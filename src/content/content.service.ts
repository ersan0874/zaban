import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { mkdir, writeFile } from 'fs/promises';
import { basename, join, resolve } from 'path';
import { DataSource, Repository } from 'typeorm';
import { LLM_PROVIDER, type LlmProvider } from '../ai/llm/llm.types';
import {
  getQuestionDefinition,
  listGeneratableQuestionTypes,
} from '../questions/registry';
import { Course } from '../courses/entities/course.entity';
import { Section } from '../sections/entities/section.entity';
import { Unit } from '../units/entities/unit.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Word } from '../words/entities/word.entity';
import { ContentJob, ContentJobStatus } from './entities/content-job.entity';
import { ContentSourceFile } from './entities/content-source-file.entity';
import { ContentProposal } from './entities/content-proposal.entity';
import {
  ContentDraftLesson,
  DraftLessonStatus,
} from './entities/content-draft-lesson.entity';
import {
  ContentDraftExercise,
  DraftQuality,
} from './entities/content-draft-exercise.entity';
import { CreateContentJobDto } from './dto/create-content-job.dto';
import {
  PublishContentJobDto,
  UpdateDraftExerciseDto,
  UpdateDraftLessonDto,
} from './dto/update-draft.dto';
import { ContentQueueService } from './content-queue.service';
import { detectSourceKind } from './pipeline/source-kind';
import { normalizeOutline } from './pipeline/outline';
import type { CourseOutline } from './entities/content-proposal.entity';

const DEFAULT_QUESTION_COUNTS: Record<string, number> = {
  multiple_choice: 3,
  cloze_typing: 1,
  true_false: 1,
};
const MAX_PER_TYPE = 10;

/** Admin-side operations of the AI content pipeline. */
@Injectable()
export class ContentService {
  constructor(
    @InjectRepository(ContentJob)
    private readonly jobRepository: Repository<ContentJob>,
    @InjectRepository(ContentSourceFile)
    private readonly fileRepository: Repository<ContentSourceFile>,
    @InjectRepository(ContentProposal)
    private readonly proposalRepository: Repository<ContentProposal>,
    @InjectRepository(ContentDraftLesson)
    private readonly lessonRepository: Repository<ContentDraftLesson>,
    @InjectRepository(ContentDraftExercise)
    private readonly exerciseRepository: Repository<ContentDraftExercise>,
    private readonly queue: ContentQueueService,
    private readonly dataSource: DataSource,
    private readonly config: ConfigService,
    @Inject(LLM_PROVIDER) private readonly llm: LlmProvider,
  ) {}

  questionTypes() {
    return listGeneratableQuestionTypes().map((d) => ({
      type: d.type,
      label: d.label,
      defaultCount: DEFAULT_QUESTION_COUNTS[d.type] ?? 0,
    }));
  }

  /** Small live call so the admin can check key + network from the panel. */
  async ping() {
    const started = Date.now();
    const { data, usage } = await this.llm.generateJson<{ reply: string }>({
      tier: 'lite',
      parts: [{ text: 'Reply with the single word "ok".' }],
      schema: {
        type: 'object',
        properties: { reply: { type: 'string' } },
        required: ['reply'],
      },
    });
    return {
      ok: true,
      reply: data.reply,
      model: usage.model,
      ms: Date.now() - started,
    };
  }

  async createJob(
    files: Express.Multer.File[],
    dto: CreateContentJobDto,
    userId: string | null,
  ) {
    if (!files?.length)
      throw new BadRequestException('Upload at least one file');
    for (const file of files) {
      if (!detectSourceKind(file.originalname, file.mimetype)) {
        throw new BadRequestException(
          `Unsupported file type: ${file.originalname}`,
        );
      }
    }
    const questionCounts = this.cleanCounts(
      dto.questionCounts ?? DEFAULT_QUESTION_COUNTS,
    );

    const job = await this.jobRepository.save(
      this.jobRepository.create({
        title: dto.title.trim(),
        status: ContentJobStatus.EXTRACTING,
        settings: {
          outputLanguage: dto.outputLanguage?.trim() || 'fa',
          questionCounts,
          instructions: dto.instructions?.trim() || undefined,
        },
        createdBy: userId,
      }),
    );

    const dir = resolve(
      this.config.get<string>('UPLOAD_DIR', 'storage/uploads'),
      job.id,
    );
    await mkdir(dir, { recursive: true });
    await this.fileRepository.save(
      await Promise.all(
        files.map(async (file, order) => {
          // Multer gives latin1 names; restore UTF-8 (Persian file names).
          const name = Buffer.from(file.originalname, 'latin1').toString(
            'utf8',
          );
          const storagePath = join(
            dir,
            `${order}-${basename(name).replace(/[^\p{L}\p{N}._-]+/gu, '_')}`,
          );
          await writeFile(storagePath, file.buffer);
          return this.fileRepository.create({
            jobId: job.id,
            order,
            originalName: name,
            mimeType: file.mimetype,
            sizeBytes: file.size,
            storagePath,
          });
        }),
      ),
    );

    await this.queue.enqueue({ name: 'extract', data: { jobId: job.id } });
    return this.getJob(job.id);
  }

