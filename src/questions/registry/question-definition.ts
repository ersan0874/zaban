/**
 * A question module: everything the platform needs to know about one
 * question type lives in a single definition file under `definitions/`.
 * Adding a new type = add a definition + register it in `index.ts`.
 */

export type JsonSchema = Record<string, unknown>;

export interface ExerciseData {
  prompt: string;
  content: Record<string, unknown>;
  answer: Record<string, unknown>;
}

export interface GradeResult {
  correct: boolean;
  /** 0..1 — partial credit for open-ended types, otherwise 0 or 1. */
  score: number;
  feedback?: string | null;
  /** `pending` = could not be graded now (AI unavailable) and will be retried. */
  status: 'graded' | 'pending' | 'ungraded';
}

/** Grades an open-ended answer against a reference (implemented with an LLM). */
export interface OpenAnswerGrader {
  grade(input: {
    question: string;
    referenceAnswer: string;
    keyPoints: string[];
    response: string;
  }): Promise<{ score: number; feedback: string }>;
}

export interface GradeContext {
  prompt: string;
  content: Record<string, unknown>;
  openAnswerGrader?: OpenAnswerGrader;
}

export interface QuestionGeneration<Item = Record<string, unknown>> {
  /** What the model should produce for this type (English, model-facing). */
  instructions: string;
  /** JSON Schema of ONE generated item. */
  itemSchema: JsonSchema;
  /** Maps a generated item to the stored exercise shape. */
  toExercise(item: Item): ExerciseData;
}

export interface QuestionDefinition {
  type: string;
  /** Admin-facing label. */
  label: string;
  /** Present when the AI pipeline can generate this type from text. */
  generation?: QuestionGeneration<any>;
  /** Returns human-readable problems; empty array = valid. */
  validate(exercise: ExerciseData): string[];
  grade(
    answer: Record<string, unknown>,
    response: unknown,
    ctx: GradeContext,
  ): GradeResult | Promise<GradeResult>;
}
