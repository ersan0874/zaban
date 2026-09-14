import { Module } from '@nestjs/common';
import { QuestionsModule } from '../questions/questions.module';
import { UsersModule } from '../users/users.module';
import { PlacementTestController } from './placement-test.controller';
import { PlacementTestService } from './placement-test.service';

@Module({
  imports: [QuestionsModule, UsersModule],
  controllers: [PlacementTestController],
  providers: [PlacementTestService],
})
export class PlacementTestModule {}
