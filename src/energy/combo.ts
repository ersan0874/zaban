/**
 * Combo rules (ADR-016): every `length` passed pages in a row without a
 * mistake is a combo. Each higher tier restores more energy.
 *
 * Tier 1 (5 in a row)  → minBase..maxBase           (default 1–3)
 * Tier 2 (10 in a row) → minBase+minStep..maxBase+maxStep (default 2–5)
 * Tier n               → minBase+(n-1)·minStep .. maxBase+(n-1)·maxStep
 */
export type ComboRules = {
  length: number;
  minBase: number;
  maxBase: number;
  minStep: number;
  maxStep: number;
};

/** Combo tier reached at this streak, or 0 when the streak is not a combo. */
export function comboTier(streak: number, length: number): number {
  if (length <= 0 || streak <= 0 || streak % length !== 0) return 0;
  return streak / length;
}

export function comboRewardRange(
  tier: number,
  rules: ComboRules,
): { min: number; max: number } {
  const min = rules.minBase + (tier - 1) * rules.minStep;
  const max = Math.max(min, rules.maxBase + (tier - 1) * rules.maxStep);
  return { min, max };
}

/** Uniform integer roll in the tier's range; `random` is injectable for tests. */
export function rollComboReward(
  tier: number,
  rules: ComboRules,
  random: () => number = Math.random,
): number {
  const { min, max } = comboRewardRange(tier, rules);
  return min + Math.floor(random() * (max - min + 1));
}
