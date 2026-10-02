import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ContentDraftLesson } from './content-draft-lesson.entity';

export enum DraftQuality {
  OK = 'ok',
  /** Failed validation or the AI reviewer flagged it — a human must check. */
  NEEDS_REVIEW = 'needs_review',
}

@Entity('content_draft_exercises')
export class ContentDraftExercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  draftLessonId: string;

  @Column({ type: 'varchar', length: 100 })
  type: string;

  @Column({ type: 'text' })
  prompt: string;

  @Column({ type: 'int' })
  order: number;

  @Column({ type: 'jsonb' })
  content: Record<string, unknown>;

  @Column({ type: 'jsonb' })
  answer: Record<string, unknown>;

  /** Key term this question practises (links to `Word` for language courses). */
  @Column({ type: 'varchar', length: 255, nullable: true })
  relatedTerm: string | null;

  @Column({ type: 'varchar', length: 16, default: DraftQuality.OK })
  quality: DraftQuality;

  @Column({ type: 'text', nullable: true })
  qualityNote: string | null;

  @ManyToOne(() => ContentDraftLesson, (lesson) => lesson.exercises, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'draftLessonId' })
  lesson: ContentDraftLesson;
}
