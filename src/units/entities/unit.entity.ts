import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Section } from '../../sections/entities/section.entity';
import { Word } from '../../words/entities/word.entity';
import { Question } from '../../questions/entities/question.entity';
import { Lesson } from '../../lessons/entities/lesson.entity';

@Entity('units')
export class Unit {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'int' })
  order: number;

  @Column({ type: 'uuid' })
  sectionId: string;

  @ManyToOne(() => Section, (section) => section.units, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'sectionId' })
  section: Section;

  @OneToMany(() => Lesson, (lesson) => lesson.unit, {
    cascade: true,
  })
  lessons: Lesson[];

  /** Legacy study vocabulary attached to a unit (still used by seed/study). */
  @OneToMany(() => Word, (word) => word.unit, {
    cascade: true,
  })
  words: Word[];

  /** @deprecated Prefer Exercise under Lesson; kept for backward compatibility. */
  @OneToMany(() => Question, (question) => question.unit, {
    cascade: true,
  })
  questions: Question[];
}
