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
