import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { LessonSession } from './lesson-session.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';

@Entity('session_attempts')
export class SessionAttempt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  sessionId: string;

  @Column({ type: 'uuid' })
  exerciseId: string;

  @Column({ type: 'jsonb' })
  response: unknown;

  @Column({ type: 'boolean' })
  isCorrect: boolean;

  /** 0..1 — partial credit for open-ended answers (essay). */
  @Column({ type: 'real', nullable: true })
  score: number | null;

  @Column({ type: 'text', nullable: true })
  feedback: string | null;

  /** `pending` = AI grading failed and will be retried in the background. */
  @Column({ type: 'varchar', length: 16, default: 'graded' })
  gradingStatus: 'graded' | 'pending' | 'ungraded';

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => LessonSession, (session) => session.attempts, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'sessionId' })
  session: LessonSession;

  @ManyToOne(() => Exercise, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'exerciseId' })
  exercise: Exercise;
}
