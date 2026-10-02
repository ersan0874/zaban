import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import {
  LLM_PROVIDER,
  type LlmProvider,
  type LlmUsage,
} from '../../ai/llm/llm.types';
import {
  ExerciseData,
  QuestionDefinition,
  getQuestionDefinition,
} from '../../questions/registry';
import {
  ContentJob,
  ContentJobStatus,
  SourceBlock,
} from '../entities/content-job.entity';
import { ContentSourceFile } from '../entities/content-source-file.entity';
import {
  ContentProposal,
  CourseOutline,
} from '../entities/content-proposal.entity';
import {
  ContentDraftLesson,
  DraftLessonStatus,
  KeyTerm,
} from '../entities/content-draft-lesson.entity';
import {
  ContentDraftExercise,
  DraftQuality,
} from '../entities/content-draft-exercise.entity';
import { SourceExtractorService } from './source-extractor.service';
import { renderBlocks, splitIntoBlocks } from './source-blocks';
import { LESSON_SYSTEM, PROPOSE_SYSTEM, REVIEW_SYSTEM } from './prompts';
import { normalizeOutline, OUTLINE_SCHEMA } from './outline';

const MAX_FIX_ROUNDS = 2;
/** Above this, blocks are shortened when asking for structure proposals. */
const MAX_PROPOSAL_CHARS = 600_000;
const MAX_LESSON_SOURCE_CHARS = 40_000;

type RawItem = Record<string, unknown> & { relatedTerm?: string };

interface GeneratedQuestion {
  type: string;
  exercise: ExerciseData;
  relatedTerm: string | null;
  problems: string[];
}

/** The AI steps of the content pipeline. Each method is one queue job. */
@Injectable()
export class ContentPipelineService {
  private readonly logger = new Logger(ContentPipelineService.name);

  constructor(
    @Inject(LLM_PROVIDER) private readonly llm: LlmProvider,
    private readonly extractor: SourceExtractorService,
    private readonly config: ConfigService,
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
  ) {}

  // ── Step 1: files → Markdown → numbered source blocks ──────────────────

  async extract(jobId: string) {
    const job = await this.jobRepository.findOneByOrFail({ id: jobId });
    await this.setStatus(job, ContentJobStatus.EXTRACTING);
    const files = await this.fileRepository.find({
      where: { jobId },
      order: { order: 'ASC' },
    });
    for (const file of files) {
      if (file.extractedMarkdown !== null) continue; // resumed after a pause
      file.extractedMarkdown = await this.extractor.extract(file, (usage) =>
        this.addUsage(jobId, usage),
      );
      await this.fileRepository.save(file);
    }
    const sourceBlocks = splitIntoBlocks(
      files.map((f) => ({
        name: f.originalName,
        markdown: f.extractedMarkdown ?? '',
      })),
    );
    if (sourceBlocks.length === 0) {
      throw new Error('No text could be extracted from the uploaded files');
    }
    // update() rather than save(): tokenUsage is incremented in SQL meanwhile.
    await this.jobRepository.update(jobId, { sourceBlocks });
  }

  // ── Step 2: 2-3 alternative course structures ───────────────────────────

