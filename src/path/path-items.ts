/**
 * The learning path, one stop per lesson, with a review exam after every
 * `examEvery` lessons and a reward chest after every `chestEvery` lessons.
 * Pure so the API, its tests and the browser demo share one implementation.
 */

export type PathItemStatus = 'locked' | 'active' | 'completed';

export type PathLessonInput = {
  id: string;
  title: string;
  unitId: string;
  unitTitle: string;
  sectionTitle: string | null;
};

export type PathItem =
  | {
      kind: 'lesson';
      id: string;
      lessonId: string;
      title: string;
      unitId: string;
      unitTitle: string;
      sectionTitle: string | null;
      /** 1-based lesson number on the path. */
      number: number;
      status: PathItemStatus;
    }
  | {
      kind: 'exam';
      id: string;
      /** Lesson number the exam follows; also its key in the API. */
      position: number;
      title: string;
      unitId: string;
      unitTitle: string;
      sectionTitle: string | null;
      lessonIds: string[];
      fromNumber: number;
      toNumber: number;
      status: PathItemStatus;
    }
  | {
      kind: 'chest';
      id: string;
      position: number;
      title: string;
      unitId: string;
      unitTitle: string;
      sectionTitle: string | null;
      status: PathItemStatus;
    };

export type PathRules = { examEvery: number; chestEvery: number };

export type PathProgress = {
  completedLessonIds: ReadonlySet<string>;
  passedExamPositions: ReadonlySet<number>;
  openedChestPositions: ReadonlySet<number>;
};

export function examTitle(fromNumber: number, toNumber: number): string {
  return `آزمون جامع درس‌های ${fromNumber} تا ${toNumber}`;
}

export function buildPathItems(
  lessons: PathLessonInput[],
  progress: PathProgress,
  rules: PathRules,
): PathItem[] {
  const items: PathItem[] = [];
  // Lessons and exams are taken in order; a chest never blocks the path.
  let gateOpen = true;
  let everythingBeforeDone = true;
  let lastExamAt = 0;

  const nextStatus = (done: boolean): PathItemStatus => {
    if (done) return 'completed';
    everythingBeforeDone = false;
    if (gateOpen) {
      gateOpen = false;
      return 'active';
    }
    return 'locked';
  };

  lessons.forEach((lesson, index) => {
    const number = index + 1;
    const where = {
      unitId: lesson.unitId,
      unitTitle: lesson.unitTitle,
      sectionTitle: lesson.sectionTitle,
    };
    items.push({
      kind: 'lesson',
      id: `lesson:${lesson.id}`,
      lessonId: lesson.id,
      title: lesson.title,
      number,
      ...where,
      status: nextStatus(progress.completedLessonIds.has(lesson.id)),
    });

    if (rules.examEvery > 0 && number % rules.examEvery === 0) {
      const covered = lessons.slice(lastExamAt, number);
      items.push({
        kind: 'exam',
        id: `exam:${number}`,
        position: number,
        title: examTitle(lastExamAt + 1, number),
        lessonIds: covered.map((l) => l.id),
        fromNumber: lastExamAt + 1,
        toNumber: number,
        ...where,
        status: nextStatus(progress.passedExamPositions.has(number)),
      });
      lastExamAt = number;
    }

    if (rules.chestEvery > 0 && number % rules.chestEvery === 0) {
      const opened = progress.openedChestPositions.has(number);
      items.push({
        kind: 'chest',
        id: `chest:${number}`,
        position: number,
        title: 'جعبه‌ی جایزه',
        ...where,
        status: opened
          ? 'completed'
          : everythingBeforeDone
            ? 'active'
            : 'locked',
      });
    }
  });

  return items;
}

export type ChestRewards = {
  energy: number;
  gems: number;
  xp: number;
  streakFreeze: number;
};

/** Every chest gives energy and XP; gems and a streak freeze are luck. */
export function rollChestRewards(
  random: () => number = Math.random,
): ChestRewards {
  const between = (min: number, max: number) =>
    min + Math.floor(random() * (max - min + 1));
  return {
    energy: between(2, 5),
    xp: between(15, 40),
    gems: random() < 0.6 ? between(5, 20) : 0,
    streakFreeze: random() < 0.2 ? 1 : 0,
  };
}

/** Up to `perLesson` questions from each covered lesson, shuffled. */
export function pickExamExercises<T extends { lessonId: string; type: string }>(
  exercises: T[],
  lessonIds: string[],
  perLesson: number,
  random: () => number = Math.random,
): T[] {
  const shuffle = <U>(list: U[]): U[] => {
    const copy = [...list];
    for (let i = copy.length - 1; i > 0; i--) {
      const j = Math.floor(random() * (i + 1));
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  };
  const picked: T[] = [];
  for (const lessonId of lessonIds) {
    // Essays need AI grading and are slow; an exam keeps to instant ones.
    const own = exercises.filter(
      (ex) => ex.lessonId === lessonId && ex.type !== 'essay',
    );
    picked.push(...shuffle(own).slice(0, perLesson));
  }
  return shuffle(picked);
}
