import { QuestionType } from '../types/question.types';
import { getQuestionDefinition, listGeneratableQuestionTypes } from './index';
import { gradeExercise } from '../../sessions/validators/exercise-grader';

describe('question registry', () => {
  it('keeps legacy grading for existing types', async () => {
    const mc = await gradeExercise(
      QuestionType.MULTIPLE_CHOICE,
      { correctOption: 'Abandon' },
      { selected: ' abandon ' },
      { prompt: '', content: {} },
    );
    expect(mc.correct).toBe(true);

    const cloze = await gradeExercise(
      QuestionType.CLOZE_TYPING,
      { blanks: { blank_1: 'diminish' } },
      { blanks: { blank_1: 'Diminish' } },
      { prompt: '', content: {} },
    );
    expect(cloze.correct).toBe(true);

    const order = await gradeExercise(
      QuestionType.REORDER,
      { order: ['a', 'b'] },
      ['b', 'a'],
      { prompt: '', content: {} },
    );
    expect(order.correct).toBe(false);
  });

  it('accepts a translation typed without the final period or half-space', async () => {
    const answer = { texts: ['این منطقه به خاطر زیبایی طبیعی‌اش مشهور است.'] };
    const ctx = { prompt: '', content: {} };
    for (const typed of [
      'این منطقه به خاطر زیبایی طبیعی‌اش مشهور است',
      'اين منطقه به خاطر زيبايي طبيعي اش مشهور است',
      'این منطقه به خاطر زیبایی طبیعیاش مشهور است!',
    ]) {
      const r = await gradeExercise(
        QuestionType.TRANSLATION,
        answer,
        { text: typed },
        ctx,
      );
      expect(r.correct).toBe(true);
    }
    const wrong = await gradeExercise(
      QuestionType.TRANSLATION,
      answer,
      { text: 'این منطقه به خاطر زیبایی طبیعی‌اش مشهور نیست' },
      ctx,
    );
    expect(wrong.correct).toBe(false);
  });

  it('grades unknown types as wrong', async () => {
    const r = await gradeExercise('nope', {}, 'x', { prompt: '', content: {} });
    expect(r).toEqual({ correct: false, score: 0, status: 'graded' });
  });

  it('accepts Persian digits for short answers', async () => {
    const r = await gradeExercise(
      QuestionType.SHORT_ANSWER,
      { texts: ['12'] },
      '۱۲.',
      { prompt: '', content: {} },
    );
    expect(r.correct).toBe(true);
  });

  it('grades true/false with Persian words', async () => {
    const r = await gradeExercise(
      QuestionType.TRUE_FALSE,
      { value: false, explanation: 'x' },
      'غلط',
      { prompt: '', content: {} },
    );
    expect(r.correct).toBe(true);
    expect(r.feedback).toBe('x');
  });

  it('uses the open-answer grader for essays and falls back to pending', async () => {
    const answer = { referenceAnswer: 'ref', keyPoints: ['a'] };
    const graded = await gradeExercise(
      QuestionType.ESSAY,
      answer,
      'my answer',
      {
        prompt: 'p',
        content: { question: 'q' },
        openAnswerGrader: {
          grade: () => Promise.resolve({ score: 0.8, feedback: 'good' }),
        },
      },
    );
    expect(graded).toMatchObject({
      correct: true,
      score: 0.8,
      status: 'graded',
    });

    const failing = await gradeExercise(QuestionType.ESSAY, answer, 'x', {
      prompt: 'p',
      content: {},
      openAnswerGrader: { grade: () => Promise.reject(new Error('down')) },
    });
    expect(failing.status).toBe('pending');
  });

  it('round-trips every generatable type through toExercise + validate', () => {
    const samples: Record<string, unknown> = {
      multiple_choice: {
        instruction: 'i',
        stem: 's',
        options: ['a', 'b', 'c', 'd'],
        correctOption: 'b',
      },
      matching: {
        instruction: 'i',
        pairs: [
          { left: 'a', right: '1' },
          { left: 'b', right: '2' },
        ],
      },
      cloze_typing: {
        instruction: 'i',
        text: 'The _____ is red.',
        answers: ['apple'],
      },
      word_bank: { instruction: 'i', sentenceTokens: ['I', 'am', 'here'] },
      translation: {
        instruction: 'i',
        direction: 'en_to_fa',
        source: 'hi',
        acceptedAnswers: ['سلام'],
      },
      reorder: { instruction: 'i', itemsInOrder: ['1', '2', '3'] },
      true_false: {
        instruction: 'i',
        statement: 's',
        isTrue: true,
        explanation: 'e',
      },
      short_answer: { instruction: 'i', question: 'q', acceptedAnswers: ['4'] },
      essay: {
        instruction: 'i',
        question: 'q',
        referenceAnswer: 'r',
        keyPoints: ['k'],
      },
    };
    for (const def of listGeneratableQuestionTypes()) {
      const exercise = def.generation!.toExercise(samples[def.type]);
      expect({ type: def.type, errors: def.validate(exercise) }).toEqual({
        type: def.type,
        errors: [],
      });
    }
    const bad = getQuestionDefinition(QuestionType.MULTIPLE_CHOICE)!.validate({
      prompt: 'p',
      content: { stem: 's', options: ['a', 'b'] },
      answer: { correctOption: 'z' },
    });
    expect(bad).toContain('correct option is not among the options');
  });
});
