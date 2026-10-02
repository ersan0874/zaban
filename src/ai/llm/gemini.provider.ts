import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiError, GoogleGenAI, type Part } from '@google/genai';
import {
  LlmJsonRequest,
  LlmJsonResult,
  LlmNotConfiguredError,
  LlmPart,
  LlmProvider,
  LlmQuotaExhaustedError,
} from './llm.types';

/** Files above this size go through the Gemini File API instead of inline data. */
const INLINE_LIMIT_BYTES = 15 * 1024 * 1024;
const MAX_ATTEMPTS = 6;
/** After this many overload errors the main model falls back to the lite model. */
const FALLBACK_AFTER_OVERLOADS = 2;
/** Free-tier daily quotas reset at Pacific midnight; we re-check hourly. */
const DAILY_QUOTA_PAUSE_MS = 60 * 60 * 1000;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

@Injectable()
export class GeminiProvider implements LlmProvider {
  private readonly logger = new Logger(GeminiProvider.name);
  private client: GoogleGenAI | null = null;
  private nextSlotAt = 0;
  private readonly exhaustedUntil = new Map<string, number>();

  constructor(private readonly config: ConfigService) {}

  private get models() {
    return {
      main: this.config.get<string>('GEMINI_MODEL', 'gemini-flash-latest'),
      lite: this.config.get<string>(
        'GEMINI_MODEL_LITE',
        'gemini-flash-lite-latest',
      ),
    };
  }

  private getClient(): GoogleGenAI {
    if (this.client) return this.client;
    const apiKey = this.config.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new LlmNotConfiguredError('GEMINI_API_KEY is not set');
    }
    this.client = new GoogleGenAI({
      apiKey,
      httpOptions: {
        timeout: Number(this.config.get('GEMINI_TIMEOUT_MS', 180_000)),
        // Retries are handled below (with model fallback), not by the SDK.
        retryOptions: { attempts: 1 },
      },
    });
    return this.client;
  }

  /** Spaces requests evenly to stay under the free-tier requests/minute cap. */
  private async waitForSlot() {
    const rpm = Math.max(1, Number(this.config.get('GEMINI_RPM', 10)));
    const interval = Math.ceil(60_000 / rpm);
    const now = Date.now();
    const slot = Math.max(now, this.nextSlotAt);
    this.nextSlotAt = slot + interval;
    if (slot > now) await sleep(slot - now);
  }

  async generateJson<T>(request: LlmJsonRequest): Promise<LlmJsonResult<T>> {
    const client = this.getClient();
    const parts = await Promise.all(
      request.parts.map((p) => this.toPart(client, p)),
    );
    const primary = this.models[request.tier ?? 'main'];
    const fallback = this.models.lite;
    const chain = primary === fallback ? [primary] : [primary, fallback];

    let lastError: unknown;
    let overloads = 0;
    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      const available = chain.filter((m) => !this.isExhausted(m));
      if (available.length === 0) {
        throw new LlmQuotaExhaustedError(
          'All configured Gemini models reached their daily quota',
          this.msUntilFirstReset(chain),
        );
      }
      // An overloaded or exhausted main model falls back to the lite model.
      const model =
        overloads >= FALLBACK_AFTER_OVERLOADS && available.length > 1
          ? available[1]
          : available[0];
      await this.waitForSlot();
      try {
        const response = await client.models.generateContent({
          model,
          contents: [{ role: 'user', parts }],
          config: {
            systemInstruction: request.system,
            temperature: request.temperature ?? 0.4,
            responseMimeType: 'application/json',
            responseJsonSchema: request.schema,
          },
        });
        const text = response.text ?? '';
        let data: T;
        try {
          data = JSON.parse(text) as T;
        } catch {
          throw new Error(
            `Model returned invalid JSON (${text.slice(0, 120)})`,
          );
        }
        return {
          data,
          usage: {
            model: response.modelVersion ?? model,
            inputTokens: response.usageMetadata?.promptTokenCount ?? 0,
            outputTokens: response.usageMetadata?.candidatesTokenCount ?? 0,
          },
        };
      } catch (err) {
        lastError = err;
        const status = err instanceof ApiError ? err.status : undefined;
        const message = err instanceof Error ? err.message : String(err);
        if (status === 429 && /per ?day|daily|PerDay/i.test(message)) {
          this.logger.warn(`Gemini ${model} reached its daily quota`);
          this.exhaustedUntil.set(model, Date.now() + DAILY_QUOTA_PAUSE_MS);
          continue;
        }
        const retryable =
          status === undefined ||
          status === 429 ||
          status >= 500 ||
          /invalid JSON/.test(message);
        if (!retryable || attempt === MAX_ATTEMPTS) break;
        if (status === 429 || status === 503) overloads++;
        const delay = Math.min(60_000, 2_000 * 2 ** (attempt - 1));
        this.logger.warn(
          `Gemini ${model} failed (${status ?? 'network'}), retry ${attempt} in ${delay}ms: ${message.slice(0, 160)}`,
        );
        await sleep(delay);
      }
    }
    if (lastError instanceof ApiError && lastError.status === 429) {
      throw new LlmQuotaExhaustedError(lastError.message, 10 * 60 * 1000);
    }
    throw lastError instanceof Error ? lastError : new Error(String(lastError));
  }

  private isExhausted(model: string) {
    return (this.exhaustedUntil.get(model) ?? 0) > Date.now();
  }

  private msUntilFirstReset(models: string[]) {
    const resets = models.map((m) => this.exhaustedUntil.get(m) ?? 0);
    return Math.max(60_000, Math.min(...resets) - Date.now());
  }

  private async toPart(client: GoogleGenAI, part: LlmPart): Promise<Part> {
    if ('text' in part) return { text: part.text };
    const { data, mimeType, displayName } = part.file;
    if (data.length <= INLINE_LIMIT_BYTES) {
      return { inlineData: { mimeType, data: data.toString('base64') } };
    }
    const uploaded = await client.files.upload({
      file: new Blob([new Uint8Array(data)], { type: mimeType }),
      config: { mimeType, displayName },
    });
    if (!uploaded.uri) throw new Error('Gemini file upload returned no URI');
    return { fileData: { fileUri: uploaded.uri, mimeType } };
  }
}