  listJobs() {
    return this.jobRepository.find({
      select: {
        id: true,
        title: true,
        status: true,
        domain: true,
        error: true,
        pausedUntil: true,
        tokenUsage: true,
        publishedCourseId: true,
        createdAt: true,
        updatedAt: true,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async getJob(id: string) {
    const job = await this.jobRepository.findOne({
      where: { id },
      relations: { files: true, proposals: true },
      order: { files: { order: 'ASC' }, proposals: { order: 'ASC' } },
    });
    if (!job) throw new NotFoundException('Content job not found');
    const lessonStats = await this.lessonRepository
      .createQueryBuilder('l')
      .select('l.status', 'status')
      .addSelect('COUNT(*)::int', 'count')
      .where('l.jobId = :id', { id })
      .groupBy('l.status')
      .getRawMany<{ status: string; count: number }>();
    const needsReview = await this.exerciseRepository
      .createQueryBuilder('e')
      .innerJoin('e.lesson', 'l')
      .where('l.jobId = :id', { id })
      .andWhere('e.quality = :q', { q: DraftQuality.NEEDS_REVIEW })
      .getCount();

    const { sourceBlocks, files, ...rest } = job;
    return {
      ...rest,
      blockCount: sourceBlocks.length,
      files: files.map(({ extractedMarkdown, ...f }) => ({
        ...f,
        storagePath: undefined,
        extracted: extractedMarkdown !== null,
        extractedChars: extractedMarkdown?.length ?? 0,
      })),
      lessonStats: Object.fromEntries(
        lessonStats.map((s) => [s.status, s.count]),
      ),
      exercisesNeedingReview: needsReview,
    };
  }

  /** Source text of a block range — lets the admin see what a lesson is built from. */
  async getSource(id: string, from: number, to: number) {
    const job = await this.jobRepository.findOneBy({ id });
    if (!job) throw new NotFoundException('Content job not found');
    return job.sourceBlocks.slice(Math.max(0, from), Math.max(0, to) + 1);
  }

  async selectProposal(
    jobId: string,
    proposalId: string,
    edited?: CourseOutline,
  ) {
    const job = await this.jobRepository.findOneBy({ id: jobId });
    if (!job) throw new NotFoundException('Content job not found');
    if (job.status !== ContentJobStatus.AWAITING_STRUCTURE) {
      throw new BadRequestException(
        'Job is not waiting for a structure choice',
      );
    }
    const proposal = await this.proposalRepository.findOneBy({
      id: proposalId,
      jobId,
    });
    if (!proposal) throw new NotFoundException('Proposal not found');

    const outline = normalizeOutline(
      edited ?? proposal.outline,
      job.sourceBlocks.length,
    );
    if (outline.sections.length === 0) {
      throw new BadRequestException('Outline has no lessons');
    }
    if (edited) {
      proposal.outline = outline;
      await this.proposalRepository.save(proposal);
    }

    await this.lessonRepository.delete({ jobId });
    const lessons: ContentDraftLesson[] = [];
    outline.sections.forEach((section, s) =>
      section.units.forEach((unit, u) =>
        unit.lessons.forEach((lesson, l) =>
          lessons.push(
            this.lessonRepository.create({
              jobId,
              sectionOrder: s + 1,
              sectionTitle: section.title,
              unitOrder: u + 1,
              unitTitle: unit.title,
              order: l + 1,
              title: lesson.title,
              objective: lesson.objective,
              blockStart: lesson.blockStart,
              blockEnd: lesson.blockEnd,
              status: DraftLessonStatus.PENDING,
            }),
          ),
        ),
      ),
    );
    const saved = await this.lessonRepository.save(lessons);

    await this.jobRepository.update(jobId, {
      selectedProposalId: proposal.id,
      status: ContentJobStatus.GENERATING,
      error: null,
    });
    for (const lesson of saved) {
      await this.queue.enqueue({
        name: 'lesson',
        data: { jobId, lessonId: lesson.id },
      });
    }
    return this.getJob(jobId);
  }

  listLessons(jobId: string) {
    return this.lessonRepository.find({
      where: { jobId },
      relations: { exercises: true },
      order: {
        sectionOrder: 'ASC',
        unitOrder: 'ASC',
        order: 'ASC',
        exercises: { order: 'ASC' },
      },
    });
  }

  async updateLesson(id: string, dto: UpdateDraftLessonDto) {
    const lesson = await this.lessonRepository.findOneBy({ id });
    if (!lesson) throw new NotFoundException('Draft lesson not found');
    Object.assign(lesson, definedFields(dto));
    return this.lessonRepository.save(lesson);
  }

  async regenerateLesson(id: string) {
    const lesson = await this.lessonRepository.findOneBy({ id });
    if (!lesson) throw new NotFoundException('Draft lesson not found');
    const job = await this.jobRepository.findOneByOrFail({ id: lesson.jobId });
    if (job.status === ContentJobStatus.PUBLISHED) {
      throw new BadRequestException('Job is already published');
    }
    lesson.status = DraftLessonStatus.PENDING;
    await this.lessonRepository.save(lesson);
    await this.jobRepository.update(job.id, {
      status: ContentJobStatus.GENERATING,
    });
    await this.queue.enqueue({
      name: 'lesson',
      data: { jobId: job.id, lessonId: lesson.id },
    });
    return lesson;
  }

  /** Edits an exercise; saving re-validates and clears the review flag if valid. */
  async updateExercise(id: string, dto: UpdateDraftExerciseDto) {
    const exercise = await this.exerciseRepository.findOneBy({ id });
    if (!exercise) throw new NotFoundException('Draft exercise not found');
    Object.assign(exercise, definedFields(dto));
    const definition = getQuestionDefinition(exercise.type);
    const problems = definition?.validate(exercise) ?? ['unknown type'];
    if (problems.length > 0) {
      throw new BadRequestException(problems.join('; '));
    }
    exercise.quality = DraftQuality.OK;
    exercise.qualityNote = null;
    return this.exerciseRepository.save(exercise);
  }

  async deleteExercise(id: string) {
    const result = await this.exerciseRepository.delete({ id });
    if (!result.affected)
      throw new NotFoundException('Draft exercise not found');
    return { deleted: true };
  }

  /** Re-runs the step that failed (extraction/proposal) or failed lessons. */
  async retry(jobId: string) {
    const job = await this.jobRepository.findOneBy({ id: jobId });
    if (!job) throw new NotFoundException('Content job not found');
    const failedLessons = await this.lessonRepository.findBy({
      jobId,
      status: DraftLessonStatus.FAILED,
    });
    if (failedLessons.length > 0) {
      for (const lesson of failedLessons)
        await this.regenerateLesson(lesson.id);
      return this.getJob(jobId);
    }
    if (job.status !== ContentJobStatus.FAILED) {
      throw new BadRequestException('Nothing to retry');
    }
    const step = job.sourceBlocks.length > 0 ? 'propose' : 'extract';
    await this.jobRepository.update(jobId, {
      status:
        step === 'extract'
          ? ContentJobStatus.EXTRACTING
          : ContentJobStatus.PROPOSING,
      error: null,
    });
    await this.queue.enqueue({ name: step, data: { jobId } });
    return this.getJob(jobId);
  }

  /** Creates the live course in one transaction. */
  async publish(jobId: string, dto: PublishContentJobDto) {
    const job = await this.jobRepository.findOne({
      where: { id: jobId },
      relations: { proposals: true },
    });
    if (!job) throw new NotFoundException('Content job not found');
    if (job.status !== ContentJobStatus.AWAITING_REVIEW) {
      throw new BadRequestException('Job is not ready to publish');
    }
    const lessons = await this.listLessons(jobId);
    const notReady = lessons.filter(
      (l) => l.status !== DraftLessonStatus.READY,
    );
    if (notReady.length > 0) {
      throw new BadRequestException(
        `${notReady.length} lesson(s) are not ready (failed or still generating)`,
      );
    }
    const flagged = lessons.flatMap((l) =>
      l.exercises.filter((e) => e.quality === DraftQuality.NEEDS_REVIEW),
    );
    if (flagged.length > 0) {
      throw new BadRequestException(
        `${flagged.length} question(s) still need review — edit, approve or delete them first`,
      );
    }

    const outline = job.proposals.find(
      (p) => p.id === job.selectedProposalId,
    )?.outline;
    const domain = (dto.domain || job.domain || 'general').toLowerCase();

    const courseId = await this.dataSource.transaction(async (manager) => {
      const lastOrder = await manager
        .getRepository(Course)
        .createQueryBuilder('c')
        .select('COALESCE(MAX(c.order), 0)', 'max')
        .getRawOne<{ max: number }>();
      const course = await manager.save(
        manager.create(Course, {
          title: dto.courseTitle?.trim() || outline?.courseTitle || job.title,
          description: dto.description ?? outline?.courseDescription ?? null,
          domain,
          locale: job.settings.outputLanguage,
          order: Number(lastOrder?.max ?? 0) + 1,
          isPublished: true,
        }),
      );

      const sections = new Map<number, Section>();
      const units = new Map<string, Unit>();
      for (const draft of lessons) {
        let section = sections.get(draft.sectionOrder);
        if (!section) {
          section = await manager.save(
            manager.create(Section, {
              courseId: course.id,
              title: draft.sectionTitle,
              order: draft.sectionOrder,
            }),
          );
          sections.set(draft.sectionOrder, section);
        }
        const unitKey = `${draft.sectionOrder}:${draft.unitOrder}`;
        let unit = units.get(unitKey);
        if (!unit) {
          unit = await manager.save(
            manager.create(Unit, {
              sectionId: section.id,
              title: draft.unitTitle,
              order: draft.unitOrder,
            }),
          );
          units.set(unitKey, unit);
        }

        // Language courses: key terms become Words so SRS tracks them.
        const wordIds = new Map<string, string>();
        if (domain === 'language') {
          for (const term of draft.keyTerms) {
            const key = term.term.trim().toLowerCase();
            let word = await manager
              .getRepository(Word)
              .createQueryBuilder('w')
              .where('LOWER(w.word) = :key', { key })
              .getOne();
            if (!word) {
              word = await manager.save(
                manager.create(Word, {
                  word: term.term.trim(),
                  persianMeaning: term.meaning.slice(0, 500),
                  courseId: course.id,
                  unitId: unit.id,
                }),
              );
            }
            wordIds.set(key, word.id);
          }
        }

        const lesson = await manager.save(
          manager.create(Lesson, {
            unitId: unit.id,
            title: draft.title,
            summary: draft.objective,
            notes: draft.notes,
            order: draft.order,
          }),
        );
        await manager.save(
          draft.exercises.map((e) =>
            manager.create(Exercise, {
              lessonId: lesson.id,
              type: e.type,
              prompt: e.prompt,
              order: e.order,
              content: e.content,
              answer: e.answer,
              wordId: e.relatedTerm
                ? (wordIds.get(e.relatedTerm.toLowerCase()) ?? null)
                : null,
            }),
          ),
        );
      }

      await manager.update(ContentJob, jobId, {
        status: ContentJobStatus.PUBLISHED,
        publishedCourseId: course.id,
      });
      return course.id;
    });

    return { courseId, ...(await this.getJob(jobId)) };
  }

  private cleanCounts(raw: Record<string, number>) {
    const allowed = new Set(listGeneratableQuestionTypes().map((d) => d.type));
    const counts: Record<string, number> = {};
    for (const [type, value] of Object.entries(raw ?? {})) {
      if (!allowed.has(type)) {
        throw new BadRequestException(
          `Question type "${type}" cannot be generated`,
        );
      }
      const n = Math.trunc(Number(value));
      if (n > 0) counts[type] = Math.min(n, MAX_PER_TYPE);
    }
    if (Object.keys(counts).length === 0) {
      throw new BadRequestException('Request at least one question');
    }
    return counts;
  }
}

/**
 * Partial-update DTOs arrive with every declared property present (unset ones
 * as `undefined`), so a plain Object.assign would wipe fields the admin did
 * not send. Keep only the ones that were actually provided.
 */
function definedFields<T extends object>(dto: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(dto).filter(([, value]) => value !== undefined),
  ) as Partial<T>;
}
