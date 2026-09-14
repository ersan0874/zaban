import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { EnergyService } from '../energy/energy.service';
import { EnergyTxnReason } from '../energy/entities/energy-transaction.entity';
import { UserGamification } from './entities/user-gamification.entity';
import { DailyQuest } from './entities/daily-quest.entity';
import { UserBadge } from './entities/user-badge.entity';
import { LootBox } from './entities/loot-box.entity';
import {
  BADGE_CATALOG,
  CLUB_STREAK_THRESHOLD,
  CLUB_XP_THRESHOLD,
  DAILY_QUEST_TEMPLATES,
  HEARTS_DEFAULT,
  LOOT_EVERY_N_LESSONS,
  XP_PER_CORRECT,
  XP_SESSION_BONUS,
  daysBetweenUtc,
  utcDateString,
} from './gamification.constants';

export type SessionGamificationInput = {
  sessionId: string;
  correctCount: number;
  totalCount: number;
  results: Array<{ isCorrect: boolean; isReview?: boolean }>;
};

@Injectable()
export class GamificationService {
  constructor(
    @InjectRepository(UserGamification)
    private readonly gamiRepository: Repository<UserGamification>,
    @InjectRepository(DailyQuest)
    private readonly questRepository: Repository<DailyQuest>,
    @InjectRepository(UserBadge)
    private readonly badgeRepository: Repository<UserBadge>,
    @InjectRepository(LootBox)
    private readonly lootRepository: Repository<LootBox>,
    private readonly energyService: EnergyService,
    private readonly dataSource: DataSource,
  ) {}

  async getSnapshot(userId: string) {
    const profile = await this.ensureProfile(userId);
    // Passive missed streak before read (without awarding XP)
    let dirty = false;
    if (profile.lastActiveDate) {
      const gap = daysBetweenUtc(profile.lastActiveDate, utcDateString());
      if (gap > 1) {
        if (profile.streakFreezeCount > 0) {
          profile.streakFreezeCount -= 1;
          profile.lastActiveDate = utcDateString(
            new Date(Date.now() - 86_400_000),
          );
        } else {
          profile.streakCount = 0;
        }
        dirty = true;
      }
    }
    if (dirty) await this.gamiRepository.save(profile);
    const quests = await this.ensureDailyQuests(userId);
    const badges = await this.badgeRepository.find({
      where: { userId },
      order: { earnedAt: 'DESC' },
    });
    const loot = await this.lootRepository.find({
      where: { userId, opened: false },
      order: { createdAt: 'DESC' },
    });

    return {
      xp: profile.xp,
      streakCount: profile.streakCount,
      streakFreezeCount: profile.streakFreezeCount,
      lastActiveDate: profile.lastActiveDate,
      hearts: profile.hearts,
      heartsCap: profile.heartsCap,
      lessonsCompleted: profile.lessonsCompleted,
      clubUnlocked: profile.clubUnlocked,
      questPoints: profile.questPoints,
      quests: quests.map((q) => this.toQuestDto(q)),
      badges: badges.map((b) => ({
        badgeKey: b.badgeKey,
        title: b.title,
        pinned: b.pinned,
        earnedAt: b.earnedAt,
      })),
      unopenedLootCount: loot.length,
      lootBoxes: loot.map((l) => ({
        id: l.id,
        opened: l.opened,
        createdAt: l.createdAt,
      })),
    };
  }

