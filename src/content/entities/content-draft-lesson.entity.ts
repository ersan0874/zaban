import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ContentJob } from './content-job.entity';
import { ContentDraftExercise } from './content-draft-exercise.entity';

export enum DraftLessonStatus {
  PENDING = 'pending',
  GENERATING = 'generating',
  READY = 'ready',
  FAILED = 'failed',
}

export interface KeyTerm {
  term: string;
  meaning: string;
}

/**
 * One lesson of the chosen outline, before publishing. Chapter and unit are
 * denormalised (index + title) because they only exist to group lessons.
 */
@Entity('content_draft_lessons')
export class ContentDraftLesson {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  jobId: string;

  @Column({ type: 'int' })
  sectionOrder: number;

  @Column({ type: 'varchar', length: 255 })
  sectionTitle: string;

  @Column({ type: 'int' })
  unitOrder: number;

  @Column({ type: 'varchar', length: 255 })
  unitTitle: string;

  @Column({ type: 'int' })
  order: number;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text' })
  objective: string;

  @Column({ type: 'int' })
  blockStart: number;

  @Column({ type: 'int' })
  blockEnd: number;

  @Column({ type: 'varchar', length: 16, default: DraftLessonStatus.PENDING })
  status: DraftLessonStatus;

  /** Short bullet-style teaching notes (Markdown + LaTeX). */
  @Column({ type: 'jsonb', default: [] })
  notes: string[];

  @Column({ type: 'jsonb', default: [] })
  keyTerms: KeyTerm[];

  @Column({ type: 'text', nullable: true })
  error: string | null;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => ContentJob, (job) => job.lessons, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'jobId' })
  job: ContentJob;

  @OneToMany(() => ContentDraftExercise, (exercise) => exercise.lesson)
  exercises: ContentDraftExercise[];
}
