import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Course } from './entities/course.entity';
import { CoursesService } from './courses.service';
import { CoursesController } from './courses.controller';
import { Section } from '../sections/entities/section.entity';
import { Unit } from '../units/entities/unit.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Word } from '../words/entities/word.entity';
import { MasteryModule } from '../mastery/mastery.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Course,
      Section,
      Unit,
      Lesson,
      Exercise,
      Word,
    ]),
    MasteryModule,
  ],
  controllers: [CoursesController],
  providers: [CoursesService],
  exports: [CoursesService, TypeOrmModule],
})
export class CoursesModule {}
