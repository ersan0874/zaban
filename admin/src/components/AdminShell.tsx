'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { clearToken, getToken } from '@/lib/api';
import { useEffect } from 'react';

const links = [
  { href: '/users', label: 'Users' },
  { href: '/analytics', label: 'Analytics' },
  { href: '/cms', label: 'CMS' },
  { href: '/ai-jobs', label: 'AI Jobs' },
  { href: '/purchases', label: 'Purchases' },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (!getToken()) router.replace('/login');
  }, [router]);

  return (
    <div className="layout">
      <aside className="sidebar">
        <h1>Zaban Admin</h1>
        <nav>
          {links.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              style={
                pathname === l.href
                  ? { background: '#334155', fontWeight: 600 }
                  : undefined
              }
            >
              {l.label}
            </Link>
          ))}
        </nav>
        <button
          type="button"
          className="secondary"
          style={{ marginTop: '2rem', width: '100%' }}
          onClick={() => {
            clearToken();
            router.push('/login');
          }}
        >
          Logout
        </button>
      </aside>
      <main className="main">{children}</main>
    </div>
  );
}
