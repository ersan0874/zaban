import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum EnergyTxnReason {
  REGEN = 'regen',
  LESSON_START = 'lesson_start',
  COMBO_REWARD = 'combo_reward',
  SEED = 'seed',
  LOOT_BOX = 'loot_box',
  PURCHASE = 'purchase',
}

@Entity('energy_transactions')
@Index(['userId', 'createdAt'])
export class EnergyTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'int' })
  delta: number;

  @Column({ type: 'int' })
  balanceAfter: number;

  @Column({ type: 'varchar', length: 64 })
  reason: EnergyTxnReason;

  /** Optional link (sessionId, etc.) for audit / anti-cheat. */
  @Column({ type: 'uuid', nullable: true })
  referenceId: string | null;

  @Column({ type: 'jsonb', default: {} })
  meta: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
