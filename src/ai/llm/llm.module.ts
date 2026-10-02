import { Module } from '@nestjs/common';
import { GeminiProvider } from './gemini.provider';
import { LLM_PROVIDER } from './llm.types';
import { OpenAnswerGraderService } from './open-answer-grader.service';

@Module({
  providers: [
    GeminiProvider,
    { provide: LLM_PROVIDER, useExisting: GeminiProvider },
    OpenAnswerGraderService,
  ],
  exports: [LLM_PROVIDER, OpenAnswerGraderService],
})
export class LlmModule {}
