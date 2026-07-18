/**
 * Extensible question-type identifiers.
 * Add new string values as new question modules are introduced.
 */
export enum QuestionType {
  MULTIPLE_CHOICE = 'multiple_choice',
  MATCHING = 'matching',
  CLOZE_TYPING = 'cloze_typing',
}

/** Multiple-choice: options list + optional stem metadata */
export interface MultipleChoiceContent {
  options: string[];
  stem?: string;
}

export interface MultipleChoiceAnswer {
  correctOption: string;
}

/** Matching: left items paired with right items */
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
  blanks: Array<{
    id: string;
    position: number;
  }>;
}

export interface ClozeTypingAnswer {
  blanks: Record<string, string>;
}

export type QuestionContent =
  | MultipleChoiceContent
  | MatchingContent
  | ClozeTypingContent
  | Record<string, unknown>;

export type QuestionAnswer =
  | MultipleChoiceAnswer
  | MatchingAnswer
  | ClozeTypingAnswer
  | string
  | string[]
  | Record<string, unknown>;
