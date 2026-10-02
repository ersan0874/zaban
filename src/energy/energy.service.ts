import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, MoreThan, Repository } from 'typeorm';
import { UserEnergy } from './entities/user-energy.entity';
import {
  EnergyTransaction,
  EnergyTxnReason,
} from './entities/energy-transaction.entity';
import { EnergyConfig } from './energy.config';
import { ComboRules, comboTier, rollComboReward } from './combo';
import { EnergySubscription } from '../billing/entities/energy-subscription.entity';

export type EnergySnapshot = {
  balance: number;
  cap: number;
  regenIntervalMinutes: number;
  nextRegenAt: string | null;
  millisUntilNextRegen: number | null;
  /** Energy per page passed. `lessonCost` is kept as an alias for old clients. */
  stepCost: number;
  lessonCost: number;
  comboStreak: number;
};

export type ComboRewardEvent = {
  /** Streak that triggered the combo (5, 10, 15, ...). */
  streak: number;
  tier: number;
  /** Energy actually added (after the cap). */
  energyAwarded: number;
  rolled: number;
};

export type ComboState = {
  streak: number;
  /** Pages per combo tier (default 5). */
  length: number;
  reward: ComboRewardEvent | null;
};

@Injectable()
export class EnergyService {
  constructor(
    @InjectRepository(UserEnergy)
    private readonly energyRepository: Repository<UserEnergy>,
    @InjectRepository(EnergyTransaction)
    private readonly txnRepository: Repository<EnergyTransaction>,
    @InjectRepository(EnergySubscription)
    private readonly subscriptionRepository: Repository<EnergySubscription>,
    private readonly energyConfig: EnergyConfig,
    private readonly dataSource: DataSource,
  ) {}

  async getSnapshot(userId: string): Promise<EnergySnapshot> {
    const wallet = await this.applyRegen(userId);
    return this.toSnapshot(wallet);
  }

