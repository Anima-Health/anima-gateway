import { useState, useEffect } from 'react';
import { Shield, CheckCircle, XCircle, Hash, List } from 'lucide-react';
import { verifyService, MerkleProof, VerificationResponse } from '@/services/verify.service';

interface VerifyPanelProps {
  initialPatientId?: string | null;
}

export default function VerifyPanel({ initialPatientId }: VerifyPanelProps) {
  const [patientId, setPatientId] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<VerificationResponse | null>(null);

  // Auto-fill patient ID if provided
  useEffect(() => {
    if (initialPatientId) {
      setPatientId(initialPatientId);
      // Auto-verify if ID is provided
      handleVerifyWithId(initialPatientId);
    }
  }, [initialPatientId]);

  const handleVerifyWithId = async (id: string) => {
    if (!id.trim()) {
      setError('Please enter a patient ID');
      return;
    }

    setLoading(true);
    setError('');
    setResult(null);

    try {
      const verification = await verifyService.verifyPatient(id);
      setResult(verification);
      console.log('Verification result:', verification);
    } catch (err: any) {
      console.error('Verification error:', err);
      setError(err.response?.data?.error?.type || 'Verification failed');
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async () => {
    handleVerifyWithId(patientId);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="card-brutal bg-black text-white">
        <div className="flex items-center gap-3">
          <Shield size={32} />
          <div>
            <h2 className="text-3xl font-black">DATA INTEGRITY VERIFICATION</h2>
            <p className="text-sm font-medium mt-1">
              Cryptographic proof using Merkle trees & IOTA blockchain
            </p>
          </div>
        </div>
      </div>

      {/* Input */}
      <div className="card-brutal">
        <h3 className="text-xl font-black mb-4 uppercase">Verify Patient Record</h3>

        <div className="mb-4">
          <label className="block mb-2 font-bold uppercase text-sm">
            Patient ID
          </label>
          <input
            type="text"
            value={patientId}
            onChange={(e) => setPatientId(e.target.value)}
            className="input-brutal font-mono text-sm"
            placeholder="e.g., 87dfcbdd-1e4c-4a62-a829-78558e87a5f1"
          />
          <div className="mt-2 bg-gray-100 border-2 border-black p-3">
            <p className="text-xs font-bold mb-2">HOW TO GET PATIENT ID:</p>
            <ol className="text-xs space-y-1 font-medium">
              <li>1. Go to <strong>PATIENT LIST</strong> tab</li>
              <li>2. Patient ID is shown in gray box</li>
              <li>3. Click <strong>VERIFY</strong> button (auto-fills here!)</li>
              <li>4. Or copy ID and paste above</li>
            </ol>
          </div>
        </div>

        {error && (
          <div className="bg-black text-white border-4 border-black p-4 mb-4">
            <div className="flex items-center gap-2">
              <XCircle size={20} />
              <span className="font-bold">{error}</span>
            </div>
          </div>
        )}

        <button
          onClick={handleVerify}
          disabled={loading || !patientId.trim()}
          className="btn-brutal w-full flex items-center justify-center gap-2"
        >
          <Shield size={20} />
          {loading ? 'VERIFYING...' : 'VERIFY WITH MERKLE PROOF'}
        </button>

        {/* How it Works */}
        <div className="bg-gray-100 border-4 border-black p-4 mt-6">
          <h4 className="font-black text-sm mb-2">HOW MERKLE PROOF WORKS:</h4>
          <ol className="space-y-1 text-sm font-medium">
            <li>1. Patient data is hashed (SHA-256)</li>
            <li>2. Hash is stored as leaf in Merkle tree</li>
            <li>3. Tree is combined up to single root hash</li>
            <li>4. Root hash is anchored to IOTA blockchain</li>
            <li>5. Proof shows path from leaf to root</li>
            <li>6. Anyone can verify data hasn't changed!</li>
          </ol>
        </div>
      </div>

      {/* Verification Result */}
      {result && result.success && result.proof && (
        <div className="space-y-4">
          {/* Status Banner */}
          <div className={`border-4 border-black p-6 ${result.verified ? 'bg-green-50' : 'bg-red-50'}`}>
            <div className="flex items-center gap-3">
              {result.verified ? (
                <CheckCircle size={32} className="text-green-700" />
              ) : (
                <XCircle size={32} className="text-red-700" />
              )}
              <div>
                <h3 className="text-2xl font-black">
                  {result.verified ? 'VERIFIED ✅' : 'VERIFICATION FAILED ❌'}
                </h3>
                <p className="font-medium mt-1">{result.message}</p>
              </div>
            </div>
          </div>

          {/* Merkle Proof Details */}
          <div className="card-brutal">
            <h3 className="text-xl font-black mb-4 uppercase">Merkle Proof Details</h3>

            <div className="space-y-4">
              {/* Patient ID */}
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">
                  PATIENT ID (IN BATCH)
                </div>
                <div className="bg-gray-100 border-2 border-black p-3 font-mono text-sm break-all">
                  {result.proof.patient_id}
                </div>
              </div>

              {/* Leaf Hash */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <Hash size={16} />
                  <div className="text-xs font-black uppercase text-gray-600">
                    LEAF HASH (Patient Data)
                  </div>
                </div>
                <div className="bg-black text-white border-4 border-black p-3 font-mono text-xs break-all">
                  {result.proof.leaf_hash}
                </div>
                <p className="text-xs mt-1 font-medium text-gray-600">
                  SHA-256 hash of complete patient record
                </p>
              </div>

              {/* Proof Path */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <List size={16} />
                  <div className="text-xs font-black uppercase text-gray-600">
                    PROOF PATH ({result.proof.proof_hashes.length} steps)
                  </div>
                </div>
                <div className="bg-gray-100 border-2 border-black p-4">
                  {result.proof.proof_hashes.length === 0 ? (
                    <p className="text-xs font-medium text-gray-600">
                      Single leaf - no intermediate hashes needed
                    </p>
                  ) : (
                    <div className="space-y-2">
                      {result.proof.proof_hashes.map((hash, i) => (
                        <div key={i} className="flex items-start gap-2">
                          <div className="bg-black text-white px-2 py-1 font-black text-xs">
                            {i + 1}
                          </div>
                          <div className="flex-1 font-mono text-xs break-all bg-white border-2 border-black p-2">
                            {hash}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                  <p className="text-xs mt-3 font-bold text-gray-600">
                    ↑ Sibling hashes used to reconstruct path to root
                  </p>
                </div>
              </div>

              {/* Root Hash */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <CheckCircle size={16} />
                  <div className="text-xs font-black uppercase text-gray-600">
                    MERKLE ROOT (Anchored to IOTA)
                  </div>
                </div>
                <div className="bg-black text-white border-4 border-black p-3 font-mono text-xs break-all">
                  {result.proof.root_hash}
                </div>
                <p className="text-xs mt-1 font-bold text-green-700">
                  ✅ This root hash is anchored on IOTA blockchain (immutable!)
                </p>
              </div>

              {/* Position Info */}
              <div className="bg-white border-4 border-black p-4">
                <h4 className="font-black text-sm mb-2">TECHNICAL DETAILS:</h4>
                <div className="text-xs space-y-1 font-medium">
                  <div>
                    <span className="font-black">Leaf Index:</span> {result.proof.leaf_index}
                  </div>
                  <div>
                    <span className="font-black">Tree Depth:</span> {result.proof.proof_hashes.length + 1} levels
                  </div>
                  <div>
                    <span className="font-black">Algorithm:</span> SHA-256
                  </div>
                  <div>
                    <span className="font-black">Verification:</span>{' '}
                    <span className={result.verified ? 'text-green-700' : 'text-red-700'}>
                      {result.verified ? 'PASSED ✅' : 'FAILED ❌'}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* What This Proves */}
          <div className="bg-black text-white border-4 border-black p-6">
            <h4 className="font-black text-sm mb-3">WHAT THIS CRYPTOGRAPHIC PROOF GUARANTEES:</h4>
            <ul className="space-y-2 text-sm font-medium">
              <li>✅ This exact patient record was included in batch</li>
              <li>✅ Data hasn't been altered since anchoring</li>
              <li>✅ Timestamp is verifiable on IOTA blockchain</li>
              <li>✅ Anyone can verify using only the root hash</li>
              <li>✅ No need to reveal other patient data</li>
              <li>✅ Mathematically impossible to forge</li>
            </ul>
          </div>
        </div>
      )}

      {/* Not Found */}
      {result && !result.success && (
        <div className="card-brutal">
          <div className="flex items-start gap-3">
            <XCircle size={24} className="text-red-600" />
            <div>
              <h4 className="font-black text-sm mb-2">NOT VERIFIED</h4>
              <p className="text-sm font-medium">{result.message}</p>
              <p className="text-xs mt-2 text-gray-600">
                Make sure the patient ID is correct and has been included in an anchored batch.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

