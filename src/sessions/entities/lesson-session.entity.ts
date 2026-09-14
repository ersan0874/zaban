import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Lesson } from '../../lessons/entities/lesson.entity';
import { SessionAttempt } from './session-attempt.entity';

export enum LessonSessionStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  EXPIRED = 'expired',
}

@Entity('lesson_sessions')
export class LessonSession {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  lessonId: string;

  @Column({ type: 'varchar', length: 32, default: LessonSessionStatus.ACTIVE })
  status: LessonSessionStatus;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;

  @Column({ type: 'int', default: 0 })
  correctCount: number;

  @Column({ type: 'int', default: 0 })
  totalCount: number;

  /** Extra review exercise IDs injected into this session (SRS). */
  @Column({ type: 'uuid', array: true, default: [] })
  reviewExerciseIds: string[];

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt: Date | null;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Lesson, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'lessonId' })
  lesson: Lesson;

  @OneToMany(() => SessionAttempt, (attempt) => attempt.session, {
    cascade: true,
  })
  attempts: SessionAttempt[];
}
