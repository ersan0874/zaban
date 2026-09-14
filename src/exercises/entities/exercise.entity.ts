import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Lesson } from '../../lessons/entities/lesson.entity';
import type {
  QuestionAnswer,
  QuestionContent,
} from '../../questions/types/question.types';

/**
 * Canonical modular exercise under a Lesson.
 * `type` + jsonb content/answer keep the engine domain-agnostic.
 */
@Entity('exercises')
export class Exercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  lessonId: string;

  @Column({ type: 'varchar', length: 100 })
  type: string;

  @Column({ type: 'text' })
  prompt: string;

  @Column({ type: 'int', default: 0 })
  order: number;

  @Column({ type: 'jsonb' })
  content: QuestionContent;

  @Column({ type: 'jsonb' })
  answer: QuestionAnswer;

  /** Optional primary word this exercise trains (for SRS skill tracking). */
  @Column({ type: 'uuid', nullable: true })
  wordId: string | null;

  @ManyToOne(() => Lesson, (lesson) => lesson.exercises, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'lessonId' })
  lesson: Lesson;
}
