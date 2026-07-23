import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThan, Repository } from 'typeorm';
import {
  PlanType,
  Subscription,
  SubscriptionStatus,
} from './entities/subscription.entity';

export const PLAN_DURATIONS_DAYS: Record<PlanType, number> = {
  [PlanType.MONTHLY]: 30,
  [PlanType.THREE_MONTHS]: 90,
  [PlanType.YEARLY]: 365,
};

export const PLAN_PRICES_TOMAN: Record<PlanType, number> = {
  [PlanType.MONTHLY]: 149_000,
  [PlanType.THREE_MONTHS]: 349_000,
  [PlanType.YEARLY]: 990_000,
};

@Injectable()
export class SubscriptionsService {
  constructor(
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
  ) {}

  async getActiveSubscription(userId: string): Promise<Subscription | null> {
    return this.subscriptionRepository.findOne({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        endDate: MoreThan(new Date()),
      },
      order: { endDate: 'DESC' },
    });
  }

  async hasActiveSubscription(userId: string): Promise<boolean> {
    const active = await this.getActiveSubscription(userId);
    return active !== null;
  }

  async getStatus(userId: string) {
    const subscription = await this.getActiveSubscription(userId);

    return {
      isActive: subscription !== null,
      subscription,
      infiniteHearts: subscription !== null,
    };
  }

  async activatePlan(
    userId: string,
    planType: PlanType,
  ): Promise<Subscription> {
    const now = new Date();
    const existing = await this.getActiveSubscription(userId);

    // Stack from current endDate if already Super
    const startBase = existing && existing.endDate > now ? existing.endDate : now;

    if (existing) {
      existing.status = SubscriptionStatus.EXPIRED;
      await this.subscriptionRepository.save(existing);
    }

    const days = PLAN_DURATIONS_DAYS[planType];
    const endDate = new Date(startBase);
    endDate.setDate(endDate.getDate() + days);

    const subscription = this.subscriptionRepository.create({
      userId,
      planType,
      status: SubscriptionStatus.ACTIVE,
      startDate: now,
      endDate,
    });

    return this.subscriptionRepository.save(subscription);
  }
}
