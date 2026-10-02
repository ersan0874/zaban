export type QuestionTypeInfo = {
  type: string;
  label: string;
  defaultCount: number;
};

export type ContentJobSummary = {
  id: string;
  title: string;
  status: string;
  domain: string | null;
  error: string | null;
  pausedUntil: string | null;
  tokenUsage: { inputTokens: number; outputTokens: number; calls: number };
  publishedCourseId: string | null;
  createdAt: string;
};

export type OutlineLesson = {
  title: string;
  objective: string;
  blockStart: number;
  blockEnd: number;
};
export type CourseOutline = {
  courseTitle: string;
  courseDescription: string;
  sections: Array<{
    title: string;
    units: Array<{ title: string; lessons: OutlineLesson[] }>;
  }>;
};

export type Proposal = {
  id: string;
  order: number;
  title: string;
  rationale: string;
  outline: CourseOutline;
};

export type ContentJobDetail = ContentJobSummary & {
  settings: {
    outputLanguage: string;
    questionCounts: Record<string, number>;
    instructions?: string;
  };
  selectedProposalId: string | null;
  blockCount: number;
  files: Array<{
    id: string;
    originalName: string;
    sizeBytes: number;
    extracted: boolean;
    extractedChars: number;
  }>;
  proposals: Proposal[];
  lessonStats: Record<string, number>;
  exercisesNeedingReview: number;
};

export type DraftExercise = {
  id: string;
  type: string;
  prompt: string;
  order: number;
  content: Record<string, unknown>;
  answer: Record<string, unknown>;
  relatedTerm: string | null;
  quality: 'ok' | 'needs_review';
  qualityNote: string | null;
};

export type DraftLesson = {
  id: string;
  sectionOrder: number;
  sectionTitle: string;
  unitOrder: number;
  unitTitle: string;
  order: number;
  title: string;
  objective: string;
  blockStart: number;
  blockEnd: number;
  status: 'pending' | 'generating' | 'ready' | 'failed';
  notes: string[];
  keyTerms: Array<{ term: string; meaning: string }>;
  error: string | null;
  exercises: DraftExercise[];
};

export const STATUS_LABELS: Record<string, string> = {
  extracting: 'Reading files',
  proposing: 'Designing structures',
  awaiting_structure: 'Choose a structure',
  generating: 'Generating lessons',
  awaiting_review: 'Ready for review',
  published: 'Published',
  failed: 'Failed',
};

export const BUSY_STATUSES = new Set(['extracting', 'proposing', 'generating']);

export function statusBadgeClass(status: string) {
  if (status === 'failed') return 'badge bad';
  if (status === 'published' || status === 'awaiting_review') return 'badge ok';
  if (status === 'awaiting_structure') return 'badge warn';
  return 'badge';
}
