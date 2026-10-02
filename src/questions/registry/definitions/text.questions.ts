import { QuestionType } from '../../types/question.types';
import { QuestionDefinition } from '../question-definition';
import {
  asRecord,
  asStringArray,
  binary,
  isNonEmptyString,
  normalizeText,
  textResponse,
} from '../helpers';

const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';
const ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩';

/** Looser comparison for short answers: unify digits, drop edge punctuation. */
function normalizeShort(value: unknown): string {
  return normalizeText(value)
    .replace(/[۰-۹]/g, (d) => String(PERSIAN_DIGITS.indexOf(d)))
    .replace(/[٠-٩]/g, (d) => String(ARABIC_DIGITS.indexOf(d)))
    .replace(/[ي]/g, 'ی')
    .replace(/[ك]/g, 'ک')
    .replace(/^[\s.,;:!?،؛"'«»()]+|[\s.,;:!?،؛"'«»()]+$/g, '');
}

type TranslationItem = {
  instruction: string;
  direction: 'en_to_fa' | 'fa_to_en';
  source: string;
  acceptedAnswers: string[];
};

export const translationQuestion: QuestionDefinition = {
  type: QuestionType.TRANSLATION,
  label: 'ترجمه',
  generation: {
    instructions:
      'Only for language content: a short sentence to translate between English and Persian. acceptedAnswers lists every common correct translation.',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        direction: { type: 'string', enum: ['en_to_fa', 'fa_to_en'] },
        source: { type: 'string' },
        acceptedAnswers: { type: 'array', items: { type: 'string' } },
      },
      required: ['instruction', 'direction', 'source', 'acceptedAnswers'],
    },
    toExercise: (item: TranslationItem) => ({
      prompt: item.instruction,
      content: { direction: item.direction, source: item.source },
      answer: { texts: item.acceptedAnswers },
    }),
  },
  validate: ({ content, answer }) => [
    ...(isNonEmptyString(content.source) ? [] : ['source is empty']),
    ...(asStringArray(answer.texts).length > 0
      ? []
      : ['needs at least one accepted answer']),
  ],
  grade: (answer, response) => {
    const accepted = asStringArray(answer.texts).map(normalizeText);
    const given = normalizeText(textResponse(response, 'text', 'translation'));
    return binary(accepted.length > 0 && accepted.includes(given));
  },
};

export const speakingQuestion: QuestionDefinition = {
  type: QuestionType.SPEAKING,
  label: 'گفتاری',
  validate: ({ answer }) =>
    isNonEmptyString(answer.text) ? [] : ['answer.text is empty'],
  grade: (answer, response) => {
    const expected = normalizeText(answer.text);
    const given = normalizeText(textResponse(response, 'text', 'transcript'));
    return binary(expected.length > 0 && expected === given);
  },
};

type ShortAnswerItem = {
  instruction: string;
  question: string;
  acceptedAnswers: string[];
};

export const shortAnswerQuestion: QuestionDefinition = {
  type: QuestionType.SHORT_ANSWER,
  label: 'پاسخ کوتاه',
  generation: {
    instructions:
      'A question whose answer is one word, a number or a very short phrase. acceptedAnswers lists all acceptable spellings/forms (e.g. "12" and "twelve").',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        question: { type: 'string' },
        acceptedAnswers: { type: 'array', items: { type: 'string' } },
      },
      required: ['instruction', 'question', 'acceptedAnswers'],
    },
    toExercise: (item: ShortAnswerItem) => ({
      prompt: item.instruction,
      content: { question: item.question },
      answer: { texts: item.acceptedAnswers },
    }),
  },
  validate: ({ content, answer }) => [
    ...(isNonEmptyString(content.question) ? [] : ['question is empty']),
    ...(asStringArray(answer.texts).length > 0
      ? []
      : ['needs at least one accepted answer']),
  ],
  grade: (answer, response) => {
    const accepted = asStringArray(answer.texts).map(normalizeShort);
    const given = normalizeShort(textResponse(response, 'text', 'answer'));
    return binary(given.length > 0 && accepted.includes(given));
  },
};

type EssayItem = {
  instruction: string;
  question: string;
  referenceAnswer: string;
  keyPoints: string[];
};

export const essayQuestion: QuestionDefinition = {
  type: QuestionType.ESSAY,
  label: 'تشریحی',
  generation: {
    instructions:
      'An open question that needs a few sentences (or a worked solution) to answer. referenceAnswer is a complete model answer; keyPoints are 2-5 points a correct answer must contain (used for grading).',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        question: { type: 'string' },
        referenceAnswer: { type: 'string' },
        keyPoints: { type: 'array', items: { type: 'string' } },
      },
      required: ['instruction', 'question', 'referenceAnswer', 'keyPoints'],
    },
    toExercise: (item: EssayItem) => ({
      prompt: item.instruction,
      content: { question: item.question },
      answer: {
        referenceAnswer: item.referenceAnswer,
        keyPoints: item.keyPoints,
      },
    }),
  },
  validate: ({ content, answer }) => [
    ...(isNonEmptyString(content.question) ? [] : ['question is empty']),
    ...(isNonEmptyString(answer.referenceAnswer)
      ? []
      : ['referenceAnswer is empty']),
    ...(asStringArray(answer.keyPoints).length > 0
      ? []
      : ['needs at least one key point']),
  ],
  grade: async (answer, response, ctx) => {
    const given = textResponse(response, 'text', 'answer').trim();
    const referenceAnswer =
      typeof answer.referenceAnswer === 'string' ? answer.referenceAnswer : '';
    if (given.length === 0) {
      return { correct: false, score: 0, status: 'graded', feedback: null };
    }
    if (!ctx.openAnswerGrader) {
      return { correct: false, score: 0, status: 'pending', feedback: null };
    }
    try {
      const { score, feedback } = await ctx.openAnswerGrader.grade({
        question: textResponse(asRecord(ctx.content), 'question') || ctx.prompt,
        referenceAnswer,
        keyPoints: asStringArray(answer.keyPoints),
        response: given,
      });
      const clamped = Math.max(0, Math.min(1, score));
      return {
        correct: clamped >= 0.6,
        score: clamped,
        feedback,
        status: 'graded',
      };
    } catch {
      return { correct: false, score: 0, status: 'pending', feedback: null };
    }
  },
};
