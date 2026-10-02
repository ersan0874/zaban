import { QuestionType } from '../../types/question.types';
import { QuestionDefinition } from '../question-definition';
import {
  asRecord,
  asStringArray,
  binary,
  isNonEmptyString,
  normalizeText,
  shuffle,
  textResponse,
} from '../helpers';

function gradeSingleChoice(answer: Record<string, unknown>, response: unknown) {
  const given =
    typeof response === 'string'
      ? response
      : (asRecord(response).correctOption ?? asRecord(response).selected);
  return binary(normalizeText(answer.correctOption) === normalizeText(given));
}

function validateSingleChoice(
  content: Record<string, unknown>,
  answer: Record<string, unknown>,
): string[] {
  const options = asStringArray(content.options);
  const errors: string[] = [];
  if (options.length < 2) errors.push('needs at least 2 options');
  const normalized = options.map(normalizeText);
  if (new Set(normalized).size !== normalized.length) {
    errors.push('options must be unique');
  }
  if (!normalized.includes(normalizeText(answer.correctOption))) {
    errors.push('correct option is not among the options');
  }
  return errors;
}

type ChoiceItem = {
  instruction: string;
  stem: string;
  options: string[];
  correctOption: string;
};

export const multipleChoiceQuestion: QuestionDefinition = {
  type: QuestionType.MULTIPLE_CHOICE,
  label: 'چهارگزینه‌ای',
  generation: {
    instructions:
      'A question with exactly 4 options and one unambiguous correct option. Distractors must be plausible. correctOption must be copied verbatim from options.',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        stem: { type: 'string' },
        options: { type: 'array', items: { type: 'string' } },
        correctOption: { type: 'string' },
      },
      required: ['instruction', 'stem', 'options', 'correctOption'],
    },
    toExercise: (item: ChoiceItem) => ({
      prompt: item.instruction,
      content: { stem: item.stem, options: shuffle(item.options) },
      answer: { correctOption: item.correctOption },
    }),
  },
  validate: ({ content, answer }) => [
    ...(isNonEmptyString(content.stem) ? [] : ['stem is empty']),
    ...validateSingleChoice(content, answer),
  ],
  grade: gradeSingleChoice,
};

export const listeningQuestion: QuestionDefinition = {
  type: QuestionType.LISTENING,
  label: 'شنیداری',
  validate: ({ content, answer }) => validateSingleChoice(content, answer),
  grade: gradeSingleChoice,
};

export const imageWordQuestion: QuestionDefinition = {
  type: QuestionType.IMAGE_WORD,
  label: 'تصویر و واژه',
  validate: ({ content, answer }) => validateSingleChoice(content, answer),
  grade: gradeSingleChoice,
};

type TrueFalseItem = {
  instruction: string;
  statement: string;
  isTrue: boolean;
  explanation: string;
};

function parseBoolean(response: unknown): boolean | null {
  const raw =
    typeof response === 'object' && response !== null
      ? asRecord(response).value
      : response;
  if (typeof raw === 'boolean') return raw;
  const text = normalizeText(textResponse(raw));
  if (['true', 'صحیح', 'درست', 'yes'].includes(text)) return true;
  if (['false', 'غلط', 'نادرست', 'no'].includes(text)) return false;
  return null;
}

export const trueFalseQuestion: QuestionDefinition = {
  type: QuestionType.TRUE_FALSE,
  label: 'صحیح / غلط',
  generation: {
    instructions:
      'A single factual statement that is clearly true or clearly false according to the source. Mix true and false statements. explanation says briefly why.',
    itemSchema: {
      type: 'object',
      properties: {
        instruction: { type: 'string' },
        statement: { type: 'string' },
        isTrue: { type: 'boolean' },
        explanation: { type: 'string' },
      },
      required: ['instruction', 'statement', 'isTrue', 'explanation'],
    },
    toExercise: (item: TrueFalseItem) => ({
      prompt: item.instruction,
      content: { statement: item.statement },
      answer: { value: item.isTrue, explanation: item.explanation },
    }),
  },
  validate: ({ content, answer }) => [
    ...(isNonEmptyString(content.statement) ? [] : ['statement is empty']),
    ...(typeof answer.value === 'boolean'
      ? []
      : ['answer.value must be boolean']),
  ],
  grade: (answer, response) => {
    const given = parseBoolean(response);
    const result = binary(given !== null && given === answer.value);
    return {
      ...result,
      feedback:
        typeof answer.explanation === 'string' ? answer.explanation : null,
    };
  },
};
