import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, LessThanOrEqual, Repository } from 'typeorm';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Word } from '../words/entities/word.entity';
import {
  ItemProgress,
  ProgressItemKind,
} from './entities/item-progress.entity';
import { applySrsResult, initialSrsState } from './srs';

const MAX_REVIEW_INJECT = 3;

export type GradedExerciseResult = {
  exerciseId: string;
  type: string;
  isCorrect: boolean;
};

@Injectable()
export class ProgressService {
  constructor(
    @InjectRepository(ItemProgress)
    private readonly progressRepository: Repository<ItemProgress>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
  ) {}

  async recordSessionResults(
    userId: string,
    results: GradedExerciseResult[],
  ): Promise<void> {
    if (results.length === 0) return;

    const exerciseIds = results.map((r) => r.exerciseId);
    const exercises = await this.exerciseRepository.find({
      where: { id: In(exerciseIds) },
    });
    const byId = new Map(exercises.map((ex) => [ex.id, ex]));

    for (const result of results) {
      const exercise = byId.get(result.exerciseId);
      if (!exercise) continue;
      const targets = await this.resolveTargets(exercise);
      for (const target of targets) {
        await this.applyResult(userId, target, result.isCorrect);
      }
    }
  }

  /**
   * Pick due review exercises (wrong/weak items) to inject into a lesson session.
   * Excludes exercises already in the current lesson.
   */
  async pickReviewExercisesForLesson(
    userId: string,
    lessonExerciseIds: string[],
    limit = MAX_REVIEW_INJECT,
  ): Promise<Exercise[]> {
    const due = await this.progressRepository.find({
      where: {
        userId,
        nextReviewAt: LessThanOrEqual(new Date()),
      },
      order: { nextReviewAt: 'ASC', skillScore: 'ASC' },
      take: 20,
    });
    if (due.length === 0) return [];

    const lessonSet = new Set(lessonExerciseIds);
    const picked: Exercise[] = [];
    const usedExerciseIds = new Set<string>();

    for (const row of due) {
      if (picked.length >= limit) break;

      if (row.itemKind === ProgressItemKind.EXERCISE) {
        if (lessonSet.has(row.itemId) || usedExerciseIds.has(row.itemId)) {
          continue;
        }
        const ex = await this.exerciseRepository.findOne({
          where: { id: row.itemId },
        });
        if (ex) {
          picked.push(ex);
          usedExerciseIds.add(ex.id);
        }
        continue;
      }

      // word → find an exercise linked to that word
      const candidates = await this.exerciseRepository.find({
        where: { wordId: row.itemId },
        take: 5,
      });
      const candidate =
        candidates.find(
          (ex) => !lessonSet.has(ex.id) && !usedExerciseIds.has(ex.id),
        ) ?? null;
      if (candidate) {
        picked.push(candidate);
        usedExerciseIds.add(candidate.id);
      }
    }

    return picked;
  }

  async getProgressSummary(userId: string) {
    const rows = await this.progressRepository.find({
      where: { userId },
      order: { updatedAt: 'DESC' },
    });
    const now = Date.now();
    const dueCount = rows.filter((r) => r.nextReviewAt.getTime() <= now).length;
    const avgSkill =
      rows.length === 0
        ? 0
        : Math.round(
            rows.reduce((sum, r) => sum + r.skillScore, 0) / rows.length,
          );

    return {
      totalTracked: rows.length,
      dueCount,
      averageSkillScore: avgSkill,
      items: rows.map((r) => this.toProgressDto(r)),
    };
  }

  async getDueReviews(userId: string, limit = 50) {
    const rows = await this.progressRepository.find({
      where: {
        userId,
        nextReviewAt: LessThanOrEqual(new Date()),
      },
      order: { nextReviewAt: 'ASC', skillScore: 'ASC' },
      take: limit,
    });

    return {
      count: rows.length,
      items: rows.map((r) => this.toProgressDto(r)),
    };
  }

  async getItemProgress(userId: string, itemKind: string, itemId: string) {
    const kind =
      itemKind === ProgressItemKind.WORD
        ? ProgressItemKind.WORD
        : ProgressItemKind.EXERCISE;
    const row = await this.progressRepository.findOne({
      where: { userId, itemKind: kind, itemId },
    });
    if (!row) {
      throw new NotFoundException('Progress item not found');
    }
    return this.toProgressDto(row);
  }

  private async applyResult(
    userId: string,
    target: { itemKind: ProgressItemKind; itemId: string; label: string | null },
    isCorrect: boolean,
  ): Promise<void> {
    let row = await this.progressRepository.findOne({
      where: {
        userId,
        itemKind: target.itemKind,
        itemId: target.itemId,
      },
    });

    if (!row) {
      const init = initialSrsState();
      row = this.progressRepository.create({
        userId,
        itemKind: target.itemKind,
        itemId: target.itemId,
        label: target.label,
        ...init,
      });
    }

    const next = applySrsResult(row, isCorrect);
    Object.assign(row, next);
    if (target.label) {
      row.label = target.label;
    }
    await this.progressRepository.save(row);
  }

  private async resolveTargets(
    exercise: Exercise,
  ): Promise<
    Array<{ itemKind: ProgressItemKind; itemId: string; label: string | null }>
  > {
    if (exercise.wordId) {
      const word = await this.wordRepository.findOne({
        where: { id: exercise.wordId },
      });
      return [
        {
          itemKind: ProgressItemKind.WORD,
          itemId: exercise.wordId,
          label: word?.word ?? null,
        },
      ];
    }

    // Always track the exercise itself so wrong answers enter the queue.
    return [
      {
        itemKind: ProgressItemKind.EXERCISE,
        itemId: exercise.id,
        label: exercise.prompt.slice(0, 80),
      },
    ];
  }

  private toProgressDto(row: ItemProgress) {
    return {
      id: row.id,
      itemKind: row.itemKind,
      itemId: row.itemId,
      label: row.label,
      skillScore: row.skillScore,
      repetitions: row.repetitions,
      intervalMinutes: row.intervalMinutes,
      nextReviewAt: row.nextReviewAt,
      lastReviewedAt: row.lastReviewedAt,
      lastWasCorrect: row.lastWasCorrect,
      totalCorrect: row.totalCorrect,
      totalIncorrect: row.totalIncorrect,
      isDue: row.nextReviewAt.getTime() <= Date.now(),
    };
  }
}
