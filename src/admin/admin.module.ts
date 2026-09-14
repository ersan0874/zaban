import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';
import { UserEnergy } from '../energy/entities/user-energy.entity';
import { EnergyTransaction } from '../energy/entities/energy-transaction.entity';
import { LessonSession } from '../sessions/entities/lesson-session.entity';
import { Course } from '../courses/entities/course.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';
import { AiModule } from '../ai/ai.module';
import { BillingModule } from '../billing/billing.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      UserEnergy,
      EnergyTransaction,
      LessonSession,
      Course,
      Lesson,
      Exercise,
    ]),
    AiModule,
    BillingModule,
  ],
  controllers: [AdminController],
  providers: [AdminService, AdminGuard],
})
export class AdminModule {}
