import { QuestionDefinition } from './question-definition';
import {
  imageWordQuestion,
  listeningQuestion,
  multipleChoiceQuestion,
  trueFalseQuestion,
} from './definitions/choice.questions';
import {
  clozeTypingQuestion,
  matchingQuestion,
  reorderQuestion,
  wordBankQuestion,
} from './definitions/sequence.questions';
import {
  essayQuestion,
  shortAnswerQuestion,
  speakingQuestion,
  translationQuestion,
} from './definitions/text.questions';

export * from './question-definition';

/** Every question type the platform knows. Register new modules here. */
const DEFINITIONS: QuestionDefinition[] = [
  multipleChoiceQuestion,
  matchingQuestion,
  clozeTypingQuestion,
  wordBankQuestion,
  translationQuestion,
  reorderQuestion,
  listeningQuestion,
  speakingQuestion,
  imageWordQuestion,
  trueFalseQuestion,
  shortAnswerQuestion,
  essayQuestion,
];

const BY_TYPE = new Map(DEFINITIONS.map((d) => [d.type, d]));

export function getQuestionDefinition(
  type: string,
): QuestionDefinition | undefined {
  return BY_TYPE.get(type);
}

export function listQuestionDefinitions(): QuestionDefinition[] {
  return DEFINITIONS;
}

/** Types the AI content pipeline can generate from source text. */
export function listGeneratableQuestionTypes(): QuestionDefinition[] {
  return DEFINITIONS.filter((d) => d.generation);
}
