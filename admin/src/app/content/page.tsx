'use client';

import Link from 'next/link';
import { FormEvent, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch, apiUpload } from '@/lib/api';
import {
  BUSY_STATUSES,
  ContentJobSummary,
  QuestionTypeInfo,
  STATUS_LABELS,
  statusBadgeClass,
} from '@/lib/content';

export default function ContentJobsPage() {
  const [jobs, setJobs] = useState<ContentJobSummary[]>([]);
  const [types, setTypes] = useState<QuestionTypeInfo[]>([]);
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [title, setTitle] = useState('');
  const [language, setLanguage] = useState('fa');
  const [instructions, setInstructions] = useState('');
  const [files, setFiles] = useState<FileList | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [ping, setPing] = useState('');

  async function load() {
    setJobs(await apiFetch<ContentJobSummary[]>('/admin/content/jobs'));
  }

  useEffect(() => {
    apiFetch<QuestionTypeInfo[]>('/admin/content/question-types')
      .then((list) => {
        setTypes(list);
        setCounts(Object.fromEntries(list.map((t) => [t.type, t.defaultCount])));
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
    load().catch((err) =>
      setError(err instanceof Error ? err.message : 'Failed to load'),
    );
    const t = setInterval(() => load().catch(() => undefined), 5000);
    return () => clearInterval(t);
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!files?.length) return;
    setBusy(true);
    setError('');
    try {
      const form = new FormData();
      form.append('title', title);
      form.append('outputLanguage', language);
      if (instructions.trim()) form.append('instructions', instructions);
      form.append('questionCounts', JSON.stringify(counts));
      Array.from(files).forEach((f) => form.append('files', f));
      const job = await apiUpload<{ id: string }>('/admin/content/jobs', form);
      window.location.href = `/content/${job.id}`;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed');
    } finally {
      setBusy(false);
    }
  }

  async function testConnection() {
    setPing('Testing…');
    try {
      const r = await apiFetch<{ model: string; ms: number }>(
        '/admin/content/ping',
        { method: 'POST' },
      );
      setPing(`Connected · ${r.model} · ${r.ms} ms`);
    } catch (err) {
      setPing(`Failed: ${err instanceof Error ? err.message : 'unknown'}`);
    }
  }

  return (
    <AdminShell>
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <h2>AI Content</h2>
        <div className="row">
          <span className="muted">{ping}</span>
          <button type="button" className="secondary" onClick={testConnection}>
            Test AI connection
          </button>
        </div>
      </div>
      {error && <p className="error">{error}</p>}

      <div className="card">
        <h3 style={{ marginTop: 0 }}>New content from files</h3>
        <form onSubmit={onSubmit}>
          <label>Title</label>
          <input
            dir="auto"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            minLength={2}
          />
          <label>Files (PDF, images, Word .docx, text — up to 10, 50 MB each)</label>
          <input
            type="file"
            multiple
            accept=".pdf,.png,.jpg,.jpeg,.webp,.heic,.docx,.txt,.md"
            onChange={(e) => setFiles(e.target.files)}
            required
          />
          <div className="grid-2">
            <div>
              <label>Language of notes &amp; instructions</label>
              <select value={language} onChange={(e) => setLanguage(e.target.value)}>
                <option value="fa">Persian (fa)</option>
                <option value="en">English (en)</option>
              </select>
            </div>
            <div>
              <label>Guidance for the AI (optional)</label>
              <input
                dir="auto"
                value={instructions}
                onChange={(e) => setInstructions(e.target.value)}
                placeholder="e.g. audience: master's exam candidates, focus on synonyms"
              />
            </div>
          </div>
          <label>Questions per lesson</label>
          <div className="grid-2" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))' }}>
            {types.map((t) => (
              <div key={t.type}>
                <span className="muted">{t.label}</span>
                <input
                  type="number"
                  min={0}
                  max={10}
                  value={counts[t.type] ?? 0}
                  onChange={(e) =>
                    setCounts({ ...counts, [t.type]: Number(e.target.value) })
                  }
                />
              </div>
            ))}
          </div>
          <button type="submit" disabled={busy}>
            {busy ? 'Uploading…' : 'Upload & start'}
          </button>
        </form>
      </div>

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Title</th>
              <th>Status</th>
              <th>AI calls</th>
              <th>Created</th>
            </tr>
          </thead>
          <tbody>
            {jobs.map((job) => (
              <tr key={job.id}>
                <td dir="auto">
                  <Link href={`/content/${job.id}`}>{job.title}</Link>
                </td>
                <td>
                  <span className={statusBadgeClass(job.status)}>
                    {STATUS_LABELS[job.status] ?? job.status}
                    {BUSY_STATUSES.has(job.status) ? '…' : ''}
                  </span>
                  {job.pausedUntil && (
                    <span className="muted"> paused (quota) until {new Date(job.pausedUntil).toLocaleTimeString()}</span>
                  )}
                </td>
                <td>{job.tokenUsage?.calls ?? 0}</td>
                <td>{new Date(job.createdAt).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminShell>
  );
}
