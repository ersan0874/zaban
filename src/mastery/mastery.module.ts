import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Unit } from '../units/entities/unit.entity';
import { Word } from '../words/entities/word.entity';
import { ItemProgress } from '../progress/entities/item-progress.entity';
import { LessonSession } from '../sessions/entities/lesson-session.entity';
import { CourseMastery } from './entities/course-mastery.entity';
import { CheckpointAttempt } from './entities/checkpoint-attempt.entity';
import { MasteryService } from './mastery.service';
import { MasteryController } from './mastery.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CourseMastery,
      CheckpointAttempt,
      Lesson,
      Unit,
      Word,
      ItemProgress,
      LessonSession,
    ]),
  ],
  controllers: [MasteryController],
  providers: [MasteryService],
  exports: [MasteryService],
})
export class MasteryModule {}
