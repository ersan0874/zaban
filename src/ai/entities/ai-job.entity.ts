import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum AiJobStatus {
  UPLOADED = 'uploaded',
  EXTRACTING = 'extracting',
  STRUCTURING = 'structuring',
  GENERATING = 'generating',
  AWAITING_REVIEW = 'awaiting_review',
  PUBLISHED = 'published',
  FAILED = 'failed',
}

@Entity('ai_jobs')
export class AiJob {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 32, default: AiJobStatus.UPLOADED })
  status: AiJobStatus;

  @Column({ type: 'varchar', length: 32, default: 'text' })
  sourceType: string;

  @Column({ type: 'text' })
  sourceText: string;

  @Column({ type: 'jsonb', nullable: true })
  resultJson: Record<string, unknown> | null;

  @Column({ type: 'uuid', nullable: true })
  createdBy: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
