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

export enum PurchasePlatform {
  GOOGLE = 'google',
  APPLE = 'apple',
  WEB_TEST = 'web_test',
}

export enum PurchaseStatus {
  PENDING = 'pending',
  VERIFIED = 'verified',
  REJECTED = 'rejected',
}

@Entity('purchases')
@Index(['receipt'])
export class Purchase {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 64 })
  productId: string;

  @Column({ type: 'varchar', length: 16 })
  platform: PurchasePlatform;

  @Column({ type: 'text' })
  receipt: string;

  @Column({ type: 'varchar', length: 16, default: PurchaseStatus.PENDING })
  status: PurchaseStatus;

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
