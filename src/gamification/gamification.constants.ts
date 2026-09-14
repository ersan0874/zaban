/** UTC calendar day YYYY-MM-DD */
export function utcDateString(d = new Date()): string {
  return d.toISOString().slice(0, 10);
}

export function daysBetweenUtc(a: string, b: string): number {
  const ms =
    Date.parse(`${b}T00:00:00.000Z`) - Date.parse(`${a}T00:00:00.000Z`);
  return Math.round(ms / 86_400_000);
}

export const XP_PER_CORRECT = 10;
export const XP_SESSION_BONUS = 15;
export const HEARTS_DEFAULT = 5;
export const LOOT_EVERY_N_LESSONS = 3;
export const CLUB_STREAK_THRESHOLD = 7;
export const CLUB_XP_THRESHOLD = 500;

export type QuestTemplate = {
  questKey: string;
  title: string;
  target: number;
  rewardXp: number;
  rewardQuestPoints: number;
};

export const DAILY_QUEST_TEMPLATES: QuestTemplate[] = [
  {
    questKey: 'complete_lesson',
    title: 'یک درس تمام کن',
    target: 1,
    rewardXp: 20,
    rewardQuestPoints: 10,
  },
  {
    questKey: 'correct_answers',
    title: '۱۰ پاسخ درست بده',
    target: 10,
    rewardXp: 30,
    rewardQuestPoints: 15,
  },
  {
    questKey: 'earn_xp',
    title: '۵۰ XP بگیر',
    target: 50,
    rewardXp: 25,
    rewardQuestPoints: 10,
  },
];

export const BADGE_CATALOG: Record<
  string,
  { title: string }
> = {
  first_lesson: { title: 'اولین درس' },
  streak_3: { title: 'استریک ۳ روزه' },
  streak_7: { title: 'استریک ۷ روزه' },
  xp_100: { title: '۱۰۰ XP' },
  perfect_session: { title: 'جلسه بدون غلط' },
};