  /** Server-side grant (loot / admin). Caps at ENERGY_CAP. */
  async grant(
    userId: string,
    amount: number,
    reason: EnergyTxnReason = EnergyTxnReason.SEED,
    meta: Record<string, unknown> = {},
  ): Promise<EnergySnapshot> {
    if (amount <= 0) return this.getSnapshot(userId);
    return this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      this.applyRegenInMemory(wallet);
      const before = wallet.balance;
      wallet.balance = Math.min(this.energyConfig.cap, wallet.balance + amount);
      const applied = wallet.balance - before;
      await manager.save(wallet);
      if (applied > 0) {
        await manager.save(
          manager.create(EnergyTransaction, {
            userId,
            delta: applied,
            balanceAfter: wallet.balance,
            reason,
            referenceId: null,
            meta,
          }),
        );
      }
      return this.toSnapshot(wallet);
    });
  }

  /**
   * A lesson can start only if the first page is affordable. Nothing is
   * burned here; every page passed burns energy through [applyStep].
   */
  async assertCanStart(userId: string): Promise<EnergySnapshot> {
    const wallet = await this.applyRegen(userId);
    if (
      !(await this.hasUnlimited(userId)) &&
      wallet.balance < this.energyConfig.stepCost
    ) {
      throw this.insufficient(wallet);
    }
    return this.toSnapshot(wallet);
  }

  /**
   * One page passed (a graded question or a lesson-note page). Burns the
   * step cost, then advances or resets the user's combo streak. Every
   * `comboLength` passed pages in a row restore a server-rolled amount of
   * energy that grows with each tier (see combo.ts).
   */
  async applyStep(
    userId: string,
    sessionId: string,
    passed: boolean,
  ): Promise<{ energy: EnergySnapshot; combo: ComboState }> {
    const unlimited = await this.hasUnlimited(userId);
    const cost = this.energyConfig.stepCost;
    return this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      this.applyRegenInMemory(wallet);

      if (!unlimited) {
        if (wallet.balance < cost) {
          throw this.insufficient(wallet);
        }
        wallet.balance -= cost;
        await manager.save(
          manager.create(EnergyTransaction, {
            userId,
            delta: -cost,
            balanceAfter: wallet.balance,
            reason: EnergyTxnReason.STEP,
            referenceId: sessionId,
            meta: { cost, passed },
          }),
        );
      }

      wallet.comboStreak = passed ? wallet.comboStreak + 1 : 0;
      const tier = comboTier(wallet.comboStreak, this.energyConfig.comboLength);
      let reward: ComboRewardEvent | null = null;

      if (tier > 0) {
        const rolled = rollComboReward(tier, this.comboRules());
        const before = wallet.balance;
        wallet.balance = Math.min(
          this.energyConfig.cap,
          wallet.balance + rolled,
        );
        const applied = wallet.balance - before;
        reward = {
          streak: wallet.comboStreak,
          tier,
          energyAwarded: applied,
          rolled,
        };
        if (applied > 0) {
          await manager.save(
            manager.create(EnergyTransaction, {
              userId,
              delta: applied,
              balanceAfter: wallet.balance,
              reason: EnergyTxnReason.COMBO_REWARD,
              referenceId: sessionId,
              meta: { ...reward },
            }),
          );
        }
      }

      await manager.save(wallet);
      return {
        energy: this.toSnapshot(wallet),
        combo: {
          streak: wallet.comboStreak,
          length: this.energyConfig.comboLength,
          reward,
        },
      };
    });
  }

  private comboRules(): ComboRules {
    return {
      length: this.energyConfig.comboLength,
      minBase: this.energyConfig.comboRewardMin,
      maxBase: this.energyConfig.comboRewardMax,
      minStep: this.energyConfig.comboRewardMinStep,
      maxStep: this.energyConfig.comboRewardMaxStep,
    };
  }

  private async hasUnlimited(userId: string): Promise<boolean> {
    const sub = await this.subscriptionRepository.findOne({
      where: { userId, active: true, expiresAt: MoreThan(new Date()) },
    });
    return !!sub;
  }

  private insufficient(wallet: UserEnergy): ForbiddenException {
    return new ForbiddenException({
      code: 'INSUFFICIENT_ENERGY',
      message: 'Not enough energy',
      energy: this.toSnapshot(wallet),
    });
  }

  private async applyRegen(userId: string): Promise<UserEnergy> {
    return this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      const gained = this.applyRegenInMemory(wallet);
      if (gained > 0) {
        await manager.save(wallet);
        await manager.save(
          manager.create(EnergyTransaction, {
            userId,
            delta: gained,
            balanceAfter: wallet.balance,
            reason: EnergyTxnReason.REGEN,
            referenceId: null,
            meta: { intervalMs: this.energyConfig.regenIntervalMs },
          }),
        );
      } else {
        await manager.save(wallet);
      }
      return wallet;
    });
  }

  private async loadWalletForUpdate(
    manager: EntityManager,
    userId: string,
  ): Promise<UserEnergy> {
    let wallet = await manager.findOne(UserEnergy, {
      where: { userId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!wallet) {
      wallet = await this.createWallet(manager, userId);
    }
    return wallet;
  }

  /** Mutates wallet; returns energy gained. */
  private applyRegenInMemory(wallet: UserEnergy): number {
    const cap = this.energyConfig.cap;
    const interval = this.energyConfig.regenIntervalMs;
    if (wallet.balance >= cap) {
      wallet.lastRegenAt = new Date();
      return 0;
    }

    const now = Date.now();
    const elapsed = now - wallet.lastRegenAt.getTime();
    if (elapsed < interval) return 0;

    const ticks = Math.floor(elapsed / interval);
    const room = cap - wallet.balance;
    const gained = Math.min(ticks, room);
    if (gained <= 0) return 0;

    wallet.balance += gained;
    wallet.lastRegenAt = new Date(
      wallet.lastRegenAt.getTime() + ticks * interval,
    );
    if (wallet.balance >= cap) {
      wallet.lastRegenAt = new Date();
    }
    return gained;
  }

  private async createWallet(
    manager: EntityManager,
    userId: string,
  ): Promise<UserEnergy> {
    const cap = this.energyConfig.cap;
    const wallet = manager.create(UserEnergy, {
      userId,
      balance: cap,
      lastRegenAt: new Date(),
    });
    const saved = await manager.save(wallet);
    await manager.save(
      manager.create(EnergyTransaction, {
        userId,
        delta: cap,
        balanceAfter: cap,
        reason: EnergyTxnReason.SEED,
        referenceId: null,
        meta: { note: 'initial wallet' },
      }),
    );
    return saved;
  }

  private toSnapshot(wallet: UserEnergy): EnergySnapshot {
    const cap = this.energyConfig.cap;
    const interval = this.energyConfig.regenIntervalMs;
    const intervalMinutes = Math.round(interval / 60_000);

    if (wallet.balance >= cap) {
      return {
        balance: wallet.balance,
        cap,
        regenIntervalMinutes: intervalMinutes,
        nextRegenAt: null,
        millisUntilNextRegen: null,
        stepCost: this.energyConfig.stepCost,
        lessonCost: this.energyConfig.stepCost,
        comboStreak: wallet.comboStreak ?? 0,
      };
    }

    const nextAt = wallet.lastRegenAt.getTime() + interval;
    return {
      balance: wallet.balance,
      cap,
      regenIntervalMinutes: intervalMinutes,
      nextRegenAt: new Date(nextAt).toISOString(),
      millisUntilNextRegen: Math.max(0, nextAt - Date.now()),
      stepCost: this.energyConfig.stepCost,
      lessonCost: this.energyConfig.stepCost,
      comboStreak: wallet.comboStreak ?? 0,
    };
  }
}
