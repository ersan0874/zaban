import { QuestionType } from '../../questions/types/question.types';

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function normalizeText(value: unknown): string {
  return String(value ?? '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v));
}

function arraysEqualNormalized(a: string[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  return a.every((item, i) => normalizeText(item) === normalizeText(b[i]));
}

/**
 * Server-side exercise graders. Client never decides correctness.
 */
export function gradeExercise(
  type: string,
  answer: unknown,
  response: unknown,
): boolean {
  switch (type) {
    case QuestionType.MULTIPLE_CHOICE:
    case QuestionType.LISTENING:
    case QuestionType.IMAGE_WORD: {
      const expected = asRecord(answer).correctOption;
      const given =
        typeof response === 'string'
          ? response
          : (asRecord(response).correctOption ??
            asRecord(response).selected);
      return normalizeText(expected) === normalizeText(given);
    }
    case QuestionType.MATCHING: {
      const expectedPairs = asRecord(asRecord(answer).pairs);
      const givenPairs = asRecord(asRecord(response).pairs ?? response);
      const keys = Object.keys(expectedPairs);
      if (keys.length === 0) return false;
      return keys.every(
        (key) =>
          normalizeText(expectedPairs[key]) === normalizeText(givenPairs[key]),
      );
    }
    case QuestionType.CLOZE_TYPING: {
      const expectedBlanks = asRecord(asRecord(answer).blanks);
      const givenBlanks = asRecord(asRecord(response).blanks ?? response);
      const keys = Object.keys(expectedBlanks);
      if (keys.length === 0) return false;
      return keys.every(
        (key) =>
          normalizeText(expectedBlanks[key]) ===
          normalizeText(givenBlanks[key]),
      );
    }
    case QuestionType.WORD_BANK:
    case QuestionType.REORDER: {
      const expected = asStringArray(asRecord(answer).order);
      const given = asStringArray(
        asRecord(response).order ?? response,
      );
      return arraysEqualNormalized(expected, given);
    }
    case QuestionType.TRANSLATION: {
      const accepted = asStringArray(asRecord(answer).texts).map(normalizeText);
      const given = normalizeText(
        typeof response === 'string'
          ? response
          : (asRecord(response).text ?? asRecord(response).translation),
      );
      return accepted.length > 0 && accepted.includes(given);
    }
    case QuestionType.SPEAKING: {
      const expected = normalizeText(asRecord(answer).text);
      const given = normalizeText(
        typeof response === 'string'
          ? response
          : (asRecord(response).text ?? asRecord(response).transcript),
      );
      return expected.length > 0 && expected === given;
    }
    default:
      return false;
  }
}
