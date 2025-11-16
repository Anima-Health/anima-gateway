'use client';

import { useState } from 'react';
import Dashboard from '@/components/Dashboard';
import LoginPage from '@/components/LoginPage';

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  return (
    <main className="min-h-screen bg-white">
      {isAuthenticated ? (
        <Dashboard onLogout={() => setIsAuthenticated(false)} />
      ) : (
        <LoginPage onLogin={() => setIsAuthenticated(true)} />
      )}
    </main>
  );
}

