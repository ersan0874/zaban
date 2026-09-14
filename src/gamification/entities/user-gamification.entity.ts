import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('user_gamification')
export class UserGamification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', unique: true })
  userId: string;

  @Column({ type: 'int', default: 0 })
  xp: number;

  @Column({ type: 'int', default: 0 })
  streakCount: number;

  /** Calendar date YYYY-MM-DD (UTC) of last qualifying activity. */
  @Column({ type: 'varchar', length: 10, nullable: true })
  lastActiveDate: string | null;

  /** Inventory: consume on missed day or via shop (phase 9). */
  @Column({ type: 'int', default: 0 })
  streakFreezeCount: number;

  @Column({ type: 'int', default: 5 })
  hearts: number;

  @Column({ type: 'int', default: 5 })
  heartsCap: number;

  @Column({ type: 'int', default: 0 })
  lessonsCompleted: number;

  @Column({ type: 'boolean', default: false })
  clubUnlocked: boolean;

  @Column({ type: 'int', default: 0 })
  questPoints: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
