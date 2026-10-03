import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { CoursesModule } from '../courses/courses.module';
import { SessionsModule } from '../sessions/sessions.module';
import { EnergyModule } from '../energy/energy.module';
import { EconomyModule } from '../economy/economy.module';
import { GamificationModule } from '../gamification/gamification.module';
import { PathMilestone } from './entities/path-milestone.entity';
import { PathService } from './path.service';
import { PathController } from './path.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Lesson, Exercise, PathMilestone]),
    CoursesModule,
    SessionsModule,
    EnergyModule,
    EconomyModule,
    GamificationModule,
  ],
  controllers: [PathController],
  providers: [PathService],
})
export class PathModule {}
