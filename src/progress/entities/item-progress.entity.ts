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

export enum ProgressItemKind {
  WORD = 'word',
  EXERCISE = 'exercise',
}

/**
 * Per-user skill + SRS schedule for a learnable item (word or exercise).
 */
@Entity('item_progress')
@Index(['userId', 'itemKind', 'itemId'], { unique: true })
@Index(['userId', 'nextReviewAt'])
export class ItemProgress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 32 })
  itemKind: ProgressItemKind;

  @Column({ type: 'uuid' })
  itemId: string;

  /** Optional denormalized label for UI (e.g. English word). */
  @Column({ type: 'varchar', length: 255, nullable: true })
  label: string | null;

  /** 0–100 mastery-style skill. */
  @Column({ type: 'int', default: 0 })
  skillScore: number;

  /** Successful review streak used by interval ladder. */
  @Column({ type: 'int', default: 0 })
  repetitions: number;

  @Column({ type: 'float', default: 2.5 })
  easeFactor: number;

  @Column({ type: 'int', default: 10 })
  intervalMinutes: number;

  @Column({ type: 'timestamptz' })
  nextReviewAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  lastReviewedAt: Date | null;

  @Column({ type: 'boolean', nullable: true })
  lastWasCorrect: boolean | null;

  @Column({ type: 'int', default: 0 })
  totalCorrect: number;

  @Column({ type: 'int', default: 0 })
  totalIncorrect: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
