import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { SessionAttempt } from './entities/session-attempt.entity';
import { asRecord } from '../questions/registry/helpers';

export interface LateGradeNotice {
  attemptId: string;
  exerciseId: string;
  lessonTitle: string;
  question: string;
  isCorrect: boolean;
  score: number | null;
  feedback: string | null;
  gradedAt: string | null;
}

const LIMIT = 20;

/**
 * Answers graded after the learner left the lesson (AI was unavailable at
 * submit time). The app shows them once and then marks them seen.
 */
@Injectable()
export class LateGradesService {
  constructor(
    @InjectRepository(SessionAttempt)
    private readonly attemptRepository: Repository<SessionAttempt>,
  ) {}

  async listUnseen(userId: string): Promise<LateGradeNotice[]> {
    const attempts = await this.attemptRepository.find({
      where: { lateGradeUnseen: true, session: { userId } },
      relations: { session: true, exercise: { lesson: true } },
      order: { lateGradedAt: 'ASC' },
      take: LIMIT,
    });
    return attempts.map((a) => {
      const content = asRecord(a.exercise?.content);
      const question = content.question ?? content.statement;
      return {
        attemptId: a.id,
        exerciseId: a.exerciseId,
        lessonTitle: a.exercise?.lesson?.title ?? '',
        question:
          typeof question === 'string' ? question : (a.exercise?.prompt ?? ''),
        isCorrect: a.isCorrect,
        score: a.score,
        feedback: a.feedback,
        gradedAt: a.lateGradedAt?.toISOString() ?? null,
      };
    });
  }

  /** Marks the given notices (or all of the user's) as seen. */
  async markSeen(userId: string, attemptIds?: string[]): Promise<number> {
    const owned = await this.attemptRepository.find({
      select: { id: true },
      where: {
        lateGradeUnseen: true,
        session: { userId },
        ...(attemptIds?.length ? { id: In(attemptIds) } : {}),
      },
    });
    if (owned.length === 0) return 0;
    await this.attemptRepository.update(
      { id: In(owned.map((a) => a.id)) },
      { lateGradeUnseen: false },
    );
    return owned.length;
  }
}
