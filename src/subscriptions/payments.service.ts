import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { randomBytes } from 'crypto';
import { Repository } from 'typeorm';
import {
  PaymentStatus,
  PaymentTransaction,
} from './entities/payment-transaction.entity';
import { PlanType } from './entities/subscription.entity';
import {
  PLAN_PRICES_TOMAN,
  SubscriptionsService,
} from './subscriptions.service';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(PaymentTransaction)
    private readonly paymentRepository: Repository<PaymentTransaction>,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly configService: ConfigService,
  ) {}

  async requestPayment(userId: string, planType: PlanType) {
    const amount = PLAN_PRICES_TOMAN[planType];
    const authority = randomBytes(16).toString('hex');

    const transaction = await this.paymentRepository.save(
      this.paymentRepository.create({
        userId,
        planType,
        amount,
        authority,
        status: PaymentStatus.PENDING,
      }),
    );

    const appUrl = this.configService.get<string>(
      'APP_URL',
      'http://localhost:3000',
    );

    // Mock gateway: opening this URL completes payment immediately
    const verifyPath = `/api/payments/verify?authority=${authority}&Status=OK`;
    const paymentUrl = `${appUrl}${verifyPath}`;

    return {
      authority: transaction.authority,
      amount: transaction.amount,
      planType: transaction.planType,
      paymentUrl,
      verifyPath,
      message: 'Mock payment link created. Open paymentUrl to complete.',
    };
  }

  async verifyPayment(authority: string, status?: string) {
    if (!authority) {
      throw new BadRequestException('authority is required');
    }

    const transaction = await this.paymentRepository.findOne({
      where: { authority },
    });

    if (!transaction) {
      throw new NotFoundException('Payment transaction not found');
    }

    if (transaction.status === PaymentStatus.PAID) {
      const subscription =
        await this.subscriptionsService.getActiveSubscription(
          transaction.userId,
        );
      return {
        success: true,
        alreadyVerified: true,
        subscription,
        message: 'Payment was already verified',
      };
    }

    const isOk = !status || status.toUpperCase() === 'OK';

    if (!isOk) {
      transaction.status = PaymentStatus.FAILED;
      await this.paymentRepository.save(transaction);
      return {
        success: false,
        message: 'Payment canceled or failed',
      };
    }

    transaction.status = PaymentStatus.PAID;
    await this.paymentRepository.save(transaction);

    const subscription = await this.subscriptionsService.activatePlan(
      transaction.userId,
      transaction.planType,
    );

    return {
      success: true,
      alreadyVerified: false,
      subscription,
      amount: transaction.amount,
      planType: transaction.planType,
      message: 'Subscription activated successfully',
    };
  }
}
