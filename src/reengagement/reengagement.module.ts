import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Lesson } from '../lessons/entities/lesson.entity';
import { UserReentry } from './entities/user-reentry.entity';
import { ReengagementService } from './reengagement.service';
import { ReengagementController } from './reengagement.controller';

@Module({
  imports: [TypeOrmModule.forFeature([UserReentry, Lesson])],
  controllers: [ReengagementController],
  providers: [ReengagementService],
  exports: [ReengagementService],
})
export class ReengagementModule {}
