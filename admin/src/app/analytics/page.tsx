'use client';

import { useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch } from '@/lib/api';

type Analytics = {
  userCount: number;
  sessionCount: number;
  avgScore: number;
  comboTxnCount: number;
};

export default function AnalyticsPage() {
  const [data, setData] = useState<Analytics | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch<Analytics>('/admin/analytics')
      .then(setData)
      .catch((err) =>
        setError(err instanceof Error ? err.message : 'Failed to load'),
      );
  }, []);

  return (
    <AdminShell>
      <h2>Analytics</h2>
      {error && <p className="error">{error}</p>}
      {data && (
        <div className="stat-grid">
          <div className="stat">
            <strong>{data.userCount}</strong>
            Users
          </div>
          <div className="stat">
            <strong>{data.sessionCount}</strong>
            Sessions
          </div>
          <div className="stat">
            <strong>{(data.avgScore * 100).toFixed(1)}%</strong>
            Avg score
          </div>
          <div className="stat">
            <strong>{data.comboTxnCount}</strong>
            Combo rewards
          </div>
        </div>
      )}
    </AdminShell>
  );
}
