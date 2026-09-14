import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EnergyModule } from '../energy/energy.module';
import { UserGamification } from '../gamification/entities/user-gamification.entity';
import { UserWallet } from './entities/user-wallet.entity';
import { GemTransaction } from './entities/gem-transaction.entity';
import { ShopItem } from './entities/shop-item.entity';
import { LeagueSeason } from './entities/league-season.entity';
import { LeagueMembership } from './entities/league-membership.entity';
import { EconomyService } from './economy.service';
import { EconomyController } from './economy.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserWallet,
      GemTransaction,
      ShopItem,
      LeagueSeason,
      LeagueMembership,
      UserGamification,
    ]),
    EnergyModule,
  ],
  controllers: [EconomyController],
  providers: [EconomyService],
  exports: [EconomyService],
})
export class EconomyModule {}
