import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, In, Repository } from 'typeorm';
import { EnergyService } from '../energy/energy.service';
import { EnergyTxnReason } from '../energy/entities/energy-transaction.entity';
import { UserGamification } from '../gamification/entities/user-gamification.entity';
import { UserWallet } from './entities/user-wallet.entity';
import { GemTransaction, GemTxnReason } from './entities/gem-transaction.entity';
import {
  ShopEffectType,
  ShopItem,
} from './entities/shop-item.entity';
import {
  LeagueSeason,
  LeagueTier,
} from './entities/league-season.entity';
import { LeagueMembership } from './entities/league-membership.entity';

const TIER_LADDER: LeagueTier[] = [
  LeagueTier.BRONZE,
  LeagueTier.SILVER,
  LeagueTier.GOLD,
  LeagueTier.PLATINUM,
  LeagueTier.DIAMOND,
];

const PROMOTION_XP_THRESHOLDS: Record<LeagueTier, number> = {
  [LeagueTier.BRONZE]: 0,
  [LeagueTier.SILVER]: 50,
  [LeagueTier.GOLD]: 100,
  [LeagueTier.PLATINUM]: 200,
  [LeagueTier.DIAMOND]: 400,
};

@Injectable()
export class EconomyService implements OnModuleInit {
  private readonly logger = new Logger(EconomyService.name);

  constructor(
    @InjectRepository(UserWallet)
    private readonly walletRepository: Repository<UserWallet>,
    @InjectRepository(GemTransaction)
    private readonly gemTxnRepository: Repository<GemTransaction>,
    @InjectRepository(ShopItem)
    private readonly shopRepository: Repository<ShopItem>,
    @InjectRepository(LeagueSeason)
    private readonly seasonRepository: Repository<LeagueSeason>,
    @InjectRepository(LeagueMembership)
    private readonly membershipRepository: Repository<LeagueMembership>,
    @InjectRepository(UserGamification)
    private readonly gamiRepository: Repository<UserGamification>,
    private readonly energyService: EnergyService,
    private readonly dataSource: DataSource,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.seedShopItems();
  }

  async getWallet(userId: string) {
    const wallet = await this.ensureWallet(userId);
    return { gems: wallet.gems };
  }

  async ensureWallet(userId: string): Promise<UserWallet> {
    let wallet = await this.walletRepository.findOne({ where: { userId } });
    if (!wallet) {
      wallet = await this.walletRepository.save(
        this.walletRepository.create({ userId, gems: 0 }),
      );
    }
    return wallet;
  }

