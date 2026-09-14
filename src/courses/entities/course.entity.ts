import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Section } from '../../sections/entities/section.entity';
import { Word } from '../../words/entities/word.entity';

@Entity('courses')
export class Course {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  /** Domain tag so the same engine can host language, medicine, etc. */
  @Column({ type: 'varchar', length: 100, default: 'language' })
  domain: string;

  @Column({ type: 'varchar', length: 16, default: 'fa' })
  locale: string;

  @Column({ type: 'int', default: 1 })
  order: number;

  @Column({ type: 'boolean', default: true })
  isPublished: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => Section, (section) => section.course, {
    cascade: true,
  })
  sections: Section[];

  @OneToMany(() => Word, (word) => word.course)
  words: Word[];
}
