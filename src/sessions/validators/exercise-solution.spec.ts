import { describeSolution } from './exercise-solution';

describe('describeSolution', () => {
  it('shows the correct option', () => {
    expect(
      describeSolution('multiple_choice', { correctOption: 'apple' }),
    ).toBe('apple');
  });

  it('joins ordered words', () => {
    expect(describeSolution('word_bank', { order: ['I', 'am', 'here'] })).toBe(
      'I am here',
    );
  });

  it('spells letter puzzles as one word', () => {
    expect(describeSolution('reorder', { order: ['c', 'a', 't'] })).toBe('cat');
  });

  it('names true/false answers in Persian', () => {
    expect(describeSolution('true_false', { value: false })).toBe('نادرست');
  });

  it('returns null for unknown shapes', () => {
    expect(describeSolution('translation', {})).toBeNull();
    expect(describeSolution('unknown', { x: 1 })).toBeNull();
  });
});
