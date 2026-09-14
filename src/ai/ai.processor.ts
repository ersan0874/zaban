/**
 * BullMQ worker hook (production).
 *
 * When Redis is available, register a processor on queue `ai-jobs`:
 *
 * ```ts
 * import { Worker } from 'bullmq';
 * import { AiService } from './ai.service';
 *
 * new Worker('ai-jobs', async (job) => {
 *   await aiService.runPipeline(job.data.jobId);
 * });
 * ```
 *
 * MVP uses `setImmediate` in AiService.createJobFromText for in-process async.
 * Set REDIS_URL in docker-compose for future BullMQ wiring.
 */
export const AI_JOBS_QUEUE = 'ai-jobs';
