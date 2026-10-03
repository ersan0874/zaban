import { ConfigService } from '@nestjs/config';
import { PathRules } from './path-items';

export const EXAM_PASS_PERCENT = 70;

function positiveInt(raw: unknown, fallback: number): number {
  const value = Number(raw);
  return Number.isInteger(value) && value >= 0 ? value : fallback;
}

/** PATH_EXAM_EVERY / PATH_CHEST_EVERY in .env; 0 turns one off. */
export function pathRules(config: ConfigService): PathRules {
  return {
    examEvery: positiveInt(config.get('PATH_EXAM_EVERY'), 5),
    chestEvery: positiveInt(config.get('PATH_CHEST_EVERY'), 3),
  };
}

export function examQuestionsPerLesson(config: ConfigService): number {
  return Math.max(
    1,
    positiveInt(config.get('PATH_EXAM_QUESTIONS_PER_LESSON'), 2),
  );
}
