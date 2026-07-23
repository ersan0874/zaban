import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import {
  DEFAULT_GEMS,
  HEART_REFILL_COST,
  MAX_HEARTS,
  UNIT_COMPLETION_GEMS,
  UserStats,
} from './entities/user-stats.entity';

@Injectable()
export class UserStatsService {
  constructor(
    @InjectRepository(UserStats)
    private readonly statsRepository: Repository<UserStats>,
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  async createForUser(userId: string): Promise<UserStats> {
    const existing = await this.statsRepository.findOne({ where: { userId } });
    if (existing) {
      return existing;
    }

    const stats = this.statsRepository.create({
      userId,
      hearts: MAX_HEARTS,
      gems: DEFAULT_GEMS,
      streak: 0,
      lastActivityDate: null,
    });

    return this.statsRepository.save(stats);
  }

  async ensureForUser(userId: string): Promise<UserStats> {
    const existing = await this.statsRepository.findOne({ where: { userId } });
    if (existing) {
      return existing;
    }
    return this.createForUser(userId);
  }

  async getForUser(userId: string) {
    const stats = await this.ensureForUser(userId);
    const hasActiveSubscription =
      await this.subscriptionsService.hasActiveSubscription(userId);

    return {
      ...stats,
      hasActiveSubscription,
      infiniteHearts: hasActiveSubscription,
    };
  }

  async decreaseHeart(userId: string) {
    const stats = await this.ensureForUser(userId);
    const hasActiveSubscription =
      await this.subscriptionsService.hasActiveSubscription(userId);

    // Super subscribers have infinite hearts — no deduction
    if (hasActiveSubscription) {
      return {
        ...stats,
        hasActiveSubscription: true,
        infiniteHearts: true,
        heartDeducted: false,
      };
    }

    if (stats.hearts <= 0) {
      throw new BadRequestException(
        'No hearts remaining. Refill hearts to continue.',
      );
    }

    stats.hearts -= 1;
    const saved = await this.statsRepository.save(stats);

    return {
      ...saved,
      hasActiveSubscription: false,
      infiniteHearts: false,
      heartDeducted: true,
    };
  }

  async completeUnit(userId: string) {
    const stats = await this.ensureForUser(userId);
    const today = this.toDateOnly(new Date());
    const last = stats.lastActivityDate
      ? this.toDateOnly(new Date(stats.lastActivityDate))
      : null;

    stats.gems += UNIT_COMPLETION_GEMS;

    if (!last) {
      stats.streak = 1;
      stats.lastActivityDate = today;
    } else {
      const dayDiff = this.daysBetween(last, today);

      if (dayDiff === 0) {
        // Same day — streak unchanged
      } else if (dayDiff === 1) {
        stats.streak += 1;
        stats.lastActivityDate = today;
      } else {
        stats.streak = 1;
        stats.lastActivityDate = today;
      }
    }

    const saved = await this.statsRepository.save(stats);
    const hasActiveSubscription =
      await this.subscriptionsService.hasActiveSubscription(userId);

    return {
      ...saved,
      hasActiveSubscription,
      infiniteHearts: hasActiveSubscription,
    };
  }

  async refillHearts(userId: string) {
    const stats = await this.ensureForUser(userId);
    const hasActiveSubscription =
      await this.subscriptionsService.hasActiveSubscription(userId);

    if (hasActiveSubscription) {
      throw new BadRequestException(
        'Super subscribers already have infinite hearts',
      );
    }

    if (stats.hearts >= MAX_HEARTS) {
      throw new BadRequestException('Hearts are already full');
    }

    if (stats.gems < HEART_REFILL_COST) {
      throw new BadRequestException(
        `Not enough gems. Need ${HEART_REFILL_COST}, have ${stats.gems}`,
      );
    }

    stats.gems -= HEART_REFILL_COST;
    stats.hearts = MAX_HEARTS;
    const saved = await this.statsRepository.save(stats);

    return {
      ...saved,
      hasActiveSubscription: false,
      infiniteHearts: false,
    };
  }

  private toDateOnly(date: Date): Date {
    return new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    );
  }

  private daysBetween(from: Date, to: Date): number {
    const msPerDay = 24 * 60 * 60 * 1000;
    return Math.round((to.getTime() - from.getTime()) / msPerDay);
  }
}
