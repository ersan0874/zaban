import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum ShopEffectType {
  STREAK_FREEZE = 'streak_freeze',
  ENERGY_PACK = 'energy_pack',
  XP_BOOST = 'xp_boost',
}

@Entity('shop_items')
export class ShopItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 64, unique: true })
  key: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'int' })
  priceGems: number;

  @Column({ type: 'varchar', length: 32 })
  effectType: ShopEffectType;

  @Column({ type: 'jsonb', default: {} })
  effectPayload: Record<string, unknown>;

  @Column({ type: 'boolean', default: true })
  active: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
