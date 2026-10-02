import { asRecord, asStringArray } from '../../questions/registry/helpers';

function text(value: unknown): string | null {
  if (typeof value === 'string' || typeof value === 'number') {
    const s = String(value).trim();
    return s.length > 0 ? s : null;
  }
  return null;
}

/**
 * Human-readable correct answer, shown in the feedback bar after a wrong
 * answer. Revealed only after the user has answered that exercise.
 */
export function describeSolution(type: string, answer: unknown): string | null {
  const a = asRecord(answer);
  switch (type) {
    case 'multiple_choice':
    case 'listening':
    case 'image_word':
      return text(a.correctOption);
    case 'true_false':
      return typeof a.value === 'boolean'
        ? a.value
          ? 'درست'
          : 'نادرست'
        : null;
    case 'matching': {
      const pairs = Object.entries(asRecord(a.pairs))
        .map(([k, v]) => [k, text(v)] as const)
        .filter(([, v]) => v !== null);
      return pairs.length === 0
        ? null
        : pairs.map(([k, v]) => `${k} = ${v}`).join('، ');
    }
    case 'cloze_typing': {
      const blanks = Object.values(asRecord(a.blanks))
        .map(text)
        .filter((v): v is string => v !== null);
      return blanks.length === 0 ? null : blanks.join('، ');
    }
    case 'word_bank':
    case 'reorder': {
      const order = asStringArray(a.order);
      // Letter-reorder puzzles spell one word; word puzzles form a sentence.
      const letters = order.every((t) => [...t].length === 1);
      return order.length === 0 ? null : order.join(letters ? '' : ' ');
    }
    case 'translation':
    case 'short_answer':
      return asStringArray(a.texts)[0] ?? null;
    case 'speaking':
      return text(a.text);
    case 'essay':
      return text(a.referenceAnswer);
    default:
      return null;
  }
}
