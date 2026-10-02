/**
 * Provider-agnostic contract for structured LLM calls.
 * Gemini is the only implementation today; another provider only needs to
 * implement `LlmProvider` and be bound to `LLM_PROVIDER`.
 */
export const LLM_PROVIDER = Symbol('LLM_PROVIDER');

/** `main` = best quality model, `lite` = cheaper/faster model for simple steps. */
export type LlmTier = 'main' | 'lite';

export type LlmPart =
  | { text: string }
  | { file: { mimeType: string; data: Buffer; displayName?: string } };

export interface LlmJsonRequest {
  system?: string;
  parts: LlmPart[];
  /** Plain JSON Schema describing the expected response object. */
  schema: Record<string, unknown>;
  tier?: LlmTier;
  temperature?: number;
}

export interface LlmUsage {
  model: string;
  inputTokens: number;
  outputTokens: number;
}

export interface LlmJsonResult<T> {
  data: T;
  usage: LlmUsage;
}

export interface LlmProvider {
  generateJson<T>(request: LlmJsonRequest): Promise<LlmJsonResult<T>>;
}

/** Daily/hard quota is used up — caller should pause and retry later. */
export class LlmQuotaExhaustedError extends Error {
  constructor(
    message: string,
    readonly retryAfterMs: number,
  ) {
    super(message);
    this.name = 'LlmQuotaExhaustedError';
  }
}

/** Provider is not configured (e.g. missing API key). */
export class LlmNotConfiguredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LlmNotConfiguredError';
  }
}
