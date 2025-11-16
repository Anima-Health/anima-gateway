import { useState } from 'react';
import { User, Calendar, FileText, UserCircle, MapPin, Sparkles, AlertCircle } from 'lucide-react';
import { patientService, PatientForCreate, Patient } from '@/services/patient.service';

interface PatientFormProps {
  onSuccess: (patient: Patient) => void;
}

export default function PatientForm({ onSuccess }: PatientFormProps) {
  const [formData, setFormData] = useState<PatientForCreate>({
    name: '',
    date_of_birth: '',
    medical_record_number: '',
    gender: '',
    address: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [createdPatient, setCreatedPatient] = useState<Patient | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const patient = await patientService.createPatient(formData);
      console.log('Patient created:', patient);
      setCreatedPatient(patient);
      onSuccess(patient);
    } catch (err: any) {
      console.error('Error creating patient:', err);
      setError(err.response?.data?.error?.type || 'Failed to create patient');
    } finally {
      setLoading(false);
    }
  };

  if (createdPatient) {
    return (
      <div className="space-y-6">
        {/* Success Message */}
        <div className="bg-black text-white border-4 border-black p-6">
          <div className="flex items-center gap-3 mb-3">
            <Sparkles size={24} />
            <h2 className="text-2xl font-black">PATIENT CREATED!</h2>
          </div>
          <p className="font-medium">
            Unique IOTA DID generated with REAL Ed25519 cryptography
          </p>
        </div>

        {/* Patient DID Card */}
        <div className="card-brutal">
          <h3 className="text-xl font-black mb-4 uppercase">IOTA DID GENERATED</h3>
          
          <div className="space-y-4">
            <div>
              <div className="text-xs font-black uppercase text-gray-600 mb-2">PATIENT DID</div>
              <div className="bg-gray-100 border-2 border-black p-3 font-mono text-sm break-all">
                {createdPatient.did}
              </div>
              <p className="text-xs mt-1 font-medium text-gray-600">
                ✅ Format: did:iota:anima:{'{patient_uuid}'}
              </p>
            </div>

            <div>
              <div className="text-xs font-black uppercase text-gray-600 mb-2">
                PUBLIC KEY (Ed25519) - REAL CRYPTO!
              </div>
              <div className="bg-black text-white border-4 border-black p-3 font-mono text-xs break-all">
                {createdPatient.did_metadata.public_key}
              </div>
              <p className="text-xs mt-2 font-bold text-green-700">
                ✅ Real 32-byte key generated with ed25519-dalek 2.0 + OsRng (NOT MOCK!)
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">KEY VERSION</div>
                <div className="bg-black text-white px-3 py-2 text-center font-black">
                  v{createdPatient.did_metadata.key_version}
                </div>
              </div>
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">STATUS</div>
                <div className="bg-black text-white px-3 py-2 text-center font-black">
                  {createdPatient.did_metadata.status}
                </div>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t-4 border-black">
            <div className="text-xs font-black uppercase text-gray-600 mb-2">OPENEHR COMPOSITION</div>
            <div className="bg-gray-100 border-2 border-black p-3">
              <div className="font-mono text-xs space-y-1">
                <div><span className="font-black">UID:</span> {createdPatient.composition.uid}</div>
                <div><span className="font-black">Archetype:</span> {createdPatient.composition.archetype_id}</div>
                <div><span className="font-black">Category:</span> {createdPatient.composition.category}</div>
                <div><span className="font-black">Subject DID:</span> {createdPatient.composition.subject_did}</div>
              </div>
              <div className="mt-2 text-xs font-bold text-gray-600">
                ✅ International healthcare standard (NHS, EU hospitals)
              </div>
            </div>
          </div>

          {/* Storage Info */}
          <div className="mt-4 bg-white border-4 border-black p-4">
            <h4 className="font-black text-sm mb-2">📊 STORED IN REDUCTSTORE</h4>
            <p className="text-xs font-medium text-gray-700">
              Full patient record with openEHR composition stored off-chain. Added to Merkle anchor queue.
            </p>
            <div className="mt-2 text-xs font-black uppercase text-gray-600">
              ZERO PHI ON BLOCKCHAIN • HIPAA COMPLIANT
            </div>
          </div>

          <button
            onClick={() => {
              setCreatedPatient(null);
              setFormData({
                name: '',
                date_of_birth: '',
                medical_record_number: '',
                gender: '',
                address: ''
              });
            }}
            className="btn-brutal w-full mt-6"
          >
            CREATE ANOTHER PATIENT
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="card-brutal max-w-3xl">
      <h2 className="text-3xl font-black mb-6 uppercase">Create Patient Record</h2>
      
      {error && (
        <div className="bg-black text-white border-4 border-black p-4 mb-6">
          <div className="flex items-center gap-2">
            <AlertCircle size={20} />
            <span className="font-bold">{error}</span>
          </div>
        </div>
      )}
      
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Name */}
        <div>
          <label className="block mb-2 font-bold uppercase text-sm tracking-wide">
            <User className="inline mr-2" size={16} />
            Full Name *
          </label>
          <input
            type="text"
            required
            value={formData.name}
            onChange={(e) => setFormData({...formData, name: e.target.value})}
            className="input-brutal"
            placeholder="John Doe"
          />
        </div>

        {/* Date of Birth */}
        <div>
          <label className="block mb-2 font-bold uppercase text-sm tracking-wide">
            <Calendar className="inline mr-2" size={16} />
            Date of Birth *
          </label>
          <input
            type="date"
            required
            value={formData.date_of_birth}
            onChange={(e) => setFormData({...formData, date_of_birth: e.target.value})}
            className="input-brutal"
          />
        </div>

        {/* Medical Record Number */}
        <div>
          <label className="block mb-2 font-bold uppercase text-sm tracking-wide">
            <FileText className="inline mr-2" size={16} />
            Medical Record Number *
          </label>
          <input
            type="text"
            required
            value={formData.medical_record_number}
            onChange={(e) => setFormData({...formData, medical_record_number: e.target.value})}
            className="input-brutal"
            placeholder="MRN001"
          />
        </div>

        {/* Gender */}
        <div>
          <label className="block mb-2 font-bold uppercase text-sm tracking-wide">
            <UserCircle className="inline mr-2" size={16} />
            Gender (ISO 5218 Coded)
          </label>
          <select
            value={formData.gender}
            onChange={(e) => setFormData({...formData, gender: e.target.value})}
            className="input-brutal"
          >
            <option value="">Select gender</option>
            <option value="male">Male</option>
            <option value="female">Female</option>
            <option value="other">Other</option>
          </select>
        </div>

        {/* Address */}
        <div>
          <label className="block mb-2 font-bold uppercase text-sm tracking-wide">
            <MapPin className="inline mr-2" size={16} />
            Address
          </label>
          <textarea
            value={formData.address}
            onChange={(e) => setFormData({...formData, address: e.target.value})}
            className="input-brutal"
            rows={3}
            placeholder="123 Health St, London, UK"
          />
        </div>

        {/* Info Box */}
        <div className="bg-black text-white border-4 border-black p-4">
          <h4 className="font-black text-sm mb-2">WHAT WILL BE CREATED:</h4>
          <ul className="space-y-1 text-sm font-medium">
            <li>✅ Unique IOTA DID (did:iota:anima:{'{uuid}'})</li>
            <li>✅ Real Ed25519 keypair (32-byte keys with OsRng)</li>
            <li>✅ openEHR composition (healthcare standard)</li>
            <li>✅ Stored in ReductStore (off-chain)</li>
            <li>✅ Queued for Merkle anchoring to IOTA</li>
          </ul>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={loading}
          className="btn-brutal w-full flex items-center justify-center gap-2"
        >
          <Sparkles size={20} />
          {loading ? 'CREATING DID & openEHR...' : 'CREATE PATIENT WITH IOTA DID'}
        </button>
      </form>
    </div>
  );
}
