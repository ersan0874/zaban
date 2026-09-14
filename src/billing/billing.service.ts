import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThan, Repository } from 'typeorm';
import {
  Purchase,
  PurchasePlatform,
  PurchaseStatus,
} from './entities/purchase.entity';
import {
  EnergySubscription,
  SubscriptionPlan,
} from './entities/energy-subscription.entity';
import { VerifyPurchaseDto } from './dto/verify-purchase.dto';
import { isValidProductId, PRODUCTS } from './products';
import { EnergyService } from '../energy/energy.service';
import { EnergyTxnReason } from '../energy/entities/energy-transaction.entity';

@Injectable()
export class BillingService {
  constructor(
    @InjectRepository(Purchase)
    private readonly purchaseRepository: Repository<Purchase>,
    @InjectRepository(EnergySubscription)
    private readonly subscriptionRepository: Repository<EnergySubscription>,
    private readonly energyService: EnergyService,
  ) {}

  async hasActiveUnlimited(userId: string): Promise<boolean> {
    const now = new Date();
    const sub = await this.subscriptionRepository.findOne({
      where: {
        userId,
        active: true,
        expiresAt: MoreThan(now),
      },
      order: { expiresAt: 'DESC' },
    });
    return !!sub;
  }

  async verifyPurchase(userId: string, dto: VerifyPurchaseDto) {
    if (!dto.receipt || dto.receipt.trim() === '' || dto.receipt === 'INVALID') {
      throw new BadRequestException('Invalid receipt');
    }

    if (!isValidProductId(dto.productId)) {
      throw new BadRequestException('Unknown product');
    }

    const existing = await this.purchaseRepository.findOne({
      where: { receipt: dto.receipt, status: PurchaseStatus.VERIFIED },
    });
    if (existing) {
      throw new BadRequestException('Receipt already used');
    }

    const valid = this.validateReceipt(dto.platform, dto.receipt);
    const purchase = await this.purchaseRepository.save(
      this.purchaseRepository.create({
        userId,
        productId: dto.productId,
        platform: dto.platform,
        receipt: dto.receipt,
        status: valid ? PurchaseStatus.VERIFIED : PurchaseStatus.REJECTED,
      }),
    );

    if (!valid) {
      throw new BadRequestException('Receipt verification failed');
    }

    const product = PRODUCTS[dto.productId];
    if (product.energyGrant) {
      await this.energyService.grant(
        userId,
        product.energyGrant,
        EnergyTxnReason.PURCHASE,
        { productId: dto.productId, purchaseId: purchase.id },
      );
    }

    if (product.unlimitedPlan) {
      await this.activateSubscription(userId, product.unlimitedPlan);
    }

    return {
      purchase: {
        id: purchase.id,
        productId: purchase.productId,
        status: purchase.status,
        createdAt: purchase.createdAt,
      },
      subscription: await this.getActiveSubscription(userId),
    };
  }

  async getBillingMe(userId: string) {
    const [subscription, purchases] = await Promise.all([
      this.getActiveSubscription(userId),
      this.purchaseRepository.find({
        where: { userId },
        order: { createdAt: 'DESC' },
        take: 20,
      }),
    ]);

    return {
      subscription,
      purchases: purchases.map((p) => ({
        id: p.id,
        productId: p.productId,
        platform: p.platform,
        status: p.status,
        createdAt: p.createdAt,
      })),
    };
  }

  async listPurchasesForAdmin() {
    const purchases = await this.purchaseRepository.find({
      order: { createdAt: 'DESC' },
      relations: { user: { profile: true } },
      take: 200,
    });

    return purchases.map((p) => ({
      id: p.id,
      userId: p.userId,
      email: p.user?.email ?? null,
      displayName: p.user?.profile?.displayName ?? null,
      productId: p.productId,
      platform: p.platform,
      status: p.status,
      createdAt: p.createdAt,
    }));
  }

  private validateReceipt(platform: PurchasePlatform, receipt: string): boolean {
    if (platform === PurchasePlatform.WEB_TEST) {
      return receipt.startsWith('TEST.');
    }
    // MVP: accept non-empty receipts for google/apple (real validation in prod)
    return receipt.length > 8;
  }

  private async activateSubscription(
    userId: string,
    plan: 'day' | 'week' | 'month',
  ) {
    await this.subscriptionRepository.update(
      { userId, active: true },
      { active: false },
    );

    const expiresAt = new Date();
    if (plan === 'day') expiresAt.setDate(expiresAt.getDate() + 1);
    else if (plan === 'week') expiresAt.setDate(expiresAt.getDate() + 7);
    else expiresAt.setMonth(expiresAt.getMonth() + 1);

    const planEnum =
      plan === 'day'
        ? SubscriptionPlan.DAY
        : plan === 'week'
          ? SubscriptionPlan.WEEK
          : SubscriptionPlan.MONTH;

    return this.subscriptionRepository.save(
      this.subscriptionRepository.create({
        userId,
        plan: planEnum,
        expiresAt,
        active: true,
      }),
    );
  }

  private async getActiveSubscription(userId: string) {
    const now = new Date();
    const sub = await this.subscriptionRepository.findOne({
      where: {
        userId,
        active: true,
        expiresAt: MoreThan(now),
      },
      order: { expiresAt: 'DESC' },
    });
    if (!sub) return null;
    return {
      plan: sub.plan,
      expiresAt: sub.expiresAt,
      active: true,
    };
  }
}