  async grantGems(
    userId: string,
    amount: number,
    reason: GemTxnReason,
    referenceId: string | null = null,
    meta: Record<string, unknown> = {},
  ): Promise<{ gems: number; granted: number }> {
    if (amount <= 0) {
      const wallet = await this.ensureWallet(userId);
      return { gems: wallet.gems, granted: 0 };
    }

    return this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      wallet.gems += amount;
      await manager.save(wallet);
      await manager.save(
        manager.create(GemTransaction, {
          userId,
          delta: amount,
          balanceAfter: wallet.gems,
          reason,
          referenceId,
          meta,
        }),
      );
      return { gems: wallet.gems, granted: amount };
    });
  }

  async spendGems(
    userId: string,
    amount: number,
    reason: GemTxnReason,
    referenceId: string | null = null,
    meta: Record<string, unknown> = {},
  ): Promise<{ gems: number; spent: number }> {
    if (amount <= 0) {
      const wallet = await this.ensureWallet(userId);
      return { gems: wallet.gems, spent: 0 };
    }

    return this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      if (wallet.gems < amount) {
        throw new ForbiddenException({
          code: 'INSUFFICIENT_GEMS',
          message: 'Not enough gems',
          gems: wallet.gems,
        });
      }
      wallet.gems -= amount;
      await manager.save(wallet);
      await manager.save(
        manager.create(GemTransaction, {
          userId,
          delta: -amount,
          balanceAfter: wallet.gems,
          reason,
          referenceId,
          meta,
        }),
      );
      return { gems: wallet.gems, spent: amount };
    });
  }

  async listShopItems() {
    const items = await this.shopRepository.find({
      where: { active: true },
      order: { priceGems: 'ASC' },
    });
    return items.map((item) => ({
      key: item.key,
      title: item.title,
      description: item.description,
      priceGems: item.priceGems,
      effectType: item.effectType,
      effectPayload: item.effectPayload,
    }));
  }

  async purchaseShopItem(userId: string, itemKey: string) {
    const item = await this.shopRepository.findOne({
      where: { key: itemKey, active: true },
    });
    if (!item) {
      throw new NotFoundException('Shop item not found');
    }

    const spend = await this.spendGems(
      userId,
      item.priceGems,
      GemTxnReason.PURCHASE,
      null,
      { itemKey: item.key },
    );

    const effect = await this.applyShopEffect(userId, item);

    return {
      itemKey: item.key,
      gems: spend.gems,
      spent: spend.spent,
      effect,
    };
  }

  async getCurrentLeague(userId: string) {
    const membership = await this.getOrJoinCurrentWeekLeague(userId);
    const season = await this.seasonRepository.findOne({
      where: { id: membership.seasonId },
    });
    return {
      seasonId: membership.seasonId,
      weekStart: season?.weekStart ?? null,
      tier: membership.tier,
      weeklyXp: membership.weeklyXp,
    };
  }

  async getLeaderboard(userId: string, limit = 50) {
    const membership = await this.getOrJoinCurrentWeekLeague(userId);
    const rows = await this.membershipRepository.find({
      where: { seasonId: membership.seasonId },
      relations: { user: { profile: true } },
      order: { weeklyXp: 'DESC' },
      take: limit,
    });

    return {
      seasonId: membership.seasonId,
      tier: membership.tier,
      entries: rows.map((row, index) => ({
        rank: index + 1,
        userId: row.userId,
        displayName: row.user?.profile?.displayName ?? 'Learner',
        weeklyXp: row.weeklyXp,
        isYou: row.userId === userId,
      })),
    };
  }

  /**
   * Called after gamification on lesson submit.
   */
  async onLessonCompleted(userId: string, xpGained: number, sessionId: string) {
    const gemsEarned = 2 + Math.floor(xpGained / 50);
    const gems = await this.grantGems(
      userId,
      gemsEarned,
      GemTxnReason.LESSON,
      sessionId,
      { xpGained },
    );
    await this.addWeeklyXp(userId, xpGained);
    return { gemsEarned: gems.granted, gems: gems.gems };
  }

  async addWeeklyXp(userId: string, xp: number): Promise<void> {
    if (xp <= 0) return;
    const membership = await this.getOrJoinCurrentWeekLeague(userId);
    await this.membershipRepository.update(membership.id, {
      weeklyXp: membership.weeklyXp + xp,
    });
  }

  private async getOrJoinCurrentWeekLeague(
    userId: string,
  ): Promise<LeagueMembership> {
    const weekStart = mondayUtcString();
    const tier = await this.resolveTierForUser(userId, weekStart);
    const season = await this.ensureSeason(weekStart, tier);

    let membership = await this.membershipRepository.findOne({
      where: { userId, seasonId: season.id },
    });
    if (!membership) {
      membership = await this.membershipRepository.save(
        this.membershipRepository.create({
          userId,
          seasonId: season.id,
          tier,
          weeklyXp: 0,
        }),
      );
    }
    return membership;
  }

  private async resolveTierForUser(
    userId: string,
    currentWeekStart: string,
  ): Promise<LeagueTier> {
    const priorWeekStart = priorMondayUtcString(currentWeekStart);
    const priorSeasons = await this.seasonRepository.find({
      where: { weekStart: priorWeekStart },
    });
    if (priorSeasons.length === 0) {
      return LeagueTier.BRONZE;
    }

    const priorMembership = await this.membershipRepository.findOne({
      where: {
        userId,
        seasonId: In(priorSeasons.map((s) => s.id)),
      },
      order: { weeklyXp: 'DESC' },
    });

    if (!priorMembership) {
      return LeagueTier.BRONZE;
    }

    return promoteTier(priorMembership.tier, priorMembership.weeklyXp);
  }

  private async ensureSeason(
    weekStart: string,
    tier: LeagueTier,
  ): Promise<LeagueSeason> {
    let season = await this.seasonRepository.findOne({
      where: { weekStart, tier },
    });
    if (!season) {
      season = await this.seasonRepository.save(
        this.seasonRepository.create({ weekStart, tier }),
      );
    }
    return season;
  }

  private async applyShopEffect(userId: string, item: ShopItem) {
    switch (item.effectType) {
      case ShopEffectType.STREAK_FREEZE: {
        const amount = Number(item.effectPayload.amount ?? 1);
        let profile = await this.gamiRepository.findOne({ where: { userId } });
        if (!profile) {
          profile = await this.gamiRepository.save(
            this.gamiRepository.create({
              userId,
              streakFreezeCount: amount,
            }),
          );
        } else {
          profile.streakFreezeCount += amount;
          await this.gamiRepository.save(profile);
        }
        return { type: 'streak_freeze', amount };
      }
      case ShopEffectType.ENERGY_PACK: {
        const amount = Number(item.effectPayload.amount ?? 5);
        const energy = await this.energyService.grant(
          userId,
          amount,
          EnergyTxnReason.SEED,
          { shopItemKey: item.key, source: 'shop' },
        );
        return { type: 'energy_pack', amount, energy };
      }
      case ShopEffectType.XP_BOOST:
        return {
          type: 'xp_boost',
          note: 'Placeholder — boost applied on next session (phase 17)',
        };
      default:
        throw new BadRequestException('Unknown shop effect');
    }
  }

  private async seedShopItems(): Promise<void> {
    const count = await this.shopRepository.count();
    if (count > 0) return;

    await this.shopRepository.save([
      this.shopRepository.create({
        key: 'streak_freeze',
        title: 'Streak Freeze',
        description: 'Protect your streak for one missed day',
        priceGems: 50,
        effectType: ShopEffectType.STREAK_FREEZE,
        effectPayload: { amount: 1 },
        active: true,
      }),
      this.shopRepository.create({
        key: 'energy_pack_5',
        title: 'Energy Pack (+5)',
        description: 'Instant energy refill',
        priceGems: 30,
        effectType: ShopEffectType.ENERGY_PACK,
        effectPayload: { amount: 5 },
        active: true,
      }),
      this.shopRepository.create({
        key: 'xp_boost',
        title: 'XP Boost (placeholder)',
        description: 'Double XP on next lesson — coming soon',
        priceGems: 100,
        effectType: ShopEffectType.XP_BOOST,
        effectPayload: { multiplier: 2, durationMinutes: 30 },
        active: true,
      }),
    ]);
    this.logger.log('Seeded default shop items');
  }

  private async loadWalletForUpdate(
    manager: EntityManager,
    userId: string,
  ): Promise<UserWallet> {
    let wallet = await manager.findOne(UserWallet, {
      where: { userId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!wallet) {
      wallet = await manager.save(
        manager.create(UserWallet, { userId, gems: 0 }),
      );
    }
    return wallet;
  }
}

function mondayUtcString(date = new Date()): string {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
  const day = d.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setUTCDate(d.getUTCDate() + diff);
  return d.toISOString().slice(0, 10);
}

function priorMondayUtcString(weekStart: string): string {
  const d = new Date(`${weekStart}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() - 7);
  return d.toISOString().slice(0, 10);
}

function promoteTier(current: LeagueTier, weeklyXp: number): LeagueTier {
  let tier = current;
  for (const candidate of TIER_LADDER) {
    if (weeklyXp >= PROMOTION_XP_THRESHOLDS[candidate]) {
      tier = candidate;
    }
  }
  return tier;
}
