import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LlmModule } from '../ai/llm/llm.module';
import { ContentJob } from './entities/content-job.entity';
import { ContentSourceFile } from './entities/content-source-file.entity';
import { ContentProposal } from './entities/content-proposal.entity';
import { ContentDraftLesson } from './entities/content-draft-lesson.entity';
import { ContentDraftExercise } from './entities/content-draft-exercise.entity';
import { ContentController } from './content.controller';
import { ContentService } from './content.service';
import { ContentQueueService } from './content-queue.service';
import { ContentPipelineService } from './pipeline/content-pipeline.service';
import { SourceExtractorService } from './pipeline/source-extractor.service';
import { AdminGuard } from '../admin/guards/admin.guard';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ContentJob,
      ContentSourceFile,
      ContentProposal,
      ContentDraftLesson,
      ContentDraftExercise,
    ]),
    LlmModule,
  ],
  controllers: [ContentController],
  providers: [
    ContentService,
    ContentQueueService,
    ContentPipelineService,
    SourceExtractorService,
    AdminGuard,
  ],
})
export class ContentModule {}
