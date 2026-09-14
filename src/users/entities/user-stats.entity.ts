import {
  Column,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from './user.entity';

export const MAX_HEARTS = 5;
export const DEFAULT_GEMS = 100;
export const UNIT_COMPLETION_GEMS = 20;
export const HEART_REFILL_COST = 50;

@Entity('user_stats')
export class UserStats {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', unique: true })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'int', default: MAX_HEARTS })
  hearts: number;

  @Column({ type: 'int', default: DEFAULT_GEMS })
  gems: number;

  @Column({ type: 'int', default: 0 })
  streak: number;

  @Column({ type: 'date', nullable: true, default: null })
  lastActivityDate: Date | null;
}
