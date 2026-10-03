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

export type SessionStepRecord = {
  isCorrect: boolean;
  score: number;
  feedback: string | null;
  gradingStatus: 'graded' | 'pending' | 'ungraded';
};

export enum LessonSessionKind {
  LESSON = 'lesson',
  /** Review exam on the path: only `reviewExerciseIds`, no notes. */
  EXAM = 'exam',
}

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

  @Column({ type: 'varchar', length: 16, default: LessonSessionKind.LESSON })
  kind: LessonSessionKind;

  /** Exams: the course and the path position they belong to. */
  @Column({ type: 'uuid', nullable: true })
  courseId: string | null;

  @Column({ type: 'int', nullable: true })
  examPosition: number | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  examTitle: string | null;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;

  @Column({ type: 'int', default: 0 })
  correctCount: number;

  @Column({ type: 'int', default: 0 })
  totalCount: number;

  /** Extra review exercise IDs injected into this session (SRS). */
  @Column({ type: 'uuid', array: true, default: [] })
  reviewExerciseIds: string[];

  /**
   * Pages passed in this session, keyed by exercise id or `note:<index>`.
   * Filled by POST /sessions/:id/steps; submit reuses these grades.
   */
  @Column({ type: 'jsonb', default: {} })
  steps: Record<string, SessionStepRecord>;

  /** Combo rewards granted during this session (for the result screen). */
  @Column({ type: 'jsonb', default: [] })
  comboRewards: Array<Record<string, unknown>>;

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
