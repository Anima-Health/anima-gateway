'use client';

import { useState } from 'react';
import Dashboard from '@/components/Dashboard';
import LoginPage from '@/components/LoginPage';

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const handleLogout = () => {
    // Just logout on frontend, backend keeps all data
    setIsAuthenticated(false);
  };

  const handleLogin = (did: string) => {
    setIsAuthenticated(true);
  };

  return (
    <main className="min-h-screen bg-white">
      {isAuthenticated ? (
        <Dashboard onLogout={handleLogout} />
      ) : (
        <LoginPage onLoginSuccess={handleLogin} />
      )}
    </main>
  );
}

