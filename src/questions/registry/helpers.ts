import { GradeResult } from './question-definition';

export function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

export function normalizeText(value: unknown): string {
  if (value === null || value === undefined) return '';
  const text =
    typeof value === 'string' || typeof value === 'number'
      ? String(value)
      : JSON.stringify(value);
  return text.trim().toLowerCase().replace(/\s+/g, ' ');
}

export function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((v) => (typeof v === 'string' ? v : JSON.stringify(v)));
}

export function arraysEqualNormalized(a: string[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  return a.every((item, i) => normalizeText(item) === normalizeText(b[i]));
}

/** Reads a free-text response sent either as a string or `{ [key]: string }`. */
export function textResponse(response: unknown, ...keys: string[]): string {
  if (typeof response === 'string') return response;
  const record = asRecord(response);
  for (const key of keys) {
    if (typeof record[key] === 'string') return record[key];
  }
  return '';
}

export function binary(correct: boolean): GradeResult {
  return { correct, score: correct ? 1 : 0, status: 'graded' };
}

export function shuffle<T>(items: T[]): T[] {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

export function isNonEmptyString(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}
