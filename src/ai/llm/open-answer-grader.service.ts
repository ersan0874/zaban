import { Inject, Injectable } from '@nestjs/common';
import { OpenAnswerGrader } from '../../questions/registry';
import { LLM_PROVIDER, type LlmProvider } from './llm.types';

const SYSTEM = `You grade a learner's answer to an open (essay) question.
Compare it with the reference answer and the key points. Judge meaning, not wording or language:
the learner may answer in Persian or English, with typos. For math, accept equivalent forms and
correct reasoning. score is 0..1 (fraction of key points correctly covered, minus serious errors).
feedback: 1-2 short sentences in the learner's language — what was right and what was missing.`;

@Injectable()
export class OpenAnswerGraderService implements OpenAnswerGrader {
  constructor(@Inject(LLM_PROVIDER) private readonly llm: LlmProvider) {}

  async grade(input: {
    question: string;
    referenceAnswer: string;
    keyPoints: string[];
    response: string;
  }) {
    const { data } = await this.llm.generateJson<{
      score: number;
      feedback: string;
    }>({
      system: SYSTEM,
      tier: 'lite',
      temperature: 0,
      parts: [
        {
          text: JSON.stringify({
            question: input.question,
            referenceAnswer: input.referenceAnswer,
            keyPoints: input.keyPoints,
            learnerAnswer: input.response.slice(0, 4000),
          }),
        },
      ],
      schema: {
        type: 'object',
        properties: {
          score: { type: 'number', minimum: 0, maximum: 1 },
          feedback: { type: 'string' },
        },
        required: ['score', 'feedback'],
      },
    });
    return { score: Number(data.score) || 0, feedback: data.feedback ?? '' };
  }
}
