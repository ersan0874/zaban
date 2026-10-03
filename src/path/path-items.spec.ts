import {
  buildPathItems,
  pickExamExercises,
  PathLessonInput,
  rollChestRewards,
} from './path-items';

const lessons: PathLessonInput[] = Array.from({ length: 7 }, (_, i) => ({
  id: `l${i + 1}`,
  title: `درس ${i + 1}`,
  unitId: i < 3 ? 'u1' : 'u2',
  unitTitle: i < 3 ? 'یونیت ۱' : 'یونیت ۲',
  sectionTitle: null,
}));
const rules = { examEvery: 5, chestEvery: 3 };
const none = {
  completedLessonIds: new Set<string>(),
  passedExamPositions: new Set<number>(),
  openedChestPositions: new Set<number>(),
};

describe('buildPathItems', () => {
  it('puts a chest after every 3 lessons and an exam after every 5', () => {
    const items = buildPathItems(lessons, none, rules);
    expect(items.map((i) => i.id)).toEqual([
      'lesson:l1',
      'lesson:l2',
      'lesson:l3',
      'chest:3',
      'lesson:l4',
      'lesson:l5',
      'exam:5',
      'lesson:l6',
      'chest:6',
      'lesson:l7',
    ]);
    const exam = items.find((i) => i.kind === 'exam');
    expect(exam).toMatchObject({
      lessonIds: ['l1', 'l2', 'l3', 'l4', 'l5'],
      title: 'آزمون جامع درس‌های 1 تا 5',
    });
  });

  it('opens one lesson at a time and the chest once its lessons are done', () => {
    const fresh = buildPathItems(lessons, none, rules);
    expect(fresh.filter((i) => i.status === 'active').map((i) => i.id)).toEqual(
      ['lesson:l1'],
    );

    const progress = {
      ...none,
      completedLessonIds: new Set(['l1', 'l2', 'l3']),
    };
    const items = buildPathItems(lessons, progress, rules);
    const status = Object.fromEntries(items.map((i) => [i.id, i.status]));
    expect(status['lesson:l3']).toBe('completed');
    expect(status['chest:3']).toBe('active');
    // The chest does not block the next lesson.
    expect(status['lesson:l4']).toBe('active');
    expect(status['lesson:l5']).toBe('locked');
  });

  it('keeps later lessons locked until the exam is passed', () => {
    const progress = {
      ...none,
      completedLessonIds: new Set(['l1', 'l2', 'l3', 'l4', 'l5', 'l6']),
      openedChestPositions: new Set([3]),
    };
    let items = buildPathItems(lessons, progress, rules);
    let status = Object.fromEntries(items.map((i) => [i.id, i.status]));
    expect(status['chest:3']).toBe('completed');
    expect(status['exam:5']).toBe('active');
    expect(status['lesson:l6']).toBe('completed');
    expect(status['chest:6']).toBe('locked');
    expect(status['lesson:l7']).toBe('locked');

    items = buildPathItems(
      lessons,
      { ...progress, passedExamPositions: new Set([5]) },
      rules,
    );
    status = Object.fromEntries(items.map((i) => [i.id, i.status]));
    expect(status['exam:5']).toBe('completed');
    expect(status['chest:6']).toBe('active');
    expect(status['lesson:l7']).toBe('active');
  });

  it('can turn exams and chests off', () => {
    const items = buildPathItems(lessons, none, {
      examEvery: 0,
      chestEvery: 0,
    });
    expect(items.every((i) => i.kind === 'lesson')).toBe(true);
  });
});

describe('pickExamExercises', () => {
  it('takes up to N per lesson and skips essays', () => {
    const exercises = [
      { id: 'a', lessonId: 'l1', type: 'multiple_choice' },
      { id: 'b', lessonId: 'l1', type: 'essay' },
      { id: 'c', lessonId: 'l1', type: 'cloze_typing' },
      { id: 'd', lessonId: 'l1', type: 'matching' },
      { id: 'e', lessonId: 'l2', type: 'true_false' },
      { id: 'f', lessonId: 'l9', type: 'true_false' },
    ];
    const picked = pickExamExercises(exercises, ['l1', 'l2'], 2);
    expect(picked).toHaveLength(3);
    expect(picked.map((e) => e.id)).not.toContain('b');
    expect(picked.map((e) => e.id)).not.toContain('f');
    expect(picked.map((e) => e.id)).toContain('e');
  });
});

describe('rollChestRewards', () => {
  it('always gives energy and XP', () => {
    for (const r of [0, 0.5, 0.99]) {
      const rewards = rollChestRewards(() => r);
      expect(rewards.energy).toBeGreaterThanOrEqual(2);
      expect(rewards.energy).toBeLessThanOrEqual(5);
      expect(rewards.xp).toBeGreaterThanOrEqual(15);
    }
  });
});
