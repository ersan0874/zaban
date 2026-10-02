import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ContentSourceFile } from './content-source-file.entity';
import { ContentProposal } from './content-proposal.entity';
import { ContentDraftLesson } from './content-draft-lesson.entity';

export enum ContentJobStatus {
  EXTRACTING = 'extracting',
  PROPOSING = 'proposing',
  /** Review point 1: admin picks one of the structure proposals. */
  AWAITING_STRUCTURE = 'awaiting_structure',
  GENERATING = 'generating',
  /** Review point 2: admin reviews notes and questions. */
  AWAITING_REVIEW = 'awaiting_review',
  PUBLISHED = 'published',
  FAILED = 'failed',
}

export interface ContentJobSettings {
  /** Language for learner-facing text (notes, instructions). */
  outputLanguage: string;
  /** How many questions of each type to generate per lesson. */
  questionCounts: Record<string, number>;
  /** Free-text guidance from the admin (audience, level, focus...). */
  instructions?: string;
}

/** A unit of source text the AI can reference by index. */
export interface SourceBlock {
  index: number;
  file: string;
  page: number | null;
  text: string;
}

export interface TokenUsageTotals {
  inputTokens: number;
  outputTokens: number;
  calls: number;
}

@Entity('content_jobs')
export class ContentJob {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'varchar', length: 32, default: ContentJobStatus.EXTRACTING })
  status: ContentJobStatus;

  @Column({ type: 'jsonb' })
  settings: ContentJobSettings;

  @Column({ type: 'jsonb', default: [] })
  sourceBlocks: SourceBlock[];

  /** Suggested by the AI during proposal; editable at publish. */
  @Column({ type: 'varchar', length: 100, nullable: true })
  domain: string | null;

  @Column({ type: 'text', nullable: true })
  error: string | null;

  /** Set while waiting for the provider quota to reset. */
  @Column({ type: 'timestamptz', nullable: true })
  pausedUntil: Date | null;

  @Column({
    type: 'jsonb',
    default: { inputTokens: 0, outputTokens: 0, calls: 0 },
  })
  tokenUsage: TokenUsageTotals;

  @Column({ type: 'uuid', nullable: true })
  selectedProposalId: string | null;

  @Column({ type: 'uuid', nullable: true })
  publishedCourseId: string | null;

  @Column({ type: 'uuid', nullable: true })
  createdBy: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => ContentSourceFile, (file) => file.job)
  files: ContentSourceFile[];

  @OneToMany(() => ContentProposal, (proposal) => proposal.job)
  proposals: ContentProposal[];

  @OneToMany(() => ContentDraftLesson, (lesson) => lesson.job)
  lessons: ContentDraftLesson[];
}
