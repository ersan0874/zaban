import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Unit } from '../../units/entities/unit.entity';
import { QuestionType } from '../types/question.types';
import type {
  QuestionAnswer,
  QuestionContent,
} from '../types/question.types';

@Entity('questions')
export class Question {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  unitId: string;

  /**
   * Discriminator for the question module (e.g. multiple_choice, matching).
   * Stored as string so new types can be added without schema migrations.
   */
  @Column({ type: 'varchar', length: 100 })
  type: QuestionType | string;

  @Column({ type: 'text' })
  prompt: string;

  /**
   * Variable payload shaped by `type`.
   * Examples: options, matching lists, cloze text + blanks.
   */
  @Column({ type: 'jsonb' })
  content: QuestionContent;

  /**
   * Correct answer payload shaped by `type`.
   * May be a string, array, or nested object.
   */
  @Column({ type: 'jsonb' })
  answer: QuestionAnswer;

  @ManyToOne(() => Unit, (unit) => unit.questions, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'unitId' })
  unit: Unit;
}
