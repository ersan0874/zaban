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

export enum GemTxnReason {
  LESSON = 'lesson',
  QUEST = 'quest',
  PURCHASE = 'purchase',
  IAP = 'iap',
  ADMIN = 'admin',
}

@Entity('gem_transactions')
@Index(['userId', 'createdAt'])
export class GemTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'int' })
  delta: number;

  @Column({ type: 'int' })
  balanceAfter: number;

  @Column({ type: 'varchar', length: 32 })
  reason: GemTxnReason;

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
