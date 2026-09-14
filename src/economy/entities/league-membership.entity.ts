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
import { LeagueSeason } from './league-season.entity';
import { LeagueTier } from './league-season.entity';

@Entity('league_memberships')
@Index(['userId', 'seasonId'], { unique: true })
@Index(['seasonId', 'weeklyXp'])
export class LeagueMembership {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  seasonId: string;

  @Column({ type: 'varchar', length: 32 })
  tier: LeagueTier;

  @Column({ type: 'int', default: 0 })
  weeklyXp: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => LeagueSeason, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'seasonId' })
  season: LeagueSeason;
}
