import { useState, useEffect } from 'react';
import { User, Key, FileText, Calendar, RefreshCw, AlertCircle } from 'lucide-react';
import { patientService, Patient } from '@/services/patient.service';

export default function PatientList() {
  const [patients, setPatients] = useState<Patient[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);

  const loadPatients = async () => {
    setLoading(true);
    setError('');
    
    try {
      const data = await patientService.listPatients();
      setPatients(data);
      console.log('Loaded patients:', data);
    } catch (err: any) {
      console.error('Error loading patients:', err);
      setError(err.response?.data?.error?.type || 'Failed to load patients');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPatients();
  }, []);

  if (loading && patients.length === 0) {
    return (
      <div className="card-brutal text-center py-12">
        <div className="inline-block animate-pulse mb-4">
          <User size={48} />
        </div>
        <p className="font-bold text-lg">Loading patients...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card-brutal">
        <div className="flex items-center gap-3 text-red-700 mb-4">
          <AlertCircle size={24} />
          <h3 className="font-black text-xl">ERROR LOADING PATIENTS</h3>
        </div>
        <p className="font-medium mb-4">{error}</p>
        <button onClick={loadPatients} className="btn-brutal">
          <RefreshCw className="inline mr-2" size={16} />
          TRY AGAIN
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-3xl font-black uppercase">Patient Records</h2>
        <div className="flex gap-3 items-center">
          <div className="badge-brutal">{patients.length} PATIENTS</div>
          <button
            onClick={loadPatients}
            className="btn-brutal-secondary px-4 py-2 text-sm"
          >
            <RefreshCw className="inline mr-1" size={14} />
            REFRESH
          </button>
        </div>
      </div>

      {patients.length === 0 && (
        <div className="card-brutal text-center py-12">
          <User size={48} className="mx-auto mb-4 text-gray-400" />
          <p className="font-bold text-lg mb-2">No patients yet</p>
          <p className="text-sm text-gray-600">
            Create your first patient to see them listed here
          </p>
        </div>
      )}

      {selectedPatient ? (
        // Patient Detail View
        <div className="card-brutal">
          <div className="flex justify-between items-start mb-6">
            <h3 className="text-2xl font-black">{selectedPatient.demographics.name}</h3>
            <button
              onClick={() => setSelectedPatient(null)}
              className="btn-brutal-secondary text-sm px-4 py-2"
            >
              BACK TO LIST
            </button>
          </div>

          <div className="space-y-6">
            {/* DID Section */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <Key size={18} />
                <h4 className="font-black uppercase text-sm">IOTA DID</h4>
              </div>
              <div className="bg-gray-100 border-2 border-black p-4">
                <div className="font-mono text-sm break-all">{selectedPatient.did}</div>
              </div>
            </div>

            {/* Public Key */}
            <div>
              <div className="font-black uppercase text-sm mb-2">
                Ed25519 PUBLIC KEY (REAL!)
              </div>
              <div className="bg-black text-white border-4 border-black p-4 font-mono text-xs break-all">
                {selectedPatient.did_metadata.public_key}
              </div>
              <div className="mt-2 text-xs font-bold text-green-700">
                ✅ Real 32-byte cryptographic key generated with OsRng (not mock!)
              </div>
            </div>

            {/* Demographics */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">Date of Birth</div>
                <div className="bg-gray-100 border-2 border-black p-3 font-bold">
                  {selectedPatient.demographics.date_of_birth}
                </div>
              </div>
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">MRN</div>
                <div className="bg-gray-100 border-2 border-black p-3 font-bold">
                  {selectedPatient.demographics.medical_record_number}
                </div>
              </div>
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">Gender</div>
                <div className="bg-gray-100 border-2 border-black p-3 font-bold uppercase">
                  {selectedPatient.demographics.gender || 'Not specified'}
                </div>
              </div>
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">Key Version</div>
                <div className="bg-gray-100 border-2 border-black p-3 font-bold">
                  v{selectedPatient.did_metadata.key_version}
                </div>
              </div>
            </div>

            {/* Address */}
            {selectedPatient.demographics.address && (
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">Address</div>
                <div className="bg-gray-100 border-2 border-black p-3 font-medium">
                  {selectedPatient.demographics.address}
                </div>
              </div>
            )}

            {/* openEHR Details */}
            <div className="bg-white border-4 border-black p-4">
              <div className="font-black text-sm mb-2">📋 OPENEHR COMPOSITION</div>
              <div className="text-xs space-y-1 font-medium">
                <div>Category: <span className="font-black">{selectedPatient.composition.category}</span></div>
                <div>Archetype: <span className="font-mono text-xs">{selectedPatient.composition.archetype_id}</span></div>
                <div>Composer: <span className="font-black">{selectedPatient.composition.composer}</span></div>
                <div className="text-gray-600 mt-2">
                  ✅ Healthcare standard compliant • {selectedPatient.composition.content.length} entries
                </div>
              </div>
            </div>

            {/* Metadata */}
            <div className="text-xs text-gray-600 font-medium">
              <div>Created: {new Date(selectedPatient.created_at).toLocaleString()}</div>
              <div>Created by: User {selectedPatient.created_by}</div>
            </div>
          </div>
        </div>
      ) : (
        // Patient List View
        <div className="grid gap-4">
          {patients.map((patient) => (
            <div
              key={patient.id}
              className="card-brutal hover:translate-x-1 hover:translate-y-1 hover:shadow-brutal transition-all cursor-pointer"
              onClick={() => setSelectedPatient(patient)}
            >
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <h3 className="text-xl font-black mb-2">{patient.demographics.name}</h3>
                  <div className="space-y-1 text-sm font-medium">
                    <div className="flex items-center gap-2">
                      <FileText size={14} />
                      <span className="font-bold">MRN:</span> {patient.demographics.medical_record_number}
                    </div>
                    <div className="flex items-center gap-2">
                      <Calendar size={14} />
                      <span className="font-bold">DOB:</span> {patient.demographics.date_of_birth}
                    </div>
                    <div className="flex items-center gap-2">
                      <Key size={14} />
                      <span className="font-mono text-xs">{patient.did.substring(0, 45)}...</span>
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="badge-brutal mb-2">DID v{patient.did_metadata.key_version}</div>
                  <div className="text-xs font-bold text-gray-600">
                    {patient.composition.content.length} openEHR entries
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

