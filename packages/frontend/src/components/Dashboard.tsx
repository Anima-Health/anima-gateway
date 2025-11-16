import { useState, useEffect } from 'react';
import { User, Activity, Anchor, LogOut, Plus, List } from 'lucide-react';
import PatientForm from './PatientForm';
import PatientList from './PatientList';
import AnchorPanel from './AnchorPanel';
import StatsCard from './StatsCard';
import { patientService } from '@/services/patient.service';
import { anchorService } from '@/services/anchor.service';

interface DashboardProps {
  onLogout: () => void;
}

export default function Dashboard({ onLogout }: DashboardProps) {
  const [activeTab, setActiveTab] = useState<'create' | 'list' | 'anchor'>('create');
  const [stats, setStats] = useState({
    totalPatients: 0,
    pendingAnchors: 0,
    totalBatches: 0,
  });
  const [refreshKey, setRefreshKey] = useState(0);

  // Load stats on mount and when refreshKey changes
  useEffect(() => {
    loadStats();
  }, [refreshKey]);

  const loadStats = async () => {
    try {
      const [patients, pending] = await Promise.all([
        patientService.listPatients(),
        anchorService.getPendingCount(),
      ]);
      
      setStats({
        totalPatients: patients.length,
        pendingAnchors: pending,
        totalBatches: stats.totalBatches, // Keep existing count
      });
    } catch (err) {
      console.error('Error loading stats:', err);
    }
  };

  const handlePatientCreated = () => {
    setStats({
      ...stats,
      totalPatients: stats.totalPatients + 1,
      pendingAnchors: stats.pendingAnchors + 1,
    });
    // Trigger refresh of patient list
    setRefreshKey(prev => prev + 1);
  };

  const handleBatchCreated = () => {
    setStats({
      ...stats,
      totalBatches: stats.totalBatches + 1,
      pendingAnchors: 0,
    });
    setRefreshKey(prev => prev + 1);
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="border-b-4 border-black p-6">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div>
            <h1 className="text-4xl font-black tracking-tight">ANIMA HEALTH</h1>
            <p className="text-sm font-bold uppercase mt-1 tracking-wide">
              Healthcare Data Provenance
            </p>
          </div>
          
          <button
            onClick={onLogout}
            className="btn-brutal-secondary flex items-center gap-2"
          >
            <LogOut size={18} />
            LOGOUT
          </button>
        </div>
      </header>

      {/* Stats Bar */}
      <div className="border-b-4 border-black bg-gray-100">
        <div className="max-w-7xl mx-auto p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <StatsCard
              icon={<User size={24} />}
              value={stats.totalPatients}
              label="TOTAL PATIENTS"
              subtitle="with unique IOTA DIDs"
            />
            <StatsCard
              icon={<Activity size={24} />}
              value={stats.pendingAnchors}
              label="PENDING ANCHORS"
              subtitle="waiting for batch"
            />
            <StatsCard
              icon={<Anchor size={24} />}
              value={stats.totalBatches}
              label="MERKLE BATCHES"
              subtitle="anchored to IOTA"
            />
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto p-6">
        {/* Tab Navigation */}
        <div className="flex gap-0 mb-6 border-4 border-black w-fit">
          <button
            onClick={() => setActiveTab('create')}
            className={`px-6 py-3 font-black uppercase text-sm tracking-wide transition-colors border-r-4 border-black ${
              activeTab === 'create'
                ? 'bg-black text-white'
                : 'bg-white text-black hover:bg-gray-100'
            }`}
          >
            <Plus className="inline mr-2" size={16} />
            CREATE PATIENT
          </button>
          <button
            onClick={() => setActiveTab('list')}
            className={`px-6 py-3 font-black uppercase text-sm tracking-wide transition-colors border-r-4 border-black ${
              activeTab === 'list'
                ? 'bg-black text-white'
                : 'bg-white text-black hover:bg-gray-100'
            }`}
          >
            <List className="inline mr-2" size={16} />
            PATIENT LIST
          </button>
          <button
            onClick={() => setActiveTab('anchor')}
            className={`px-6 py-3 font-black uppercase text-sm tracking-wide transition-colors ${
              activeTab === 'anchor'
                ? 'bg-black text-white'
                : 'bg-white text-black hover:bg-gray-100'
            }`}
          >
            <Anchor className="inline mr-2" size={16} />
            ANCHOR BATCH
          </button>
        </div>

        {/* Tab Content */}
        <div key={refreshKey}>
          {activeTab === 'create' && <PatientForm onSuccess={handlePatientCreated} />}
          {activeTab === 'list' && <PatientList />}
          {activeTab === 'anchor' && <AnchorPanel onAnchor={handleBatchCreated} />}
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t-4 border-black mt-12 p-6 bg-gray-100">
        <div className="max-w-7xl mx-auto text-center">
          <p className="font-bold text-sm">
            Built for <span className="font-black">IOTA HACKATHON</span> by{' '}
            <span className="font-black">Akanimoh Osutuk</span>
          </p>
          <p className="text-xs mt-2 font-medium text-gray-600">
            5 Smart Contracts • 71 Tests Passing • Real Ed25519 Cryptography
          </p>
        </div>
      </footer>
    </div>
  );
}
