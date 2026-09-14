'use client';

import { useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch } from '@/lib/api';

type UserRow = {
  id: string;
  email: string;
  role: string;
  banned: boolean;
  displayName: string | null;
  createdAt: string;
  energyBalance: number | null;
};

export default function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [error, setError] = useState('');

  async function load() {
    try {
      setUsers(await apiFetch<UserRow[]>('/admin/users'));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function toggleBan(user: UserRow) {
    await apiFetch(`/admin/users/${user.id}/ban`, {
      method: 'PATCH',
      body: JSON.stringify({ banned: !user.banned }),
    });
    await load();
  }

  return (
    <AdminShell>
      <h2>Users</h2>
      {error && <p className="error">{error}</p>}
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Email</th>
              <th>Name</th>
              <th>Role</th>
              <th>Energy</th>
              <th>Banned</th>
              <th>Created</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id}>
                <td>{u.email}</td>
                <td>{u.displayName ?? '—'}</td>
                <td>{u.role}</td>
                <td>{u.energyBalance ?? '—'}</td>
                <td>{u.banned ? 'Yes' : 'No'}</td>
                <td>{new Date(u.createdAt).toLocaleDateString()}</td>
                <td>
                  <button
                    type="button"
                    className={u.banned ? 'secondary' : 'danger'}
                    onClick={() => toggleBan(u)}
                  >
                    {u.banned ? 'Unban' : 'Ban'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminShell>
  );
}
