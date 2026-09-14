import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Lesson, LessonKind } from '../lessons/entities/lesson.entity';
import { Unit } from '../units/entities/unit.entity';
import { Word } from '../words/entities/word.entity';
import {
  ItemProgress,
  ProgressItemKind,
} from '../progress/entities/item-progress.entity';
import {
  LessonSession,
  LessonSessionStatus,
} from '../sessions/entities/lesson-session.entity';
import { CourseMastery } from './entities/course-mastery.entity';
import { CheckpointAttempt } from './entities/checkpoint-attempt.entity';

const CHECKPOINT_PASS_PERCENT = 70;

@Injectable()
export class MasteryService {
  constructor(
    @InjectRepository(CourseMastery)
    private readonly masteryRepository: Repository<CourseMastery>,
    @InjectRepository(CheckpointAttempt)
    private readonly checkpointRepository: Repository<CheckpointAttempt>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
    @InjectRepository(ItemProgress)
    private readonly progressRepository: Repository<ItemProgress>,
    @InjectRepository(LessonSession)
    private readonly sessionRepository: Repository<LessonSession>,
  ) {}

  async getCourseMastery(userId: string, courseId: string) {
    const row = await this.masteryRepository.findOne({
      where: { userId, courseId },
    });
    const score = row?.score ?? (await this.recomputeMastery(userId, courseId));
    return { courseId, score };
  }

  async onLessonCompleted(
    userId: string,
    lessonId: string,
    scorePercent: number,
  ) {
    const lesson = await this.lessonRepository.findOne({
      where: { id: lessonId },
      relations: { unit: { section: true } },
    });
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    let checkpoint: {
      recorded: boolean;
      passed: boolean;
      scorePercent: number;
    } | null = null;

    if (lesson.lessonKind === LessonKind.CHECKPOINT) {
      const passed = scorePercent >= CHECKPOINT_PASS_PERCENT;
      await this.recordCheckpoint(
        userId,
        lesson.unitId,
        lessonId,
        scorePercent,
        passed,
      );
      checkpoint = { recorded: true, passed, scorePercent };
    }

    const courseId = lesson.unit?.section?.courseId;
    let masteryScore: number | null = null;
    if (courseId) {
      masteryScore = await this.recomputeMastery(userId, courseId);
    }

    return { checkpoint, masteryScore, courseId: courseId ?? null };
  }

  async recordCheckpoint(
    userId: string,
    unitId: string,
    lessonId: string,
    scorePercent: number,
    passed: boolean,
  ): Promise<CheckpointAttempt> {
    return this.checkpointRepository.save(
      this.checkpointRepository.create({
        userId,
        unitId,
        lessonId,
        scorePercent,
        passed,
      }),
    );
  }

  async recomputeMastery(userId: string, courseId: string): Promise<number> {
    const words = await this.wordRepository.find({ where: { courseId } });
    if (words.length === 0) {
      return this.saveMastery(userId, courseId, 0);
    }

    const wordIds = words.map((w) => w.id);
    const progressRows = await this.progressRepository.find({
      where: {
        userId,
        itemKind: ProgressItemKind.WORD,
        itemId: In(wordIds),
      },
    });

    const score =
      progressRows.length === 0
        ? 0
        : Math.round(
            progressRows.reduce((sum, row) => sum + row.skillScore, 0) /
              words.length,
          );

    return this.saveMastery(userId, courseId, Math.min(100, Math.max(0, score)));
  }

  /**
   * Compute path node status for ordered units.
   */
  async computePathStatuses(
    userId: string | undefined,
    units: Array<Unit & { lessons?: Lesson[] }>,
  ): Promise<Map<string, 'active' | 'locked'>> {
    const statuses = new Map<string, 'active' | 'locked'>();
    if (!userId || units.length === 0) {
      if (units.length > 0) {
        statuses.set(units[0].id, 'active');
        for (let i = 1; i < units.length; i++) {
          statuses.set(units[i].id, 'locked');
        }
      }
      return statuses;
    }

    for (let i = 0; i < units.length; i++) {
      const unit = units[i];
      if (i === 0) {
        statuses.set(unit.id, 'active');
        continue;
      }
      const prev = units[i - 1];
      const unlocked = await this.isPreviousUnitGatePassed(userId, prev);
      statuses.set(unit.id, unlocked ? 'active' : 'locked');
    }
    return statuses;
  }

  private async isPreviousUnitGatePassed(
    userId: string,
    unit: Unit & { lessons?: Lesson[] },
  ): Promise<boolean> {
    const lessons =
      unit.lessons ??
      (await this.lessonRepository.find({ where: { unitId: unit.id } }));
    const checkpointLessons = lessons.filter(
      (l) => l.lessonKind === LessonKind.CHECKPOINT,
    );

    if (checkpointLessons.length === 0) {
      const completedCount = await this.sessionRepository.count({
        where: {
          userId,
          status: LessonSessionStatus.COMPLETED,
          lessonId: In(lessons.map((l) => l.id)),
        },
      });
      return completedCount >= 1;
    }

    const passed = await this.checkpointRepository.findOne({
      where: {
        userId,
        unitId: unit.id,
        passed: true,
      },
    });
    return passed != null;
  }

  private async saveMastery(
    userId: string,
    courseId: string,
    score: number,
  ): Promise<number> {
    let row = await this.masteryRepository.findOne({
      where: { userId, courseId },
    });
    if (!row) {
      row = this.masteryRepository.create({ userId, courseId, score });
    } else {
      row.score = score;
    }
    await this.masteryRepository.save(row);
    return score;
  }
}
