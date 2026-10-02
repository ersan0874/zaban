import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ContentJob } from './content-job.entity';

@Entity('content_source_files')
export class ContentSourceFile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  jobId: string;

  @Column({ type: 'int' })
  order: number;

  @Column({ type: 'varchar', length: 255 })
  originalName: string;

  @Column({ type: 'varchar', length: 128 })
  mimeType: string;

  @Column({ type: 'int' })
  sizeBytes: number;

  @Column({ type: 'varchar', length: 512 })
  storagePath: string;

  /** Markdown extracted from the file; `<!-- page N -->` marks page starts. */
  @Column({ type: 'text', nullable: true })
  extractedMarkdown: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => ContentJob, (job) => job.files, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'jobId' })
  job: ContentJob;
}
