import { comboRewardRange, comboTier, rollComboReward } from './combo';

const rules = { length: 5, minBase: 1, maxBase: 3, minStep: 1, maxStep: 2 };

describe('combo rules', () => {
  it('reaches a tier every 5 passed pages', () => {
    expect(comboTier(4, 5)).toBe(0);
    expect(comboTier(5, 5)).toBe(1);
    expect(comboTier(7, 5)).toBe(0);
    expect(comboTier(10, 5)).toBe(2);
    expect(comboTier(15, 5)).toBe(3);
    expect(comboTier(0, 5)).toBe(0);
  });

  it('grows the reward range with each tier', () => {
    expect(comboRewardRange(1, rules)).toEqual({ min: 1, max: 3 });
    expect(comboRewardRange(2, rules)).toEqual({ min: 2, max: 5 });
    expect(comboRewardRange(3, rules)).toEqual({ min: 3, max: 7 });
  });

  it('rolls inside the range', () => {
    expect(rollComboReward(1, rules, () => 0)).toBe(1);
    expect(rollComboReward(1, rules, () => 0.999)).toBe(3);
    expect(rollComboReward(2, rules, () => 0)).toBe(2);
    expect(rollComboReward(2, rules, () => 0.999)).toBe(5);
  });
});
