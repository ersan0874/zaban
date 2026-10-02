'use client';

import { useParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch } from '@/lib/api';
import {
  BUSY_STATUSES,
  ContentJobDetail,
  CourseOutline,
  DraftExercise,
  DraftLesson,
  Proposal,
  QuestionTypeInfo,
  STATUS_LABELS,
  statusBadgeClass,
} from '@/lib/content';

type SourceBlock = { index: number; file: string; page: number | null; text: string };

function errorText(err: unknown) {
  return err instanceof Error ? err.message : 'Request failed';
}

export default function ContentJobPage() {
  const { id } = useParams<{ id: string }>();
  const [job, setJob] = useState<ContentJobDetail | null>(null);
  const [lessons, setLessons] = useState<DraftLesson[]>([]);
  const [labels, setLabels] = useState<Record<string, string>>({});
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    const detail = await apiFetch<ContentJobDetail>(`/admin/content/jobs/${id}`);
    setJob(detail);
    if (detail.selectedProposalId) {
      setLessons(await apiFetch<DraftLesson[]>(`/admin/content/jobs/${id}/lessons`));
    }
  }, [id]);

  useEffect(() => {
    load().catch((err) => setError(errorText(err)));
    apiFetch<QuestionTypeInfo[]>('/admin/content/question-types')
      .then((t) => setLabels(Object.fromEntries(t.map((x) => [x.type, x.label]))))
      .catch(() => undefined);
  }, [load]);

  // Poll while the pipeline is working.
  useEffect(() => {
    if (!job || !BUSY_STATUSES.has(job.status)) return;
    const t = setInterval(() => load().catch(() => undefined), 4000);
    return () => clearInterval(t);
  }, [job, load]);

  async function run(action: () => Promise<unknown>) {
    setError('');
    try {
      await action();
      await load();
    } catch (err) {
      setError(errorText(err));
    }
  }

  if (!job) {
    return (
      <AdminShell>
        {error ? <p className="error">{error}</p> : <p>Loading…</p>}
      </AdminShell>
    );
  }

  const failedLessons = job.lessonStats.failed ?? 0;

  return (
    <AdminShell>
      <h2 dir="auto">{job.title}</h2>
      {error && <p className="error">{error}</p>}

      <div className="card">
        <div className="row">
          <span className={statusBadgeClass(job.status)}>
            {STATUS_LABELS[job.status] ?? job.status}
            {BUSY_STATUSES.has(job.status) ? '…' : ''}
          </span>
          {job.domain && <span className="badge">{job.domain}</span>}
          <span className="muted">
            {job.tokenUsage.calls} AI calls ·{' '}
            {(job.tokenUsage.inputTokens + job.tokenUsage.outputTokens).toLocaleString()} tokens ·{' '}
            {job.blockCount} source blocks
          </span>
        </div>
        {job.pausedUntil && (
          <p className="muted">
            Free AI quota used up — paused until{' '}
            {new Date(job.pausedUntil).toLocaleString()}, then continues automatically.
          </p>
        )}
        {job.error && <p className="error">{job.error}</p>}
        <ul className="muted">
          {job.files.map((f) => (
            <li key={f.id} dir="auto">
              {f.originalName} · {(f.sizeBytes / 1024).toFixed(0)} KB ·{' '}
              {f.extracted ? `${f.extractedChars.toLocaleString()} chars extracted` : 'waiting'}
            </li>
          ))}
        </ul>
        {job.status === 'generating' && (
          <p className="muted">
            Lessons: {job.lessonStats.ready ?? 0} ready, {job.lessonStats.generating ?? 0} generating,{' '}
            {job.lessonStats.pending ?? 0} waiting, {failedLessons} failed
          </p>
        )}
        {(job.status === 'failed' || failedLessons > 0) && (
          <button type="button" onClick={() => run(() => apiFetch(`/admin/content/jobs/${id}/retry`, { method: 'POST' }))}>
            Retry failed steps
          </button>
        )}
      </div>

      {job.status === 'awaiting_structure' && (
        <>
          <h3>Step 1 — choose how to split the content</h3>
          <div className="grid-2">
            {job.proposals.map((p) => (
              <ProposalCard
                key={p.id}
                proposal={p}
                onSelect={(outline) =>
                  run(() =>
                    apiFetch(`/admin/content/jobs/${id}/proposals/${p.id}/select`, {
                      method: 'POST',
                      body: JSON.stringify(outline ? { outline } : {}),
                    }),
                  )
                }
              />
            ))}
          </div>
        </>
      )}

      {lessons.length > 0 && (
        <>
          <h3>Step 2 — review lessons and questions</h3>
          {job.exercisesNeedingReview > 0 && (
            <p className="muted">
              {job.exercisesNeedingReview} question(s) are flagged. Fix, approve or delete them before publishing.
            </p>
          )}
          {lessons.map((lesson, i) => {
            const prev = lessons[i - 1];
            const newSection = !prev || prev.sectionOrder !== lesson.sectionOrder;
            const newUnit = newSection || prev.unitOrder !== lesson.unitOrder;
            return (
              <div key={lesson.id}>
                {newSection && <h3 dir="auto">{lesson.sectionTitle}</h3>}
                {newUnit && <h4 dir="auto" className="muted">{lesson.unitTitle}</h4>}
                <LessonCard
                  jobId={id}
                  lesson={lesson}
                  labels={labels}
                  editable={job.status !== 'published'}
                  run={run}
                />
              </div>
            );
          })}
        </>
      )}

      {job.status === 'awaiting_review' && <PublishCard job={job} run={run} />}

      {job.status === 'published' && (
        <div className="card">
          <strong>Published.</strong> Course id: {job.publishedCourseId}
        </div>
      )}
    </AdminShell>
  );
}

