import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiJob } from './entities/ai-job.entity';
import { AiService } from './ai.service';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Lesson } from '../lessons/entities/lesson.entity';

@Module({
  imports: [TypeOrmModule.forFeature([AiJob, Exercise, Lesson])],
  providers: [AiService],
  exports: [AiService],
})
export class AiModule {}
