import { useState, useEffect } from 'react';
import { Anchor, Hash, Package, CheckCircle, AlertCircle, RefreshCw } from 'lucide-react';
import { anchorService, AnchorBatchResponse } from '@/services/anchor.service';

interface AnchorPanelProps {
  onAnchor: () => void;
}

export default function AnchorPanel({ onAnchor }: AnchorPanelProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [batchResult, setBatchResult] = useState<AnchorBatchResponse | null>(null);
  const [pendingCount, setPendingCount] = useState(0);
  const [loadingPending, setLoadingPending] = useState(true);

  const loadPendingCount = async () => {
    setLoadingPending(true);
    try {
      const count = await anchorService.getPendingCount();
      setPendingCount(count);
    } catch (err: any) {
      console.error('Error loading pending count:', err);
    } finally {
      setLoadingPending(false);
    }
  };

  useEffect(() => {
    loadPendingCount();
  }, []);

  const handleCreateBatch = async () => {
    setLoading(true);
    setError('');
    
    try {
      const result = await anchorService.createBatch();
      console.log('Batch created:', result);
      setBatchResult(result);
      onAnchor();
      await loadPendingCount(); // Refresh pending count
    } catch (err: any) {
      console.error('Error creating batch:', err);
      setError(err.response?.data?.error?.type || 'Failed to create batch');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="card-brutal bg-black text-white">
        <div className="flex items-center gap-3 mb-3">
          <Anchor size={32} />
          <div>
            <h2 className="text-3xl font-black">MERKLE ANCHORING</h2>
            <p className="text-sm font-medium mt-1">Batch patient records to IOTA blockchain</p>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-black text-white border-4 border-black p-4">
          <div className="flex items-center gap-2">
            <AlertCircle size={20} />
            <span className="font-bold uppercase">{error}</span>
          </div>
        </div>
      )}

      {/* Pending Records */}
      <div className="card-brutal">
        <div className="flex justify-between items-start mb-6">
          <div>
            <h3 className="text-xl font-black uppercase mb-2">Pending Records</h3>
            <p className="text-sm font-medium text-gray-600">
              Records waiting to be anchored to IOTA blockchain
            </p>
          </div>
          <div className="text-center">
            {loadingPending ? (
              <div className="animate-pulse">
                <div className="text-5xl font-black">...</div>
              </div>
            ) : (
              <>
                <div className="text-5xl font-black">{pendingCount}</div>
                <div className="text-xs font-black uppercase mt-1">RECORDS</div>
              </>
            )}
            <button
              onClick={loadPendingCount}
              className="mt-2 text-xs font-bold uppercase hover:underline"
            >
              <RefreshCw size={12} className="inline" /> Refresh
            </button>
          </div>
        </div>

        {/* Process Explanation */}
        <div className="bg-gray-100 border-4 border-black p-6 mb-6">
          <h4 className="font-black text-sm mb-4 uppercase">MERKLE TREE PROCESS:</h4>
          <div className="space-y-3 text-sm">
            <div className="flex items-start gap-3">
              <div className="bg-black text-white w-6 h-6 flex items-center justify-center font-black text-xs flex-shrink-0">1</div>
              <div>
                <div className="font-bold">Fetch patient records from ReductStore</div>
                <div className="text-xs text-gray-600">Including full openEHR compositions + DIDs</div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="bg-black text-white w-6 h-6 flex items-center justify-center font-black text-xs flex-shrink-0">2</div>
              <div>
                <div className="font-bold">Hash each record (SHA-256)</div>
                <div className="text-xs text-gray-600">Complete patient data → 32-byte hash</div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="bg-black text-white w-6 h-6 flex items-center justify-center font-black text-xs flex-shrink-0">3</div>
              <div>
                <div className="font-bold">Build Merkle tree</div>
                <div className="text-xs text-gray-600">Combine hashes into tree structure</div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="bg-black text-white w-6 h-6 flex items-center justify-center font-black text-xs flex-shrink-0">4</div>
              <div>
                <div className="font-bold">Compute root hash</div>
                <div className="text-xs text-gray-600">Single 32-byte proof for all records</div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="bg-black text-white w-6 h-6 flex items-center justify-center font-black text-xs flex-shrink-0">5</div>
              <div>
                <div className="font-bold">Anchor to IOTA blockchain</div>
                <div className="text-xs text-gray-600">core_anchor::anchor_root() smart contract</div>
              </div>
            </div>
          </div>
        </div>

        {/* Create Batch Button */}
        {!batchResult && (
          <button
            onClick={handleCreateBatch}
            disabled={loading || pendingCount === 0}
            className="btn-brutal w-full flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Package size={20} />
            {loading ? 'CREATING MERKLE BATCH...' : `CREATE MERKLE BATCH (${pendingCount} RECORDS)`}
          </button>
        )}

        {pendingCount === 0 && !batchResult && (
          <p className="text-center text-sm font-medium text-gray-600 mt-4">
            No records pending. Create patients first to anchor them.
          </p>
        )}
      </div>

      {/* Batch Result */}
      {batchResult && batchResult.success && batchResult.batch && (
        <div className="space-y-4">
          {/* Success Banner */}
          <div className="bg-black text-white border-4 border-black p-6">
            <div className="flex items-center gap-3">
              <CheckCircle size={32} />
              <div>
                <h3 className="text-2xl font-black">BATCH ANCHORED!</h3>
                <p className="text-sm font-medium mt-1">
                  {batchResult.batch.record_count} records compressed to single Merkle root
                </p>
              </div>
            </div>
          </div>

          {/* Batch Details */}
          <div className="card-brutal">
            <h3 className="text-xl font-black mb-4 uppercase">Batch Information</h3>
            
            <div className="space-y-4">
              {/* Merkle Root */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <Hash size={16} />
                  <div className="text-xs font-black uppercase text-gray-600">
                    MERKLE ROOT (SHA-256)
                  </div>
                </div>
                <div className="bg-black text-white border-4 border-black p-4 font-mono text-xs break-all">
                  {batchResult.batch.root_hash_hex}
                </div>
                <div className="mt-2 text-xs font-bold text-green-700">
                  ✅ This hash cryptographically proves {batchResult.batch.record_count} patients with exact DIDs existed at timestamp {batchResult.batch.timestamp}
                </div>
              </div>

              {/* Stats Grid */}
              <div className="grid grid-cols-3 gap-4">
                <div className="border-4 border-black p-4 text-center">
                  <div className="text-2xl font-black">{batchResult.batch.record_count}</div>
                  <div className="text-xs font-bold uppercase mt-1">Records</div>
                </div>
                <div className="border-4 border-black p-4 text-center">
                  <div className="text-2xl font-black uppercase">{batchResult.batch.algo_id}</div>
                  <div className="text-xs font-bold uppercase mt-1">Algorithm</div>
                </div>
                <div className="border-4 border-black p-4 text-center">
                  <div className="text-xl font-black">{batchResult.batch.batch_id}</div>
                  <div className="text-xs font-bold uppercase mt-1">Batch ID</div>
                </div>
              </div>

              {/* Transaction Hash */}
              {batchResult.tx_hash && (
                <div>
                  <div className="text-xs font-black uppercase text-gray-600 mb-2">
                    IOTA TRANSACTION HASH
                  </div>
                  <div className="bg-gray-100 border-2 border-black p-3 font-mono text-sm">
                    {batchResult.tx_hash}
                  </div>
                  <p className="text-xs mt-1 font-medium text-gray-600">
                    (Production: Would be live on explorer.iota.org/testnet/)
                  </p>
                </div>
              )}

              {/* Meta URI */}
              <div>
                <div className="text-xs font-black uppercase text-gray-600 mb-2">
                  METADATA URI
                </div>
                <div className="bg-gray-100 border-2 border-black p-3 font-mono text-xs break-all">
                  {batchResult.batch.meta_uri}
                </div>
              </div>
            </div>

            <button
              onClick={() => {
                setBatchResult(null);
                loadPendingCount();
              }}
              className="btn-brutal-secondary w-full mt-6"
            >
              CREATE ANOTHER BATCH
            </button>
          </div>
        </div>
      )}

      {/* No Records Message */}
      {batchResult && !batchResult.success && (
        <div className="bg-gray-100 border-4 border-black p-6">
          <div className="flex items-start gap-3">
            <AlertCircle size={20} />
            <div>
              <h4 className="font-black text-sm mb-2">{batchResult.message}</h4>
              <button onClick={loadPendingCount} className="btn-brutal-secondary mt-3">
                <RefreshCw className="inline mr-2" size={14} />
                REFRESH STATUS
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Privacy Info */}
      {!batchResult && (
        <div className="bg-gray-100 border-4 border-black p-6">
          <div className="flex items-start gap-3">
            <AlertCircle size={20} />
            <div className="flex-1">
              <h4 className="font-black text-sm mb-2">PRIVACY-PRESERVING ANCHORING</h4>
              <p className="text-sm font-medium text-gray-700 leading-relaxed">
                Only the Merkle root hash goes on-chain. All patient data (names, DOBs, medical records, DIDs)
                stays off-chain in ReductStore. The blockchain only proves the data existed at a specific time.
              </p>
              <div className="mt-3 text-xs font-bold uppercase text-gray-600">
                ✅ ZERO PHI ON BLOCKCHAIN • ✅ HIPAA COMPLIANT • ✅ CRYPTOGRAPHICALLY PROVEN
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
