import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Purchase } from './entities/purchase.entity';
import { EnergySubscription } from './entities/energy-subscription.entity';
import { BillingService } from './billing.service';
import { BillingController } from './billing.controller';
import { EnergyModule } from '../energy/energy.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Purchase, EnergySubscription]),
    EnergyModule,
  ],
  controllers: [BillingController],
  providers: [BillingService],
  exports: [BillingService, TypeOrmModule],
})
export class BillingModule {}
