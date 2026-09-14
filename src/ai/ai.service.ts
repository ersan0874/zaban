import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiJob, AiJobStatus } from './entities/ai-job.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { QuestionType } from '../questions/types/question.types';

type DraftExercise = {
  type: string;
  prompt: string;
  order: number;
  content: Record<string, unknown>;
  answer: Record<string, unknown>;
};

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  constructor(
    @InjectRepository(AiJob)
    private readonly jobRepository: Repository<AiJob>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
  ) {}

  listJobs() {
    return this.jobRepository.find({ order: { createdAt: 'DESC' } });
  }

  async createJobFromText(sourceText: string, createdBy?: string) {
    const job = await this.jobRepository.save(
      this.jobRepository.create({
        sourceText,
        createdBy: createdBy ?? null,
        status: AiJobStatus.UPLOADED,
        sourceType: 'text',
      }),
    );

    setImmediate(() => {
      this.runPipeline(job.id).catch((err) => {
        this.logger.error(`AI pipeline failed for ${job.id}`, err);
      });
    });

    return job;
  }

  async runPipeline(jobId: string) {
    const job = await this.jobRepository.findOne({ where: { id: jobId } });
    if (!job) return;

    try {
      job.status = AiJobStatus.EXTRACTING;
      await this.jobRepository.save(job);
      const paragraphs = this.extractParagraphs(job.sourceText);

      job.status = AiJobStatus.STRUCTURING;
      await this.jobRepository.save(job);
      const outline = this.structureOutline(paragraphs);

      job.status = AiJobStatus.GENERATING;
      await this.jobRepository.save(job);
      const drafts = this.generateDraftExercises(outline, paragraphs);

      job.resultJson = { outline, drafts };
      job.status = AiJobStatus.AWAITING_REVIEW;
      await this.jobRepository.save(job);
    } catch (err) {
      job.status = AiJobStatus.FAILED;
      job.resultJson = {
        error: err instanceof Error ? err.message : 'Unknown error',
      };
      await this.jobRepository.save(job);
    }
  }

  async approveJob(jobId: string) {
    const job = await this.jobRepository.findOne({ where: { id: jobId } });
    if (!job) throw new NotFoundException('AI job not found');
    if (job.status !== AiJobStatus.AWAITING_REVIEW) {
      throw new NotFoundException('Job is not awaiting review');
    }

    const drafts =
      (job.resultJson?.drafts as DraftExercise[] | undefined) ?? [];
    const lessonId = job.resultJson?.targetLessonId as string | undefined;

    if (lessonId && drafts.length > 0) {
      const lesson = await this.lessonRepository.findOne({
        where: { id: lessonId },
      });
      if (lesson) {
        for (const draft of drafts) {
          await this.exerciseRepository.save(
            this.exerciseRepository.create({
              lessonId,
              type: draft.type,
              prompt: draft.prompt,
              order: draft.order,
              content: draft.content,
              answer: draft.answer,
              wordId: null,
            }),
          );
        }
      }
    }

    job.status = AiJobStatus.PUBLISHED;
    await this.jobRepository.save(job);
    return job;
  }

  private extractParagraphs(text: string): string[] {
    return text
      .split(/\n\s*\n/)
      .map((p) => p.trim())
      .filter((p) => p.length > 0);
  }

  private structureOutline(paragraphs: string[]) {
    return paragraphs.map((p, i) => ({
      section: i + 1,
      title: `Section ${i + 1}`,
      summary: p.slice(0, 120) + (p.length > 120 ? '…' : ''),
      difficulty: i === 0 ? 'easy' : i < 3 ? 'medium' : 'hard',
    }));
  }

  private generateDraftExercises(
    outline: Array<{ section: number; title: string; summary: string }>,
    paragraphs: string[],
  ): DraftExercise[] {
    const drafts: DraftExercise[] = [];
    let order = 1;

    for (let i = 0; i < outline.length; i++) {
      const section = outline[i];
      const paragraph = paragraphs[i] ?? section.summary;
      const words = paragraph
        .split(/\s+/)
        .filter((w) => w.length > 4)
        .slice(0, 4);
      const target = words[0] ?? 'example';
      const distractors = words.slice(1, 4);
      while (distractors.length < 3) {
        distractors.push(`option_${distractors.length + 1}`);
      }

      drafts.push({
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: `What best matches the theme of "${section.title}"?`,
        order: order++,
        content: {
          stem: section.summary,
          options: [target, ...distractors],
        },
        answer: { correctOption: target },
      });
    }

    return drafts;
  }
}
