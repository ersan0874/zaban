import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { ProgressService } from '../progress/progress.service';
import { EnergyService } from '../energy/energy.service';
import { GamificationService } from '../gamification/gamification.service';
import { EconomyService } from '../economy/economy.service';
import { MasteryService } from '../mastery/mastery.service';
import { SocialService } from '../social/social.service';
import { ReengagementService } from '../reengagement/reengagement.service';
import { LessonKind } from '../lessons/entities/lesson.entity';
import {
  LessonSession,
  LessonSessionStatus,
} from './entities/lesson-session.entity';
import { SessionAttempt } from './entities/session-attempt.entity';
import { SubmitSessionDto } from './dto/submit-session.dto';
import { gradeExercise } from './validators/exercise-grader';

const SESSION_TTL_MS = 2 * 60 * 60 * 1000; // 2 hours

@Injectable()
export class SessionsService {
  constructor(
    @InjectRepository(LessonSession)
    private readonly sessionRepository: Repository<LessonSession>,
    @InjectRepository(SessionAttempt)
    private readonly attemptRepository: Repository<SessionAttempt>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
    private readonly progressService: ProgressService,
    private readonly energyService: EnergyService,
    private readonly gamificationService: GamificationService,
    private readonly economyService: EconomyService,
    private readonly masteryService: MasteryService,
    private readonly socialService: SocialService,
    private readonly reengagementService: ReengagementService,
  ) {}

  async startSession(userId: string, lessonId: string) {
    const lesson = await this.lessonRepository.findOne({
      where: { id: lessonId },
      relations: { exercises: true },
    });
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    await this.reengagementService.assertCanStartLesson(userId, lesson);

    const lessonExercises = (lesson.exercises ?? [])
      .slice()
      .sort((a, b) => a.order - b.order);

    const reviewExercises =
      await this.progressService.pickReviewExercisesForLesson(
        userId,
        lessonExercises.map((ex) => ex.id),
      );

    const allExercises = [...lessonExercises, ...reviewExercises];

    const session = await this.sessionRepository.save(
      this.sessionRepository.create({
        userId,
        lessonId,
        status: LessonSessionStatus.ACTIVE,
        expiresAt: new Date(Date.now() + SESSION_TTL_MS),
        correctCount: 0,
        totalCount: allExercises.length,
        reviewExerciseIds: reviewExercises.map((ex) => ex.id),
        completedAt: null,
      }),
    );

    let energy;
    try {
      energy = await this.energyService.burnForLessonStart(userId, session.id);
    } catch (err) {
      await this.sessionRepository.delete(session.id);
      throw err;
    }

    return {
      sessionId: session.id,
      status: session.status,
      expiresAt: session.expiresAt,
      reviewInjectedCount: reviewExercises.length,
      energy,
      lesson: {
        id: lesson.id,
        title: lesson.title,
        summary: lesson.summary,
        estimatedMinutes: lesson.estimatedMinutes,
        unitId: lesson.unitId,
        exercises: allExercises.map((ex) =>
          this.toClientExercise(
            ex,
            reviewExercises.some((r) => r.id === ex.id),
          ),
        ),
      },
    };
  }

  async getSession(userId: string, sessionId: string) {
    const session = await this.requireOwnedSession(userId, sessionId);
    await this.expireIfNeeded(session);

    const lesson = await this.lessonRepository.findOne({
      where: { id: session.lessonId },
      relations: { exercises: true },
    });
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    const lessonExercises = (lesson.exercises ?? [])
      .slice()
      .sort((a, b) => a.order - b.order);

    const reviewIds = session.reviewExerciseIds ?? [];
    const reviewExercises =
      reviewIds.length === 0
        ? []
        : await this.exerciseRepository.find({ where: { id: In(reviewIds) } });
    const reviewSet = new Set(reviewIds);
    const allExercises = [...lessonExercises, ...reviewExercises];

    return {
      sessionId: session.id,
      status: session.status,
      expiresAt: session.expiresAt,
      correctCount: session.correctCount,
      totalCount: session.totalCount,
      completedAt: session.completedAt,
      reviewInjectedCount: reviewIds.length,
      lesson: {
        id: lesson.id,
        title: lesson.title,
        summary: lesson.summary,
        estimatedMinutes: lesson.estimatedMinutes,
        unitId: lesson.unitId,
        exercises: allExercises.map((ex) =>
          this.toClientExercise(ex, reviewSet.has(ex.id)),
        ),
      },
    };
  }

