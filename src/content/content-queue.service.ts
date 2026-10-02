import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DelayedError, Job, Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';
import { LlmQuotaExhaustedError } from '../ai/llm/llm.types';
import { ContentPipelineService } from './pipeline/content-pipeline.service';

export const CONTENT_QUEUE = 'content-pipeline';

type ContentTask =
  | { name: 'extract'; data: { jobId: string } }
  | { name: 'propose'; data: { jobId: string } }
  | { name: 'lesson'; data: { jobId: string; lessonId: string } };

const ATTEMPTS = 3;

/**
 * BullMQ queue for the AI content pipeline. Every process can enqueue; the
 * worker runs where AI_WORKER_ENABLED=true (API in dev, `worker` in Docker).
 * Concurrency is 1 to respect the free Gemini quota.
 */
@Injectable()
export class ContentQueueService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ContentQueueService.name);
  private queue: Queue | null = null;
  private worker: Worker | null = null;
  private readonly connections: IORedis[] = [];

  constructor(
    private readonly config: ConfigService,
    private readonly pipeline: ContentPipelineService,
  ) {}

  private connect() {
    const connection = new IORedis(
      this.config.get<string>('REDIS_URL', 'redis://localhost:6379'),
      { maxRetriesPerRequest: null },
    );
    this.connections.push(connection);
    return connection;
  }

  onModuleInit() {
    if (process.env.NODE_ENV === 'test') return;
    this.queue = new Queue(CONTENT_QUEUE, { connection: this.connect() });
    if (this.config.get<string>('AI_WORKER_ENABLED', 'true') === 'true') {
      this.worker = new Worker(
        CONTENT_QUEUE,
        (job, token) => this.process(job, token),
        {
          connection: this.connect(),
          concurrency: 1,
          lockDuration: 2 * 60 * 1000,
        },
      );
      this.worker.on('failed', (job, err) => {
        if (job) void this.onFailed(job, err);
      });
      this.logger.log('Content pipeline worker started');
    }
  }

  async onModuleDestroy() {
    await this.worker?.close();
    await this.queue?.close();
    await Promise.all(this.connections.map((c) => c.quit().catch(() => null)));
  }

  async enqueue(task: ContentTask) {
    if (!this.queue) throw new Error('Content queue is not available');
    // One queue entry per step/lesson: re-enqueueing replaces a waiting or
    // finished entry instead of running the same AI work twice.
    const jobId =
      task.name === 'lesson'
        ? `lesson-${task.data.lessonId}`
        : `${task.name}-${task.data.jobId}`;
    const existing = await this.queue.getJob(jobId);
    if (existing) {
      if (await existing.isActive()) return;
      await existing.remove();
    }
    await this.queue.add(task.name, task.data, {
      jobId,
      attempts: ATTEMPTS,
      backoff: { type: 'exponential', delay: 30_000 },
      removeOnComplete: 1000,
      removeOnFail: 1000,
    });
  }

  private async process(job: Job, token?: string) {
    const data = job.data as { jobId: string; lessonId?: string };
    try {
      switch (job.name) {
        case 'extract':
          await this.pipeline.extract(data.jobId);
          await this.enqueue({ name: 'propose', data: { jobId: data.jobId } });
          return;
        case 'propose':
          await this.pipeline.propose(data.jobId);
          return;
        case 'lesson':
          await this.pipeline.generateLesson(data.lessonId!);
          return;
        default:
          throw new Error(`Unknown content task ${job.name}`);
      }
    } catch (err) {
      if (err instanceof LlmQuotaExhaustedError) {
        // Quota used up: park the task and resume automatically later.
        const until = new Date(Date.now() + err.retryAfterMs);
        this.logger.warn(
          `Quota exhausted; ${job.name} paused until ${until.toISOString()}: ${err.message.slice(0, 200)}`,
        );
        await this.pipeline.setPaused(data.jobId, until, data.lessonId);
        await job.moveToDelayed(until.getTime(), token);
        throw new DelayedError();
      }
      throw err;
    }
  }

  private async onFailed(job: Job, err: Error) {
    if (job.attemptsMade < (job.opts.attempts ?? 1)) return;
    const data = job.data as { jobId: string; lessonId?: string };
    this.logger.error(`Content task ${job.name} failed: ${err.message}`);
    if (job.name === 'lesson' && data.lessonId) {
      await this.pipeline.markLessonFailed(data.lessonId, err.message);
    } else {
      await this.pipeline.markJobFailed(data.jobId, err.message);
    }
  }
}
