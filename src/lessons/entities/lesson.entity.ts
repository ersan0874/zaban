import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Unit } from '../../units/entities/unit.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';

export enum LessonKind {
  STANDARD = 'standard',
  CHECKPOINT = 'checkpoint',
  DIAGNOSTIC = 'diagnostic',
}

@Entity('lessons')
export class Lesson {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  summary: string | null;

  @Column({ type: 'int' })
  order: number;

  /** Target duration in minutes (micro-learning 3–5). */
  @Column({ type: 'int', default: 4 })
  estimatedMinutes: number;

  @Column({ type: 'varchar', length: 32, default: LessonKind.STANDARD })
  lessonKind: LessonKind;

  @Column({ type: 'uuid' })
  unitId: string;

  @ManyToOne(() => Unit, (unit) => unit.lessons, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'unitId' })
  unit: Unit;

  @OneToMany(() => Exercise, (exercise) => exercise.lesson, {
    cascade: true,
  })
  exercises: Exercise[];
}
