import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('daily_quests')
@Index(['userId', 'questDate', 'questKey'], { unique: true })
export class DailyQuest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  /** UTC date YYYY-MM-DD */
  @Column({ type: 'varchar', length: 10 })
  questDate: string;

  @Column({ type: 'varchar', length: 64 })
  questKey: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'int', default: 0 })
  progress: number;

  @Column({ type: 'int' })
  target: number;

  @Column({ type: 'int', default: 0 })
  rewardXp: number;

  @Column({ type: 'int', default: 0 })
  rewardQuestPoints: number;

  @Column({ type: 'boolean', default: false })
  completed: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
