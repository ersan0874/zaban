import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SessionAttempt } from './entities/session-attempt.entity';
import { gradeExercise } from './validators/exercise-grader';
import { OpenAnswerGraderService } from '../ai/llm/open-answer-grader.service';
import { asRecord } from '../questions/registry/helpers';

const INTERVAL_MS = 15 * 60 * 1000;
const BATCH = 20;

/**
 * Retries AI grading for answers that could not be graded at submit time
 * (e.g. Gemini unavailable). Runs only where the AI worker runs. The new
 * score is recorded on the attempt; XP already awarded is not changed.
 */
@Injectable()
export class PendingGradesService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PendingGradesService.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(
    @InjectRepository(SessionAttempt)
    private readonly attemptRepository: Repository<SessionAttempt>,
    private readonly openAnswerGrader: OpenAnswerGraderService,
    private readonly config: ConfigService,
  ) {}

  onModuleInit() {
    if (this.config.get<string>('AI_WORKER_ENABLED', 'true') !== 'true') return;
    if (process.env.NODE_ENV === 'test') return;
    this.timer = setInterval(() => {
      this.regradePending().catch((err) =>
        this.logger.error('Pending regrade failed', err),
      );
    }, INTERVAL_MS);
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  async regradePending(): Promise<number> {
    const pending = await this.attemptRepository.find({
      where: { gradingStatus: 'pending' },
      relations: { exercise: true },
      order: { createdAt: 'ASC' },
      take: BATCH,
    });
    let graded = 0;
    for (const attempt of pending) {
      const grade = await gradeExercise(
        attempt.exercise.type,
        attempt.exercise.answer,
        attempt.response,
        {
          prompt: attempt.exercise.prompt,
          content: asRecord(attempt.exercise.content),
          openAnswerGrader: this.openAnswerGrader,
        },
      );
      if (grade.status !== 'graded') break; // provider still down — try later
      attempt.isCorrect = grade.correct;
      attempt.score = grade.score;
      attempt.feedback = grade.feedback ?? null;
      attempt.gradingStatus = 'graded';
      await this.attemptRepository.save(attempt);
      graded++;
    }
    return graded;
  }
}
