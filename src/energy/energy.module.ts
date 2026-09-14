import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEnergy } from './entities/user-energy.entity';
import { EnergyTransaction } from './entities/energy-transaction.entity';
import { EnergySubscription } from '../billing/entities/energy-subscription.entity';
import { EnergyConfig } from './energy.config';
import { EnergyService } from './energy.service';
import { EnergyController } from './energy.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserEnergy,
      EnergyTransaction,
      EnergySubscription,
    ]),
  ],
  controllers: [EnergyController],
  providers: [EnergyConfig, EnergyService],
  exports: [EnergyService],
})
export class EnergyModule {}
