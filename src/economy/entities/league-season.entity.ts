import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export enum LeagueTier {
  BRONZE = 'bronze',
  SILVER = 'silver',
  GOLD = 'gold',
  PLATINUM = 'platinum',
  DIAMOND = 'diamond',
}

@Entity('league_seasons')
@Index(['weekStart', 'tier'], { unique: true })
export class LeagueSeason {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Monday of the league week (UTC), YYYY-MM-DD. */
  @Column({ type: 'varchar', length: 10 })
  weekStart: string;

  @Column({ type: 'varchar', length: 32 })
  tier: LeagueTier;

  @CreateDateColumn()
  createdAt: Date;
}
