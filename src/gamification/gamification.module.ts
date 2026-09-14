import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EnergyModule } from '../energy/energy.module';
import { UserGamification } from './entities/user-gamification.entity';
import { DailyQuest } from './entities/daily-quest.entity';
import { UserBadge } from './entities/user-badge.entity';
import { LootBox } from './entities/loot-box.entity';
import { GamificationService } from './gamification.service';
import { GamificationController } from './gamification.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserGamification,
      DailyQuest,
      UserBadge,
      LootBox,
    ]),
    EnergyModule,
  ],
  controllers: [GamificationController],
  providers: [GamificationService],
  exports: [GamificationService],
})
export class GamificationModule {}
