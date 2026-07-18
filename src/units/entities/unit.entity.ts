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

  @OneToMany(() => Word, (word) => word.unit, {
    cascade: true,
  })
  words: Word[];

  @OneToMany(() => Question, (question) => question.unit, {
    cascade: true,
  })
  questions: Question[];
}