  async propose(jobId: string) {
    const job = await this.jobRepository.findOneByOrFail({ id: jobId });
    await this.setStatus(job, ContentJobStatus.PROPOSING);

    let blocks = job.sourceBlocks;
    const totalChars = blocks.reduce((sum, b) => sum + b.text.length, 0);
    if (totalChars > MAX_PROPOSAL_CHARS) {
      const keep = Math.max(
        200,
        Math.floor(MAX_PROPOSAL_CHARS / blocks.length),
      );
      blocks = blocks.map((b) => ({
        ...b,
        text: b.text.slice(0, keep) + ' …',
      }));
    }

    const { data, usage } = await this.llm.generateJson<{
      domain: string;
      proposals: Array<{
        title: string;
        rationale: string;
        outline: CourseOutline;
      }>;
    }>({
      system: PROPOSE_SYSTEM,
      temperature: 0.7,
      parts: [
        {
          text: [
            `Output language: ${job.settings.outputLanguage}`,
            job.settings.instructions
              ? `Admin guidance: ${job.settings.instructions}`
              : '',
            `Source title: ${job.title}`,
            `Blocks are numbered 0..${job.sourceBlocks.length - 1}.`,
            '',
            renderBlocks(blocks),
          ].join('\n'),
        },
      ],
      schema: {
        type: 'object',
        properties: {
          domain: { type: 'string' },
          proposals: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                title: { type: 'string' },
                rationale: { type: 'string' },
                outline: OUTLINE_SCHEMA,
              },
              required: ['title', 'rationale', 'outline'],
            },
          },
        },
        required: ['domain', 'proposals'],
      },
    });
    await this.addUsage(jobId, usage);

    const proposals = (data.proposals ?? [])
      .map((p) => ({
        ...p,
        outline: normalizeOutline(p.outline, job.sourceBlocks.length),
      }))
      .filter((p) => p.outline.sections.length > 0)
      .slice(0, 3);
    if (proposals.length === 0) {
      throw new Error('The AI returned no usable structure proposal');
    }

    await this.proposalRepository.delete({ jobId });
    await this.proposalRepository.save(
      proposals.map((p, i) =>
        this.proposalRepository.create({
          jobId,
          order: i,
          title: p.title,
          rationale: p.rationale,
          outline: p.outline,
        }),
      ),
    );
    job.domain = (data.domain || 'general').toLowerCase().slice(0, 100);
    await this.setStatus(job, ContentJobStatus.AWAITING_STRUCTURE);
  }

  // ── Step 3: notes + questions for one lesson ────────────────────────────

  async generateLesson(lessonId: string) {
    const lesson = await this.lessonRepository.findOneByOrFail({
      id: lessonId,
    });
    const job = await this.jobRepository.findOneByOrFail({ id: lesson.jobId });
    lesson.status = DraftLessonStatus.GENERATING;
    lesson.error = null;
    await this.lessonRepository.save(lesson);
    await this.jobRepository.update(job.id, { pausedUntil: null });

    const source = this.lessonSource(job.sourceBlocks, lesson);
    const requested = this.requestedTypes(job);
    const context = {
      outputLanguage: job.settings.outputLanguage,
      adminGuidance: job.settings.instructions ?? null,
      course: job.title,
      chapter: lesson.sectionTitle,
      unit: lesson.unitTitle,
      lesson: { title: lesson.title, objective: lesson.objective },
    };

    const { data, usage } = await this.llm.generateJson<{
      notes: string[];
      keyTerms: KeyTerm[];
      questions: Record<string, RawItem[]>;
    }>({
      system: LESSON_SYSTEM,
      parts: [
        {
          text: JSON.stringify({
            ...context,
            requestedQuestions: requested.map(({ def, count }) => ({
              type: def.type,
              count,
              rules: def.generation!.instructions,
            })),
            source,
          }),
        },
      ],
      schema: {
        type: 'object',
        properties: {
          notes: { type: 'array', items: { type: 'string' } },
          keyTerms: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                term: { type: 'string' },
                meaning: { type: 'string' },
              },
              required: ['term', 'meaning'],
            },
          },
          questions: this.questionsSchema(requested),
        },
        required: ['notes', 'keyTerms', 'questions'],
      },
    });
    await this.addUsage(job.id, usage);

    let questions = this.collectQuestions(requested, data.questions);

    // Regenerate only the questions that failed their module's validation.
    for (let round = 0; round < MAX_FIX_ROUNDS; round++) {
      const missing = this.missingCounts(requested, questions);
      if (missing.length === 0) break;
      const { data: fix, usage: fixUsage } = await this.llm.generateJson<{
        questions: Record<string, RawItem[]>;
      }>({
        system: LESSON_SYSTEM,
        parts: [
          {
            text: JSON.stringify({
              ...context,
              notes: data.notes,
              keyTerms: data.keyTerms,
              task: 'Generate ONLY the requested questions. Previous attempts had problems listed in previousProblems; avoid them.',
              previousProblems: questions
                .filter((q) => q.problems.length > 0)
                .map((q) => ({ type: q.type, problems: q.problems })),
              requestedQuestions: missing.map(({ def, count }) => ({
                type: def.type,
                count,
                rules: def.generation!.instructions,
              })),
              source,
            }),
          },
        ],
        schema: {
          type: 'object',
          properties: { questions: this.questionsSchema(missing) },
          required: ['questions'],
        },
      });
      await this.addUsage(job.id, fixUsage);
      questions = [
        ...questions.filter((q) => q.problems.length === 0),
        ...this.collectQuestions(missing, fix.questions),
        ...questions.filter((q) => q.problems.length > 0),
      ];
    }

    // Keep the requested number per type, valid ones first.
    const kept: GeneratedQuestion[] = [];
    for (const { def, count } of requested) {
      const ofType = questions
        .filter((q) => q.type === def.type)
        .sort((a, b) => a.problems.length - b.problems.length);
      kept.push(...ofType.slice(0, count));
    }

    const verdicts = await this.reviewQuestions(
      job,
      lesson,
      data.notes,
      source,
      kept,
    );

    await this.exerciseRepository.delete({ draftLessonId: lesson.id });
    await this.exerciseRepository.save(
      kept.map((q, i) => {
        const problems = [...q.problems];
        const verdict = verdicts.get(i);
        if (verdict) problems.push(verdict);
        return this.exerciseRepository.create({
          draftLessonId: lesson.id,
          type: q.type,
          prompt: q.exercise.prompt,
          content: q.exercise.content,
          answer: q.exercise.answer,
          order: i + 1,
          relatedTerm: q.relatedTerm,
          quality: problems.length
            ? DraftQuality.NEEDS_REVIEW
            : DraftQuality.OK,
          qualityNote: problems.length ? problems.join(' · ') : null,
        });
      }),
    );

    lesson.notes = (data.notes ?? []).filter((n) => n.trim());
    lesson.keyTerms = (data.keyTerms ?? []).filter((t) => t.term?.trim());
    lesson.status = DraftLessonStatus.READY;
    await this.lessonRepository.save(lesson);
    await this.completeIfDone(job.id);
  }

  async markLessonFailed(lessonId: string, error: string) {
    await this.lessonRepository.update(lessonId, {
      status: DraftLessonStatus.FAILED,
      error: error.slice(0, 2000),
    });
    const lesson = await this.lessonRepository.findOneBy({ id: lessonId });
    if (lesson) await this.completeIfDone(lesson.jobId);
  }

  async markJobFailed(jobId: string, error: string) {
    await this.jobRepository.update(jobId, {
      status: ContentJobStatus.FAILED,
      error: error.slice(0, 2000),
    });
  }

  async setPaused(jobId: string, until: Date | null, lessonId?: string) {
    await this.jobRepository.update(jobId, { pausedUntil: until });
    if (lessonId) {
      await this.lessonRepository.update(lessonId, {
        status: DraftLessonStatus.PENDING,
      });
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  private async completeIfDone(jobId: string) {
    const open = await this.lessonRepository.count({
      where: {
        jobId,
        status: In([DraftLessonStatus.PENDING, DraftLessonStatus.GENERATING]),
      },
    });
    if (open > 0) return;
    await this.jobRepository.update(
      { id: jobId, status: ContentJobStatus.GENERATING },
      { status: ContentJobStatus.AWAITING_REVIEW, pausedUntil: null },
    );
  }

  private async setStatus(job: ContentJob, status: ContentJobStatus) {
    job.status = status;
    job.error = null;
    job.pausedUntil = null;
    await this.jobRepository.update(job.id, {
      status,
      error: null,
      pausedUntil: null,
      ...(job.domain !== undefined ? { domain: job.domain } : {}),
    });
  }

  private async addUsage(jobId: string, usage: LlmUsage) {
    await this.jobRepository.query(
      `UPDATE content_jobs SET "tokenUsage" = jsonb_build_object(
         'inputTokens', COALESCE(("tokenUsage"->>'inputTokens')::bigint, 0) + $2,
         'outputTokens', COALESCE(("tokenUsage"->>'outputTokens')::bigint, 0) + $3,
         'calls', COALESCE(("tokenUsage"->>'calls')::int, 0) + 1)
       WHERE id = $1`,
      [jobId, usage.inputTokens, usage.outputTokens],
    );
  }

  private lessonSource(blocks: SourceBlock[], lesson: ContentDraftLesson) {
    const slice = blocks.slice(lesson.blockStart, lesson.blockEnd + 1);
    return renderBlocks(slice).slice(0, MAX_LESSON_SOURCE_CHARS);
  }

  private requestedTypes(job: ContentJob) {
    return Object.entries(job.settings.questionCounts)
      .map(([type, count]) => ({ def: getQuestionDefinition(type), count }))
      .filter(
        (r): r is { def: QuestionDefinition; count: number } =>
          !!r.def?.generation && r.count > 0,
      );
  }

  private questionsSchema(
    requested: Array<{ def: QuestionDefinition; count: number }>,
  ) {
    const properties: Record<string, unknown> = {};
    for (const { def } of requested) {
      const item = def.generation!.itemSchema as {
        properties: Record<string, unknown>;
      };
      properties[def.type] = {
        type: 'array',
        items: {
          ...item,
          properties: { ...item.properties, relatedTerm: { type: 'string' } },
        },
      };
    }
    return {
      type: 'object',
      properties,
      required: requested.map((r) => r.def.type),
    };
  }

  private collectQuestions(
    requested: Array<{ def: QuestionDefinition; count: number }>,
    raw: Record<string, RawItem[]> | undefined,
  ): GeneratedQuestion[] {
    const out: GeneratedQuestion[] = [];
    for (const { def } of requested) {
      for (const item of raw?.[def.type] ?? []) {
        const relatedTerm =
          typeof item.relatedTerm === 'string' && item.relatedTerm.trim()
            ? item.relatedTerm.trim()
            : null;
        try {
          const exercise = def.generation!.toExercise(item);
          out.push({
            type: def.type,
            exercise,
            relatedTerm,
            problems: def.validate(exercise),
          });
        } catch (err) {
          this.logger.debug(`Malformed ${def.type} item: ${String(err)}`);
        }
      }
    }
    return out;
  }

  private missingCounts(
    requested: Array<{ def: QuestionDefinition; count: number }>,
    questions: GeneratedQuestion[],
  ) {
    return requested
      .map(({ def, count }) => ({
        def,
        count:
          count -
          questions.filter(
            (q) => q.type === def.type && q.problems.length === 0,
          ).length,
      }))
      .filter((r) => r.count > 0);
  }

  /** Second-opinion check of answers; returns problem text per question index. */
  private async reviewQuestions(
    job: ContentJob,
    lesson: ContentDraftLesson,
    notes: string[],
    source: string,
    questions: GeneratedQuestion[],
  ): Promise<Map<number, string>> {
    const result = new Map<number, string>();
    if (questions.length === 0) return result;
    if (this.config.get<string>('CONTENT_AI_REVIEW', 'true') !== 'true') {
      return result;
    }
    const { data, usage } = await this.llm.generateJson<{
      verdicts: Array<{ index: number; ok: boolean; problem: string }>;
    }>({
      system: REVIEW_SYSTEM,
      temperature: 0,
      parts: [
        {
          text: JSON.stringify({
            outputLanguage: job.settings.outputLanguage,
            lesson: lesson.title,
            notes,
            questions: questions.map((q, index) => ({
              index,
              type: q.type,
              ...q.exercise,
            })),
            source,
          }),
        },
      ],
      schema: {
        type: 'object',
        properties: {
          verdicts: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                index: { type: 'integer' },
                ok: { type: 'boolean' },
                problem: { type: 'string' },
              },
              required: ['index', 'ok', 'problem'],
            },
          },
        },
        required: ['verdicts'],
      },
    });
    await this.addUsage(job.id, usage);
    for (const v of data.verdicts ?? []) {
      if (!v.ok && v.index >= 0 && v.index < questions.length) {
        result.set(v.index, v.problem || 'flagged by AI reviewer');
      }
    }
    return result;
  }
}
