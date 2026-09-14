import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { User } from './entities/user.entity';
import { UserProfile } from './entities/user-profile.entity';
import { UserSettings } from './entities/user-settings.entity';
import { UserStats } from './entities/user-stats.entity';
import { UsersService } from './users.service';
import { UserStatsService } from './user-stats.service';
import { UserStatsController } from './user-stats.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, UserProfile, UserSettings, UserStats]),
    forwardRef(() => SubscriptionsModule),
  ],
  controllers: [UserStatsController],
  providers: [UsersService, UserStatsService],
  exports: [UsersService, UserStatsService, TypeOrmModule],
})
export class UsersModule {}