  /**
   * Called after a lesson session is graded/submitted.
   */
  async applySessionOutcome(userId: string, input: SessionGamificationInput) {
    const awardedBadges: string[] = [];
    let lootBoxId: string | null = null;
    let xpGained = 0;
    let streakBefore = 0;
    let streakAfter = 0;
    let freezeUsed = false;

    await this.dataSource.transaction(async (manager) => {
      const profile = await this.loadProfileForUpdate(manager, userId);
      streakBefore = profile.streakCount;

      const today = utcDateString();
      freezeUsed = false;

      if (profile.lastActiveDate !== today) {
        if (!profile.lastActiveDate) {
          profile.streakCount = 1;
        } else {
          const gap = daysBetweenUtc(profile.lastActiveDate, today);
          if (gap === 1) {
            profile.streakCount += 1;
          } else if (gap > 1) {
            if (profile.streakFreezeCount > 0) {
              profile.streakFreezeCount -= 1;
              freezeUsed = true;
              profile.streakCount += 1;
            } else {
              profile.streakCount = 1;
            }
          }
        }
        profile.lastActiveDate = today;
      }

      // Hearts: lose on wrong non-review; restore on correct review
      for (const r of input.results) {
        if (!r.isCorrect && !r.isReview) {
          profile.hearts = Math.max(0, profile.hearts - 1);
        } else if (r.isCorrect && r.isReview) {
          profile.hearts = Math.min(profile.heartsCap, profile.hearts + 1);
        }
      }

      xpGained =
        input.correctCount * XP_PER_CORRECT +
        (input.totalCount > 0 ? XP_SESSION_BONUS : 0);
      profile.xp += xpGained;
      profile.lessonsCompleted += 1;

      if (
        !profile.clubUnlocked &&
        (profile.streakCount >= CLUB_STREAK_THRESHOLD ||
          profile.xp >= CLUB_XP_THRESHOLD)
      ) {
        profile.clubUnlocked = true;
      }

      await manager.save(profile);
      streakAfter = profile.streakCount;

      // Quests
      const quests = await this.ensureDailyQuestsInTx(manager, userId);
      for (const q of quests) {
        if (q.completed) continue;
        if (q.questKey === 'complete_lesson') {
          q.progress = Math.min(q.target, q.progress + 1);
        } else if (q.questKey === 'correct_answers') {
          q.progress = Math.min(q.target, q.progress + input.correctCount);
        } else if (q.questKey === 'earn_xp') {
          q.progress = Math.min(q.target, q.progress + xpGained);
        }
        if (q.progress >= q.target && !q.completed) {
          q.completed = true;
          profile.xp += q.rewardXp;
          profile.questPoints += q.rewardQuestPoints;
          xpGained += q.rewardXp;
        }
        await manager.save(q);
      }
      await manager.save(profile);

      // Badges
      const grant = async (key: string) => {
        const meta = BADGE_CATALOG[key];
        if (!meta) return;
        const existing = await manager.findOne(UserBadge, {
          where: { userId, badgeKey: key },
        });
        if (existing) return;
        await manager.save(
          manager.create(UserBadge, {
            userId,
            badgeKey: key,
            title: meta.title,
            pinned: false,
          }),
        );
        awardedBadges.push(key);
      };

      if (profile.lessonsCompleted >= 1) await grant('first_lesson');
      if (profile.streakCount >= 3) await grant('streak_3');
      if (profile.streakCount >= 7) await grant('streak_7');
      if (profile.xp >= 100) await grant('xp_100');
      if (
        input.totalCount > 0 &&
        input.correctCount === input.totalCount
      ) {
        await grant('perfect_session');
      }

      // Loot every N lessons
      if (
        profile.lessonsCompleted > 0 &&
        profile.lessonsCompleted % LOOT_EVERY_N_LESSONS === 0
      ) {
        const box = await manager.save(
          manager.create(LootBox, {
            userId,
            opened: false,
            rewards: this.rollLootRewards(),
            sourceSessionId: input.sessionId,
            openedAt: null,
          }),
        );
        lootBoxId = box.id;
      }
    });

    const snapshot = await this.getSnapshot(userId);
    return {
      xpGained,
      streakBefore,
      streakAfter,
      freezeUsed,
      awardedBadges,
      lootBox: lootBoxId ? { id: lootBoxId, opened: false } : null,
      gamification: snapshot,
    };
  }

