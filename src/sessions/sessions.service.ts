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
  SessionStepRecord,
} from './entities/lesson-session.entity';
import { SessionAttempt } from './entities/session-attempt.entity';
import { SubmitSessionDto } from './dto/submit-session.dto';
import { StepSessionDto } from './dto/step-session.dto';
import { gradeExercise } from './validators/exercise-grader';
import { describeSolution } from './validators/exercise-solution';
import { OpenAnswerGraderService } from '../ai/llm/open-answer-grader.service';
import { ConfigService } from '@nestjs/config';
import { QuestionType } from '../questions/types/question.types';
import { asRecord } from '../questions/registry/helpers';
import { GradeResult } from '../questions/registry';

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
    private readonly openAnswerGrader: OpenAnswerGraderService,
    private readonly config: ConfigService,
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
    const energy = await this.energyService.assertCanStart(userId);

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
        notes: lesson.notes ?? [],
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
        notes: lesson.notes ?? [],
        estimatedMinutes: lesson.estimatedMinutes,
        unitId: lesson.unitId,
        exercises: allExercises.map((ex) =>
          this.toClientExercise(ex, reviewSet.has(ex.id)),
        ),
      },
    };
  }

  /**
   * One page passed: grade the question (or accept a lesson-note page),
   * burn energy and advance the combo. Answering the same page twice
   * returns the first result without burning or grading again.
   */
  async step(userId: string, sessionId: string, dto: StepSessionDto) {
    const session = await this.requireOwnedSession(userId, sessionId);
    await this.expireIfNeeded(session);
    if (session.status !== LessonSessionStatus.ACTIVE) {
      throw new BadRequestException('Session is not active');
    }

    let key: string;
    let exercise: Exercise | null = null;
    if (dto.exerciseId) {
      exercise = await this.requireSessionExercise(session, dto.exerciseId);
      if (dto.response === undefined || dto.response === null) {
        throw new BadRequestException('response is required for a question');
      }
      key = exercise.id;
    } else if (dto.page) {
      const index = Number(dto.page.split(':')[1]);
      const lesson = await this.lessonRepository.findOne({
        where: { id: session.lessonId },
      });
      if (index >= (lesson?.notes ?? []).length) {
        throw new BadRequestException('Unknown lesson page');
      }
      key = dto.page;
    } else {
      throw new BadRequestException('exerciseId or page is required');
    }

    const solution = exercise
      ? describeSolution(exercise.type, exercise.answer)
      : null;
    const previous = session.steps?.[key];
    if (previous) {
      return {
        key,
        ...previous,
        solution,
        duplicate: true,
        energy: await this.energyService.getSnapshot(userId),
        combo: null,
      };
    }

    let record: SessionStepRecord = {
      isCorrect: true,
      score: 1,
      feedback: null,
      gradingStatus: 'graded',
    };
    if (exercise) {
      const grade = await this.grade(userId, exercise, dto.response);
      record = {
        isCorrect: grade.correct,
        score: grade.score,
        feedback: grade.feedback ?? null,
        gradingStatus: grade.status,
      };
    }
    // An answer the AI could not grade yet is not counted as a mistake.
    const passed = record.isCorrect || record.gradingStatus !== 'graded';

    // Claim the page atomically so parallel retries cannot burn twice.
    const claimed = await this.sessionRepository
      .createQueryBuilder()
      .update(LessonSession)
      .set({
        steps: () => `steps || jsonb_build_object(:key::text, :record::jsonb)`,
      })
      .where('id = :id', { id: session.id })
      .andWhere('NOT jsonb_exists(steps, :key)')
      .setParameters({ key, record: JSON.stringify(record) })
      .execute();
    if (!claimed.affected) {
      throw new ConflictException('Page already passed');
    }

    let outcome: Awaited<ReturnType<EnergyService['applyStep']>>;
    try {
      outcome = await this.energyService.applyStep(userId, session.id, passed);
    } catch (err) {
      await this.sessionRepository
        .createQueryBuilder()
        .update(LessonSession)
        .set({ steps: () => `steps - :key::text` })
        .where('id = :id', { id: session.id })
        .setParameters({ key })
        .execute();
      throw err;
    }

    if (exercise) {
      await this.attemptRepository.save(
        this.attemptRepository.create({
          sessionId: session.id,
          exerciseId: exercise.id,
          response: dto.response,
          isCorrect: record.isCorrect,
          score: record.score,
          feedback: record.feedback,
          gradingStatus: record.gradingStatus,
        }),
      );
    }

    if (outcome.combo.reward) {
      await this.sessionRepository
        .createQueryBuilder()
        .update(LessonSession)
        .set({ comboRewards: () => `"comboRewards" || :reward::jsonb` })
        .where('id = :id', { id: session.id })
        .setParameters({ reward: JSON.stringify([outcome.combo.reward]) })
        .execute();
    }

    return {
      key,
      ...record,
      solution,
      duplicate: false,
      energy: outcome.energy,
      combo: outcome.combo,
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

    const reviewSet = new Set(session.reviewExerciseIds ?? []);
    // Answers were graded and paid for page by page via /steps; the
    // attempts saved there (possibly regraded since) are the source of truth.
    const attempts = await this.attemptRepository.find({
      where: { sessionId: session.id },
      relations: { exercise: true },
      order: { createdAt: 'ASC' },
    });
    const byExercise = new Map(attempts.map((a) => [a.exerciseId, a]));

    const results: Array<{
      exerciseId: string;
      type: string;
      isCorrect: boolean;
      isReview: boolean;
      score: number;
      feedback: string | null;
      gradingStatus: string;
    }> = [];

    for (const item of dto.answers) {
      const attempt = byExercise.get(item.exerciseId);
      if (!attempt) {
        throw new BadRequestException(
          `Exercise ${item.exerciseId} was not answered in this session`,
        );
      }
      results.push({
        exerciseId: attempt.exerciseId,
        type: attempt.exercise.type,
        isCorrect: attempt.isCorrect,
        isReview: reviewSet.has(attempt.exerciseId),
        score: attempt.score ?? (attempt.isCorrect ? 1 : 0),
        feedback: attempt.feedback ?? null,
        gradingStatus: attempt.gradingStatus,
      });
    }

    await this.progressService.recordSessionResults(
      userId,
      results.map(({ exerciseId, type, isCorrect }) => ({
        exerciseId,
        type,
        isCorrect,
      })),
    );

    const energy = await this.energyService.getSnapshot(userId);
    const comboRewards = session.comboRewards ?? [];

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

  /** Caps AI-graded essay answers per user per day to protect the free quota. */
  private async canUseAiGrading(userId: string): Promise<boolean> {
    const limit = Number(this.config.get('ESSAY_AI_DAILY_LIMIT', 50));
    const since = new Date();
    since.setHours(0, 0, 0, 0);
    const used = await this.attemptRepository
      .createQueryBuilder('attempt')
      .innerJoin('attempt.session', 'session')
      .innerJoin('attempt.exercise', 'exercise')
      .where('session.userId = :userId', { userId })
      .andWhere('exercise.type = :type', { type: QuestionType.ESSAY })
      .andWhere("attempt.gradingStatus = 'graded'")
      .andWhere('attempt.createdAt >= :since', { since })
      .getCount();
    return used < limit;
  }

  /** The single place answers are graded (each answer once, at its step). */
  private async grade(
    userId: string,
    exercise: Exercise,
    response: unknown,
  ): Promise<GradeResult> {
    const aiGradingAllowed =
      exercise.type !== (QuestionType.ESSAY as string) ||
      (await this.canUseAiGrading(userId));
    const grade = await gradeExercise(
      exercise.type,
      exercise.answer,
      response,
      {
        prompt: exercise.prompt,
        content: asRecord(exercise.content),
        openAnswerGrader: aiGradingAllowed ? this.openAnswerGrader : undefined,
      },
    );
    if (grade.status === 'pending' && !aiGradingAllowed) {
      // Over the daily AI-grading cap: show the model answer instead.
      grade.status = 'ungraded';
      const reference = asRecord(exercise.answer).referenceAnswer;
      grade.feedback = typeof reference === 'string' ? reference : null;
    }
    return grade;
  }

  private async requireSessionExercise(
    session: LessonSession,
    exerciseId: string,
  ): Promise<Exercise> {
    const exercise = await this.exerciseRepository.findOne({
      where: { id: exerciseId },
    });
    const inSession =
      !!exercise &&
      (exercise.lessonId === session.lessonId ||
        (session.reviewExerciseIds ?? []).includes(exercise.id));
    if (!exercise || !inSession) {
      throw new BadRequestException(
        `Exercise ${exerciseId} is not part of this session`,
      );
    }
    return exercise;
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