function ProposalCard({
  proposal,
  onSelect,
}: {
  proposal: Proposal;
  onSelect: (edited?: CourseOutline) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [json, setJson] = useState(JSON.stringify(proposal.outline, null, 2));
  const [jsonError, setJsonError] = useState('');
  const o = proposal.outline;
  const lessonCount = o.sections.reduce(
    (n, s) => n + s.units.reduce((m, u) => m + u.lessons.length, 0),
    0,
  );

  return (
    <div className="card outline" dir="auto">
      <h4 style={{ marginTop: 0 }}>{proposal.title}</h4>
      <p className="muted">{proposal.rationale}</p>
      <p>
        <strong>{o.courseTitle}</strong> · {o.sections.length} chapters · {lessonCount} lessons
      </p>
      {editing ? (
        <>
          <textarea className="code" rows={18} value={json} onChange={(e) => setJson(e.target.value)} dir="ltr" />
          {jsonError && <p className="error">{jsonError}</p>}
        </>
      ) : (
        <ul>
          {o.sections.map((s, si) => (
            <li key={si}>
              <strong>{s.title}</strong>
              <ul>
                {s.units.map((u, ui) => (
                  <li key={ui}>
                    {u.title}
                    <ul>
                      {u.lessons.map((l, li) => (
                        <li key={li} title={l.objective}>
                          {l.title} <span className="muted">(B{l.blockStart}–B{l.blockEnd})</span>
                        </li>
                      ))}
                    </ul>
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      )}
      <div className="row">
        <button
          type="button"
          onClick={() => {
            if (!editing) return onSelect();
            try {
              onSelect(JSON.parse(json) as CourseOutline);
            } catch {
              setJsonError('Invalid JSON');
            }
          }}
        >
          {editing ? 'Use edited structure' : 'Use this structure'}
        </button>
        <button type="button" className="secondary" onClick={() => setEditing(!editing)}>
          {editing ? 'Cancel edit' : 'Edit'}
        </button>
      </div>
    </div>
  );
}

function LessonCard({
  jobId,
  lesson,
  labels,
  editable,
  run,
}: {
  jobId: string;
  lesson: DraftLesson;
  labels: Record<string, string>;
  editable: boolean;
  run: (action: () => Promise<unknown>) => Promise<void>;
}) {
  const [notes, setNotes] = useState(lesson.notes.join('\n'));
  const [source, setSource] = useState<SourceBlock[] | null>(null);

  useEffect(() => setNotes(lesson.notes.join('\n')), [lesson.notes]);

  const statusClass =
    lesson.status === 'ready' ? 'badge ok' : lesson.status === 'failed' ? 'badge bad' : 'badge';

  return (
    <div className="card" dir="auto">
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <div>
          <strong>{lesson.title}</strong> <span className={statusClass}>{lesson.status}</span>
          <div className="muted">{lesson.objective}</div>
        </div>
        <div className="row">
          <button
            type="button"
            className="secondary"
            onClick={async () =>
              setSource(
                source
                  ? null
                  : await apiFetch<SourceBlock[]>(
                      `/admin/content/jobs/${jobId}/source?from=${lesson.blockStart}&to=${lesson.blockEnd}`,
                    ),
              )
            }
          >
            {source ? 'Hide source' : 'Source'}
          </button>
          {editable && (
            <button
              type="button"
              className="secondary"
              onClick={() => run(() => apiFetch(`/admin/content/lessons/${lesson.id}/regenerate`, { method: 'POST' }))}
            >
              Regenerate
            </button>
          )}
        </div>
      </div>
      {lesson.error && <p className="error">{lesson.error}</p>}
      {source && (
        <pre className="source">
          {source.map((b) => `[B${b.index} · ${b.file}${b.page ? ` p.${b.page}` : ''}]\n${b.text}`).join('\n\n')}
        </pre>
      )}

      {lesson.status === 'ready' && (
        <>
          <label>Notes (one per line)</label>
          <textarea rows={Math.max(3, lesson.notes.length + 1)} value={notes} onChange={(e) => setNotes(e.target.value)} disabled={!editable} />
          {editable && notes !== lesson.notes.join('\n') && (
            <button
              type="button"
              onClick={() =>
                run(() =>
                  apiFetch(`/admin/content/lessons/${lesson.id}`, {
                    method: 'PATCH',
                    body: JSON.stringify({ notes: notes.split('\n').map((n) => n.trim()).filter(Boolean) }),
                  }),
                )
              }
            >
              Save notes
            </button>
          )}
          {lesson.keyTerms.length > 0 && (
            <p className="muted">
              Key terms: {lesson.keyTerms.map((t) => `${t.term} — ${t.meaning}`).join(' · ')}
            </p>
          )}
          {lesson.exercises.map((ex) => (
            <ExerciseCard key={ex.id} exercise={ex} label={labels[ex.type] ?? ex.type} editable={editable} run={run} />
          ))}
        </>
      )}
    </div>
  );
}

function ExerciseCard({
  exercise,
  label,
  editable,
  run,
}: {
  exercise: DraftExercise;
  label: string;
  editable: boolean;
  run: (action: () => Promise<unknown>) => Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const [prompt, setPrompt] = useState(exercise.prompt);
  const [content, setContent] = useState(JSON.stringify(exercise.content, null, 2));
  const [answer, setAnswer] = useState(JSON.stringify(exercise.answer, null, 2));
  const flagged = exercise.quality === 'needs_review';

  function save() {
    return run(() =>
      apiFetch(`/admin/content/exercises/${exercise.id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          prompt,
          content: JSON.parse(content) as unknown,
          answer: JSON.parse(answer) as unknown,
        }),
      }).then(() => setEditing(false)),
    );
  }

  return (
    <div className={`exercise${flagged ? ' flagged' : ''}`}>
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <span>
          <span className="badge">{label}</span> {exercise.prompt}
        </span>
        {editable && (
          <div className="row">
            {flagged && (
              <button type="button" onClick={() => run(() => apiFetch(`/admin/content/exercises/${exercise.id}`, { method: 'PATCH', body: '{}' }))}>
                Approve
              </button>
            )}
            <button type="button" className="secondary" onClick={() => setEditing(!editing)}>
              {editing ? 'Cancel' : 'Edit'}
            </button>
            <button type="button" className="danger" onClick={() => run(() => apiFetch(`/admin/content/exercises/${exercise.id}`, { method: 'DELETE' }))}>
              Delete
            </button>
          </div>
        )}
      </div>
      {flagged && exercise.qualityNote && <p className="muted">⚠ {exercise.qualityNote}</p>}
      {editing ? (
        <>
          <label>Instruction</label>
          <input value={prompt} onChange={(e) => setPrompt(e.target.value)} />
          <div className="grid-2">
            <div>
              <label>Content (JSON)</label>
              <textarea className="code" rows={8} dir="ltr" value={content} onChange={(e) => setContent(e.target.value)} />
            </div>
            <div>
              <label>Answer (JSON)</label>
              <textarea className="code" rows={8} dir="ltr" value={answer} onChange={(e) => setAnswer(e.target.value)} />
            </div>
          </div>
          <button type="button" onClick={() => void save()}>Save</button>
        </>
      ) : (
        <div className="grid-2 muted">
          <pre className="source">{JSON.stringify(exercise.content, null, 2)}</pre>
          <pre className="source">{JSON.stringify(exercise.answer, null, 2)}</pre>
        </div>
      )}
    </div>
  );
}

function PublishCard({
  job,
  run,
}: {
  job: ContentJobDetail;
  run: (action: () => Promise<unknown>) => Promise<void>;
}) {
  const selected = job.proposals.find((p) => p.id === job.selectedProposalId);
  const [courseTitle, setCourseTitle] = useState(selected?.outline.courseTitle ?? job.title);
  const [domain, setDomain] = useState(job.domain ?? '');

  return (
    <div className="card">
      <h3 style={{ marginTop: 0 }}>Step 3 — publish to the app</h3>
      <div className="grid-2">
        <div>
          <label>Course title</label>
          <input dir="auto" value={courseTitle} onChange={(e) => setCourseTitle(e.target.value)} />
        </div>
        <div>
          <label>Domain (&quot;language&quot; turns key terms into vocabulary words)</label>
          <input value={domain} onChange={(e) => setDomain(e.target.value)} />
        </div>
      </div>
      <button
        type="button"
        disabled={job.exercisesNeedingReview > 0}
        onClick={() =>
          run(() =>
            apiFetch(`/admin/content/jobs/${job.id}/publish`, {
              method: 'POST',
              body: JSON.stringify({ courseTitle, domain: domain || undefined }),
            }),
          )
        }
      >
        Publish course
      </button>
    </div>
  );
}