  async submit(userId: string, sessionId: string, dto: SubmitSessionDto) {
    const session = await this.requireOwnedSession(userId, sessionId);
    await this.expireIfNeeded(session);

    if (session.status === LessonSessionStatus.EXPIRED) {
      throw new BadRequestException('Session expired');
    }
    if (session.status === LessonSessionStatus.COMPLETED) {
      throw new ConflictException('Session already completed');
    }

    const lessonExercises = await this.exerciseRepository.find({
      where: { lessonId: session.lessonId },
    });
    const reviewIds = session.reviewExerciseIds ?? [];
    const reviewExercises =
      reviewIds.length === 0
        ? []
        : await this.exerciseRepository.find({ where: { id: In(reviewIds) } });

    const byId = new Map(
      [...lessonExercises, ...reviewExercises].map((ex) => [ex.id, ex]),
    );

    const results: Array<{
      exerciseId: string;
      type: string;
      isCorrect: boolean;
      isReview: boolean;
    }> = [];

    const attempts: SessionAttempt[] = [];
    const reviewSet = new Set(reviewIds);

    for (const item of dto.answers) {
      const exercise = byId.get(item.exerciseId);
      if (!exercise) {
        throw new BadRequestException(
          `Exercise ${item.exerciseId} is not part of this session`,
        );
      }

      const isCorrect = gradeExercise(
        exercise.type,
        exercise.answer,
        item.response,
      );

      results.push({
        exerciseId: exercise.id,
        type: exercise.type,
        isCorrect,
        isReview: reviewSet.has(exercise.id),
      });

      attempts.push(
        this.attemptRepository.create({
          sessionId: session.id,
          exerciseId: exercise.id,
          response: item.response,
          isCorrect,
        }),
      );
    }

    await this.attemptRepository.save(attempts);

    await this.progressService.recordSessionResults(
      userId,
      results.map(({ exerciseId, type, isCorrect }) => ({
        exerciseId,
        type,
        isCorrect,
      })),
    );

    const { energy, comboRewards } = await this.energyService.applyComboRewards(
      userId,
      session.id,
      results,
    );

    const correctCount = results.filter((r) => r.isCorrect).length;

    const gamification = await this.gamificationService.applySessionOutcome(
      userId,
      {
        sessionId: session.id,
        correctCount,
        totalCount: results.length,
        results: results.map((r) => ({
          isCorrect: r.isCorrect,
          isReview: r.isReview,
        })),
      },
    );

    const scorePercent =
      results.length === 0
        ? 0
        : Math.round((correctCount / results.length) * 100);

    const economy = await this.economyService.onLessonCompleted(
      userId,
      gamification.xpGained,
      session.id,
    );

    const mastery = await this.masteryService.onLessonCompleted(
      userId,
      session.lessonId,
      scorePercent,
    );

    const lesson = await this.lessonRepository.findOne({
      where: { id: session.lessonId },
    });
    const feed = lesson
      ? await this.socialService.publishLessonComplete(userId, {
          lessonTitle: lesson.title,
          scorePercent,
          xpGained: gamification.xpGained,
        })
      : null;

    session.correctCount = correctCount;
    session.totalCount = results.length;
    session.status = LessonSessionStatus.COMPLETED;
    session.completedAt = new Date();
    await this.sessionRepository.save(session);

    if (lesson?.lessonKind === LessonKind.DIAGNOSTIC) {
      await this.reengagementService.completeDiagnostic(userId);
    }

    return {
      sessionId: session.id,
      status: session.status,
      correctCount,
      totalCount: results.length,
      scorePercent,
      results,
      completedAt: session.completedAt,
      energy,
      comboRewards,
      gamification,
      economy,
      mastery,
      feed,
    };
  }

  private toClientExercise(ex: Exercise, isReview = false) {
    return {
      id: ex.id,
      type: ex.type,
      prompt: ex.prompt,
      order: ex.order,
      content: ex.content,
      wordId: ex.wordId ?? null,
      isReview,
      // answer intentionally omitted
    };
  }

  private async requireOwnedSession(userId: string, sessionId: string) {
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.userId !== userId) {
      throw new ForbiddenException('Not your session');
    }
    return session;
  }

  private async expireIfNeeded(session: LessonSession) {
    if (
      session.status === LessonSessionStatus.ACTIVE &&
      session.expiresAt.getTime() < Date.now()
    ) {
      session.status = LessonSessionStatus.EXPIRED;
      await this.sessionRepository.save(session);
    }
  }
}
