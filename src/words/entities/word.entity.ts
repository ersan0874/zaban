import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Unit } from '../../units/entities/unit.entity';
import { Course } from '../../courses/entities/course.entity';

export interface WordExample {
  english: string;
  persian: string;
}

@Entity('words')
export class Word {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  word: string;

  @Column({ type: 'varchar', length: 500 })
  persianMeaning: string;

  @Column({ type: 'text', array: true, default: [] })
  synonyms: string[];

  @Column({ type: 'jsonb', default: [] })
  examples: WordExample[];

  /** Optional course-level lexicon link (domain-agnostic asset). */
  @Column({ type: 'uuid', nullable: true })
  courseId: string | null;

  @ManyToOne(() => Course, (course) => course.words, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'courseId' })
  course: Course | null;

  @Column({ type: 'uuid', nullable: true })
  unitId: string | null;

  @ManyToOne(() => Unit, (unit) => unit.words, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'unitId' })
  unit: Unit | null;
}
