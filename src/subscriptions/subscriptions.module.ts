import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentTransaction } from './entities/payment-transaction.entity';
import { Subscription } from './entities/subscription.entity';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';

@Module({
  imports: [TypeOrmModule.forFeature([Subscription, PaymentTransaction])],
  controllers: [SubscriptionsController, PaymentsController],
  providers: [SubscriptionsService, PaymentsService],
  exports: [SubscriptionsService, TypeOrmModule],
})
export class SubscriptionsModule {}
