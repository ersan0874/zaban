/**
 * Simple spaced-repetition schedule (ladder + ease), server-side only.
 * Intervals are intentionally short for early product feedback loops.
 */

const INTERVAL_LADDER_MINUTES = [
  10, // first success
  60, // 1 hour
  60 * 24, // 1 day
  60 * 24 * 3,
  60 * 24 * 7,
  60 * 24 * 14,
  60 * 24 * 30,
] as const;

export type SrsState = {
  skillScore: number;
  repetitions: number;
  easeFactor: number;
  intervalMinutes: number;
  nextReviewAt: Date;
  lastReviewedAt: Date;
  lastWasCorrect: boolean;
  totalCorrect: number;
  totalIncorrect: number;
};

function clampSkill(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function clampEase(value: number): number {
  return Math.max(1.3, Math.min(3.0, Number(value.toFixed(2))));
}

export function initialSrsState(now = new Date()): Omit<
  SrsState,
  'lastReviewedAt' | 'lastWasCorrect'
> & { lastReviewedAt: null; lastWasCorrect: null } {
  return {
    skillScore: 0,
    repetitions: 0,
    easeFactor: 2.5,
    intervalMinutes: 10,
    nextReviewAt: now,
    lastReviewedAt: null,
    lastWasCorrect: null,
    totalCorrect: 0,
    totalIncorrect: 0,
  };
}

export function applySrsResult(
  prev: {
    skillScore: number;
    repetitions: number;
    easeFactor: number;
    intervalMinutes: number;
    totalCorrect: number;
    totalIncorrect: number;
  },
  isCorrect: boolean,
  now = new Date(),
): SrsState {
  if (isCorrect) {
    const repetitions = prev.repetitions + 1;
    const ladderIndex = Math.min(
      repetitions - 1,
      INTERVAL_LADDER_MINUTES.length - 1,
    );
    const base = INTERVAL_LADDER_MINUTES[ladderIndex];
    const easeFactor = clampEase(prev.easeFactor + 0.05);
    const intervalMinutes = Math.max(10, Math.round(base * (easeFactor / 2.5)));
    return {
      skillScore: clampSkill(prev.skillScore + (repetitions === 1 ? 20 : 12)),
      repetitions,
      easeFactor,
      intervalMinutes,
      nextReviewAt: new Date(now.getTime() + intervalMinutes * 60_000),
      lastReviewedAt: now,
      lastWasCorrect: true,
      totalCorrect: prev.totalCorrect + 1,
      totalIncorrect: prev.totalIncorrect,
    };
  }

  const easeFactor = clampEase(prev.easeFactor - 0.2);
  const intervalMinutes = 10;
  return {
    skillScore: clampSkill(prev.skillScore - 25),
    repetitions: 0,
    easeFactor,
    intervalMinutes,
    // Wrong answers become due immediately so they enter the review queue.
    nextReviewAt: now,
    lastReviewedAt: now,
    lastWasCorrect: false,
    totalCorrect: prev.totalCorrect,
    totalIncorrect: prev.totalIncorrect + 1,
  };
}
