'use client';

import { FormEvent, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch } from '@/lib/api';

type AiJob = {
  id: string;
  status: string;
  sourceText: string;
  resultJson: Record<string, unknown> | null;
  createdAt: string;
};

export default function AiJobsPage() {
  const [jobs, setJobs] = useState<AiJob[]>([]);
  const [text, setText] = useState('');
  const [error, setError] = useState('');

  async function load() {
    setJobs(await apiFetch<AiJob[]>('/admin/ai/jobs'));
  }

  useEffect(() => {
    load().catch((err) =>
      setError(err instanceof Error ? err.message : 'Failed to load'),
    );
    const t = setInterval(() => {
      load().catch(() => undefined);
    }, 3000);
    return () => clearInterval(t);
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    await apiFetch('/admin/ai/jobs', {
      method: 'POST',
      body: JSON.stringify({ sourceText: text }),
    });
    setText('');
    await load();
  }

  async function approve(id: string) {
    await apiFetch(`/admin/ai/jobs/${id}/approve`, { method: 'POST' });
    await load();
  }

  return (
    <AdminShell>
      <h2>AI Content Jobs</h2>
      {error && <p className="error">{error}</p>}

      <div className="card">
        <form onSubmit={onSubmit}>
          <label>Source text</label>
          <textarea
            rows={6}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Paste lesson source text…"
            required
          />
          <button type="submit">Create job</button>
        </form>
      </div>

      {jobs.map((job) => (
        <div className="card" key={job.id}>
          <p>
            <strong>{job.status}</strong> ·{' '}
            {new Date(job.createdAt).toLocaleString()}
          </p>
          <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
            {job.sourceText.slice(0, 200)}
            {job.sourceText.length > 200 ? '…' : ''}
          </p>
          {Array.isArray(job.resultJson?.drafts) && (
            <p>Drafts: {job.resultJson.drafts.length}</p>
          )}
          {job.status === 'awaiting_review' && (
            <button type="button" onClick={() => approve(job.id)}>
              Approve &amp; publish
            </button>
          )}
        </div>
      ))}
    </AdminShell>
  );
}
