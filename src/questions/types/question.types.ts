/**
 * Extensible question-type identifiers.
 * Add new string values as new question modules are introduced.
 */
export enum QuestionType {
  MULTIPLE_CHOICE = 'multiple_choice',
  MATCHING = 'matching',
  CLOZE_TYPING = 'cloze_typing',
  WORD_BANK = 'word_bank',
  TRANSLATION = 'translation',
  REORDER = 'reorder',
  LISTENING = 'listening',
  SPEAKING = 'speaking',
  IMAGE_WORD = 'image_word',
}

/** Placement / adaptive difficulty bands */
export enum QuestionDifficulty {
  EASY = 'easy',
  STANDARD = 'standard',
  HARD = 'hard',
}

/** Multiple-choice */
export interface MultipleChoiceContent {
  options: string[];
  stem?: string;
}
export interface MultipleChoiceAnswer {
  correctOption: string;
}

/** Matching */
export interface MatchingContent {
  leftItems: string[];
  rightItems: string[];
}
export interface MatchingAnswer {
  pairs: Record<string, string>;
}

/** Cloze / fill-in-the-blank typing */
export interface ClozeTypingContent {
  text: string;
  blanks: Array<{ id: string; position: number }>;
}
export interface ClozeTypingAnswer {
  blanks: Record<string, string>;
}

/** Word bank tapping — build ordered tokens from a bank */
export interface WordBankContent {
  instruction?: string;
  bank: string[];
}
export interface WordBankAnswer {
  order: string[];
}

/** Bidirectional translation */
export interface TranslationContent {
  direction: 'en_to_fa' | 'fa_to_en';
  source: string;
}
export interface TranslationAnswer {
  /** Any accepted normalized answer */
  texts: string[];
}

/** Reorder / sorting */
export interface ReorderContent {
  items: string[];
}
export interface ReorderAnswer {
  order: string[];
}

/** Listening — assets filled in Phase 12; UI works with placeholders */
export interface ListeningContent {
  audioUrl?: string | null;
  slowAudioUrl?: string | null;
  options: string[];
  hint?: string;
}
export interface ListeningAnswer {
  correctOption: string;
}

/** Speaking — STT engine in Phase 12; typed fallback allowed for now */
export interface SpeakingContent {
  prompt: string;
  targetText: string;
}
export interface SpeakingAnswer {
  text: string;
}

/** Image-word — image asset in Phase 12 */
export interface ImageWordContent {
  imageUrl?: string | null;
  imageLabel?: string;
  options: string[];
}
export interface ImageWordAnswer {
  correctOption: string;
}

export type QuestionContent =
  | MultipleChoiceContent
  | MatchingContent
  | ClozeTypingContent
  | WordBankContent
  | TranslationContent
  | ReorderContent
  | ListeningContent
  | SpeakingContent
  | ImageWordContent
  | Record<string, unknown>;

export type QuestionAnswer =
  | MultipleChoiceAnswer
  | MatchingAnswer
  | ClozeTypingAnswer
  | WordBankAnswer
  | TranslationAnswer
  | ReorderAnswer
  | ListeningAnswer
  | SpeakingAnswer
  | ImageWordAnswer
  | string
  | string[]
  | Record<string, unknown>;
