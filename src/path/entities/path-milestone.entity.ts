import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum PathMilestoneKind {
  EXAM = 'exam',
  CHEST = 'chest',
}

/** A learner's passed review exam or opened chest on a course path. */
@Entity('path_milestones')
@Unique(['userId', 'courseId', 'kind', 'position'])
export class PathMilestone {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  courseId: string;

  @Column({ type: 'varchar', length: 16 })
  kind: PathMilestoneKind;

  /** Lesson number on the path the exam/chest follows. */
  @Column({ type: 'int' })
  position: number;

  /** Exams: best score so far. */
  @Column({ type: 'int', nullable: true })
  scorePercent: number | null;

  /** Exams: passed once; chests: opened. */
  @Column({ type: 'boolean', default: false })
  done: boolean;

  @Column({ type: 'jsonb', default: {} })
  rewards: Record<string, number>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
