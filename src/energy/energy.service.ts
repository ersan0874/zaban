import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, MoreThan, Repository } from 'typeorm';
import { UserEnergy } from './entities/user-energy.entity';
import {
  EnergyTransaction,
  EnergyTxnReason,
} from './entities/energy-transaction.entity';
import { EnergyConfig } from './energy.config';
import { EnergySubscription } from '../billing/entities/energy-subscription.entity';

export type EnergySnapshot = {
  balance: number;
  cap: number;
  regenIntervalMinutes: number;
  nextRegenAt: string | null;
  millisUntilNextRegen: number | null;
  lessonCost: number;
};

export type ComboRewardEvent = {
  atAnswerIndex: number;
  streak: number;
  energyAwarded: number;
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
      wallet.balance = Math.min(
        this.energyConfig.cap,
        wallet.balance + amount,
      );
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
   * Burn energy to start a lesson session. Throws if insufficient after regen.
   */
  async burnForLessonStart(
    userId: string,
    sessionId: string,
  ): Promise<EnergySnapshot> {
    const unlimited = await this.subscriptionRepository.findOne({
      where: {
        userId,
        active: true,
        expiresAt: MoreThan(new Date()),
      },
    });
    if (unlimited) {
      return this.getSnapshot(userId);
    }

    const cost = this.energyConfig.lessonCost;
    return this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      this.applyRegenInMemory(wallet);

      if (wallet.balance < cost) {
        throw new ForbiddenException({
          code: 'INSUFFICIENT_ENERGY',
          message: 'Not enough energy to start this lesson',
          energy: this.toSnapshot(wallet),
        });
      }

      wallet.balance -= cost;
      await manager.save(wallet);
      await manager.save(
        manager.create(EnergyTransaction, {
          userId,
          delta: -cost,
          balanceAfter: wallet.balance,
          reason: EnergyTxnReason.LESSON_START,
          referenceId: sessionId,
          meta: { cost },
        }),
      );

      return this.toSnapshot(wallet);
    });
  }

  /**
   * Scan graded results in order; every N correct streak → server roll 1–7.
   */
  async applyComboRewards(
    userId: string,
    sessionId: string,
    results: Array<{ isCorrect: boolean }>,
  ): Promise<{ energy: EnergySnapshot; comboRewards: ComboRewardEvent[] }> {
    const comboLength = this.energyConfig.comboLength;
    const rewards: ComboRewardEvent[] = [];
    let streak = 0;

    for (let i = 0; i < results.length; i++) {
      if (results[i].isCorrect) {
        streak += 1;
        if (streak % comboLength === 0) {
          rewards.push({
            atAnswerIndex: i,
            streak,
            energyAwarded: this.rollComboReward(),
          });
        }
      } else {
        streak = 0;
      }
    }

    if (rewards.length === 0) {
      return { energy: await this.getSnapshot(userId), comboRewards: [] };
    }

    const totalGain = rewards.reduce((s, r) => s + r.energyAwarded, 0);

    const energy = await this.dataSource.transaction(async (manager) => {
      const wallet = await this.loadWalletForUpdate(manager, userId);
      this.applyRegenInMemory(wallet);

      const before = wallet.balance;
      wallet.balance = Math.min(
        this.energyConfig.cap,
        wallet.balance + totalGain,
      );
      const applied = wallet.balance - before;
      await manager.save(wallet);

      await manager.save(
        manager.create(EnergyTransaction, {
          userId,
          delta: applied,
          balanceAfter: wallet.balance,
          reason: EnergyTxnReason.COMBO_REWARD,
          referenceId: sessionId,
          meta: { requested: totalGain, applied, rewards },
        }),
      );

      return this.toSnapshot(wallet);
    });

    return { energy, comboRewards: rewards };
  }

  private rollComboReward(): number {
    const min = this.energyConfig.comboRewardMin;
    const max = this.energyConfig.comboRewardMax;
    return min + Math.floor(Math.random() * (max - min + 1));
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
        lessonCost: this.energyConfig.lessonCost,
      };
    }

    const nextAt = wallet.lastRegenAt.getTime() + interval;
    return {
      balance: wallet.balance,
      cap,
      regenIntervalMinutes: intervalMinutes,
      nextRegenAt: new Date(nextAt).toISOString(),
      millisUntilNextRegen: Math.max(0, nextAt - Date.now()),
      lessonCost: this.energyConfig.lessonCost,
    };
  }
}
