'use client';

import { useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch } from '@/lib/api';

type Purchase = {
  id: string;
  email: string | null;
  displayName: string | null;
  productId: string;
  platform: string;
  status: string;
  createdAt: string;
};

export default function PurchasesPage() {
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch<Purchase[]>('/admin/purchases')
      .then(setPurchases)
      .catch((err) =>
        setError(err instanceof Error ? err.message : 'Failed to load'),
      );
  }, []);

  return (
    <AdminShell>
      <h2>Purchases</h2>
      {error && <p className="error">{error}</p>}
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>User</th>
              <th>Product</th>
              <th>Platform</th>
              <th>Status</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {purchases.map((p) => (
              <tr key={p.id}>
                <td>
                  {p.displayName ?? p.email ?? p.id.slice(0, 8)}
                </td>
                <td>{p.productId}</td>
                <td>{p.platform}</td>
                <td>{p.status}</td>
                <td>{new Date(p.createdAt).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminShell>
  );
}