  async openLootBox(userId: string, lootId: string) {
    return this.dataSource.transaction(async (manager) => {
      const box = await manager.findOne(LootBox, {
        where: { id: lootId, userId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!box) throw new NotFoundException('Loot box not found');
      if (box.opened) throw new BadRequestException('Loot box already opened');

      const profile = await this.loadProfileForUpdate(manager, userId);
      const rewards = box.rewards ?? {};
      const xp = Number(rewards.xp ?? 0);
      const freeze = Number(rewards.streakFreeze ?? 0);
      const energy = Number(rewards.energy ?? 0);

      if (xp > 0) profile.xp += xp;
      if (freeze > 0) profile.streakFreezeCount += freeze;
      await manager.save(profile);

      box.opened = true;
      box.openedAt = new Date();
      await manager.save(box);

      // Energy grant via energy service outside lock if needed — apply after tx
      return { rewards: { xp, streakFreeze: freeze, energy }, lootId: box.id };
    }).then(async (result) => {
      if ((result.rewards.energy ?? 0) > 0) {
        await this.energyService.grant(
          userId,
          result.rewards.energy,
          EnergyTxnReason.LOOT_BOX,
          { lootId: result.lootId },
        );
      }
      const snapshot = await this.getSnapshot(userId);
      return { ...result, gamification: snapshot };
    });
  }

  async pinBadge(userId: string, badgeKey: string, pinned: boolean) {
    const badge = await this.badgeRepository.findOne({
      where: { userId, badgeKey },
    });
    if (!badge) throw new NotFoundException('Badge not found');

    if (pinned) {
      await this.badgeRepository.update({ userId }, { pinned: false });
    }
    badge.pinned = pinned;
    await this.badgeRepository.save(badge);
    return {
      badgeKey: badge.badgeKey,
      title: badge.title,
      pinned: badge.pinned,
    };
  }

  private rollLootRewards(): Record<string, number> {
    const xp = 20 + Math.floor(Math.random() * 31); // 20-50
    const energy = 1 + Math.floor(Math.random() * 3); // 1-3
    const streakFreeze = Math.random() < 0.35 ? 1 : 0;
    return { xp, energy, streakFreeze };
  }

  private async ensureProfile(userId: string): Promise<UserGamification> {
    let row = await this.gamiRepository.findOne({ where: { userId } });
    if (!row) {
      row = await this.gamiRepository.save(
        this.gamiRepository.create({
          userId,
          xp: 0,
          streakCount: 0,
          lastActiveDate: null,
          streakFreezeCount: 0,
          hearts: HEARTS_DEFAULT,
          heartsCap: HEARTS_DEFAULT,
          lessonsCompleted: 0,
          clubUnlocked: false,
          questPoints: 0,
        }),
      );
    }
    return row;
  }

  private async loadProfileForUpdate(
    manager: EntityManager,
    userId: string,
  ): Promise<UserGamification> {
    let row = await manager.findOne(UserGamification, {
      where: { userId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!row) {
      row = await manager.save(
        manager.create(UserGamification, {
          userId,
          xp: 0,
          streakCount: 0,
          lastActiveDate: null,
          streakFreezeCount: 0,
          hearts: HEARTS_DEFAULT,
          heartsCap: HEARTS_DEFAULT,
          lessonsCompleted: 0,
          clubUnlocked: false,
          questPoints: 0,
        }),
      );
    }
    return row;
  }

  private async ensureDailyQuests(userId: string): Promise<DailyQuest[]> {
    return this.dataSource.transaction((manager) =>
      this.ensureDailyQuestsInTx(manager, userId),
    );
  }

  private async ensureDailyQuestsInTx(
    manager: EntityManager,
    userId: string,
  ): Promise<DailyQuest[]> {
    const today = utcDateString();
    const existing = await manager.find(DailyQuest, {
      where: { userId, questDate: today },
    });
    if (existing.length >= DAILY_QUEST_TEMPLATES.length) {
      return existing;
    }

    const have = new Set(existing.map((q) => q.questKey));
    for (const t of DAILY_QUEST_TEMPLATES) {
      if (have.has(t.questKey)) continue;
      existing.push(
        await manager.save(
          manager.create(DailyQuest, {
            userId,
            questDate: today,
            questKey: t.questKey,
            title: t.title,
            progress: 0,
            target: t.target,
            rewardXp: t.rewardXp,
            rewardQuestPoints: t.rewardQuestPoints,
            completed: false,
          }),
        ),
      );
    }
    return existing;
  }

  private toQuestDto(q: DailyQuest) {
    return {
      id: q.id,
      questKey: q.questKey,
      title: q.title,
      progress: q.progress,
      target: q.target,
      rewardXp: q.rewardXp,
      rewardQuestPoints: q.rewardQuestPoints,
      completed: q.completed,
      questDate: q.questDate,
    };
  }
}
