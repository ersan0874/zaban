import {
  GradeContext,
  GradeResult,
  getQuestionDefinition,
} from '../../questions/registry';
import { asRecord } from '../../questions/registry/helpers';

/**
 * Server-side exercise grading. Client never decides correctness.
 * Each question type grades itself through its registry definition.
 */
export async function gradeExercise(
  type: string,
  answer: unknown,
  response: unknown,
  ctx: GradeContext,
): Promise<GradeResult> {
  const definition = getQuestionDefinition(type);
  if (!definition) {
    return { correct: false, score: 0, status: 'graded' };
  }
  return definition.grade(asRecord(answer), response, ctx);
}
