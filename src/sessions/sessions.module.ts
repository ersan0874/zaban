import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LessonSession } from './entities/lesson-session.entity';
import { SessionAttempt } from './entities/session-attempt.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { ProgressModule } from '../progress/progress.module';
import { EnergyModule } from '../energy/energy.module';
import { GamificationModule } from '../gamification/gamification.module';
import { EconomyModule } from '../economy/economy.module';
import { MasteryModule } from '../mastery/mastery.module';
import { SocialModule } from '../social/social.module';
import { ReengagementModule } from '../reengagement/reengagement.module';
import { SessionsService } from './sessions.service';
import { SessionsController } from './sessions.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      LessonSession,
      SessionAttempt,
      Lesson,
      Exercise,
    ]),
    ProgressModule,
    EnergyModule,
    GamificationModule,
    EconomyModule,
    MasteryModule,
    SocialModule,
    ReengagementModule,
  ],
  controllers: [SessionsController],
  providers: [SessionsService],
  exports: [SessionsService, TypeOrmModule],
})
export class SessionsModule {}
