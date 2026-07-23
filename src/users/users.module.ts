import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { User } from './entities/user.entity';
import { UserStats } from './entities/user-stats.entity';
import { UsersService } from './users.service';
import { UserStatsService } from './user-stats.service';
import { UserStatsController } from './user-stats.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, UserStats]),
    forwardRef(() => SubscriptionsModule),
  ],
  controllers: [UserStatsController],
  providers: [UsersService, UserStatsService],
  exports: [UsersService, UserStatsService, TypeOrmModule],
})
export class UsersModule {}
