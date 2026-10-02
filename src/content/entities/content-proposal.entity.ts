import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ContentJob } from './content-job.entity';

export interface OutlineLesson {
  title: string;
  objective: string;
  /** Inclusive source block range this lesson is built from. */
  blockStart: number;
  blockEnd: number;
}

export interface OutlineUnit {
  title: string;
  lessons: OutlineLesson[];
}

/** A chapter. Maps to `Section`; its units map to `Unit`. */
export interface OutlineSection {
  title: string;
  units: OutlineUnit[];
}

export interface CourseOutline {
  courseTitle: string;
  courseDescription: string;
  sections: OutlineSection[];
}

@Entity('content_proposals')
export class ContentProposal {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  jobId: string;

  @Column({ type: 'int' })
  order: number;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  /** Why the AI split the content this way. */
  @Column({ type: 'text' })
  rationale: string;

  @Column({ type: 'jsonb' })
  outline: CourseOutline;

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => ContentJob, (job) => job.proposals, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'jobId' })
  job: ContentJob;
}
