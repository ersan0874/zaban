import { QuestionType } from '../../types/question.types';
import { QuestionDefinition } from '../question-definition';
import {
  arraysEqualNormalized,
  asRecord,
  asStringArray,
  binary,
  isNonEmptyString,
  normalizeText,
  shuffle,
} from '../helpers';

type MatchingItem = {
  instruction: string;
  pairs: Array<{ left: string; right: string }>;
};

export const matchingQuestion: QuestionDefinition = {
  type: QuestionType.MATCHING,
  label: 'جورکردنی',
  generation: {
    instructions:
      '3 to 5 pairs to connect (term ↔ definition, concept ↔ example, word ↔ meaning). All left items unique, all right items unique.',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        pairs: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              left: { type: 'string' },
              right: { type: 'string' },
            },
            required: ['left', 'right'],
          },
        },
      },
      required: ['instruction', 'pairs'],
    },
    toExercise: (item: MatchingItem) => ({
      prompt: item.instruction,
      content: {
        leftItems: item.pairs.map((p) => p.left),
        rightItems: shuffle(item.pairs.map((p) => p.right)),
      },
      answer: {
        pairs: Object.fromEntries(item.pairs.map((p) => [p.left, p.right])),
      },
    }),
  },
  validate: ({ content, answer }) => {
    const left = asStringArray(content.leftItems);
    const right = asStringArray(content.rightItems);
    const pairs = asRecord(answer.pairs);
    const errors: string[] = [];
    if (left.length < 2) errors.push('needs at least 2 pairs');
    if (new Set(left).size !== left.length) errors.push('left items repeat');
    if (new Set(right).size !== right.length) errors.push('right items repeat');
    for (const key of left) {
      if (!right.includes(String(pairs[key]))) {
        errors.push(`no valid match for "${key}"`);
      }
    }
    return errors;
  },
  grade: (answer, response) => {
    const expectedPairs = asRecord(answer.pairs);
    const givenPairs = asRecord(asRecord(response).pairs ?? response);
    const keys = Object.keys(expectedPairs);
    if (keys.length === 0) return binary(false);
    return binary(
      keys.every(
        (key) =>
          normalizeText(expectedPairs[key]) === normalizeText(givenPairs[key]),
      ),
    );
  },
};

const BLANK = '_____';

type ClozeItem = { instruction: string; text: string; answers: string[] };

export const clozeTypingQuestion: QuestionDefinition = {
  type: QuestionType.CLOZE_TYPING,
  label: 'جای خالی',
  generation: {
    instructions: `A sentence from the lesson with 1-2 key words removed. Mark each blank in text with exactly "${BLANK}" (five underscores). answers lists the missing words in order. Each answer must be a plain word or number that is easy to type — never a formula or LaTeX.`,
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        text: { type: 'string' },
        answers: { type: 'array', items: { type: 'string' } },
      },
      required: ['instruction', 'text', 'answers'],
    },
    toExercise: (item: ClozeItem) => ({
      prompt: item.instruction,
      content: {
        text: item.text,
        blanks: item.answers.map((_, i) => ({
          id: `blank_${i + 1}`,
          position: i,
        })),
      },
      answer: {
        blanks: Object.fromEntries(
          item.answers.map((a, i) => [`blank_${i + 1}`, a]),
        ),
      },
    }),
  },
  validate: ({ content, answer }) => {
    const text = typeof content.text === 'string' ? content.text : '';
    const blanks = Array.isArray(content.blanks) ? content.blanks : [];
    const expected = asRecord(answer.blanks);
    const markers = text.split(BLANK).length - 1;
    const errors: string[] = [];
    if (blanks.length === 0) errors.push('needs at least one blank');
    if (markers !== blanks.length) {
      errors.push(
        `text has ${markers} blank markers but ${blanks.length} answers`,
      );
    }
    for (const blank of blanks) {
      if (!isNonEmptyString(expected[String(asRecord(blank).id)])) {
        errors.push('a blank has no answer');
      }
    }
    return errors;
  },
  grade: (answer, response) => {
    const expectedBlanks = asRecord(answer.blanks);
    const givenBlanks = asRecord(asRecord(response).blanks ?? response);
    const keys = Object.keys(expectedBlanks);
    if (keys.length === 0) return binary(false);
    return binary(
      keys.every(
        (key) =>
          normalizeText(expectedBlanks[key]) ===
          normalizeText(givenBlanks[key]),
      ),
    );
  },
};

function gradeOrder(answer: Record<string, unknown>, response: unknown) {
  const expected = asStringArray(answer.order);
  const given = asStringArray(asRecord(response).order ?? response);
  return binary(arraysEqualNormalized(expected, given));
}

type WordBankItem = { instruction: string; sentenceTokens: string[] };

export const wordBankQuestion: QuestionDefinition = {
  type: QuestionType.WORD_BANK,
  label: 'بانک کلمات',
  generation: {
    instructions:
      'A short sentence (4-10 tokens) the learner rebuilds by tapping words. sentenceTokens is the correct sentence split into tokens, in order.',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        sentenceTokens: { type: 'array', items: { type: 'string' } },
      },
      required: ['instruction', 'sentenceTokens'],
    },
    toExercise: (item: WordBankItem) => ({
      prompt: item.instruction,
      content: { bank: shuffle(item.sentenceTokens) },
      answer: { order: item.sentenceTokens },
    }),
  },
  validate: ({ content, answer }) => {
    const bank = asStringArray(content.bank);
    const order = asStringArray(answer.order);
    const errors: string[] = [];
    if (order.length < 2) errors.push('needs at least 2 tokens');
    if (order.some((token) => !bank.includes(token))) {
      errors.push('answer uses tokens missing from the bank');
    }
    return errors;
  },
  grade: gradeOrder,
};

type ReorderItem = { instruction: string; itemsInOrder: string[] };

export const reorderQuestion: QuestionDefinition = {
  type: QuestionType.REORDER,
  label: 'مرتب‌سازی',
  generation: {
    instructions:
      '3 to 6 items that have one correct order (steps of a procedure, events in time, sizes, letters of a word). itemsInOrder is the correct order.',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        itemsInOrder: { type: 'array', items: { type: 'string' } },
      },
      required: ['instruction', 'itemsInOrder'],
    },
    toExercise: (item: ReorderItem) => ({
      prompt: item.instruction,
      content: { items: shuffle(item.itemsInOrder) },
      answer: { order: item.itemsInOrder },
    }),
  },
  validate: ({ content, answer }) => {
    const items = asStringArray(content.items);
    const order = asStringArray(answer.order);
    const errors: string[] = [];
    if (order.length < 2) errors.push('needs at least 2 items');
    if (
      items.length !== order.length ||
      [...items].sort().join('\u0000') !== [...order].sort().join('\u0000')
    ) {
      errors.push('items and answer order differ');
    }
    return errors;
  },
  grade: gradeOrder,
};
