mod error;
mod patient;
mod merkle;
mod store;
mod anchor;

pub use self::error::{Error, Result};
pub use self::patient::{Patient, PatientDemographics, PatientForCreate, PatientForUpdate, PatientBmc};
pub use self::merkle::{MerkleTree, MerkleRoot, MerkleProof, hash_data, hash_to_hex, verify_proof};
pub use self::store::ReductStore;
pub use self::anchor::{AnchorService, AnchoredBatch};

use std::sync::Arc;
use std::collections::HashMap;
use tokio::sync::Mutex;
use crate::blockchain::{BlockchainClient, AnchorContract};

#[derive(Clone)]
pub struct ModelManager {
    store: Arc<ReductStore>,
    // Batch queue for Merkle tree anchoring
    pub(crate) pending_anchors: Arc<Mutex<Vec<String>>>, // Patient IDs waiting to be anchored
    // Blockchain integration (optional for POC)
    pub(crate) blockchain: Option<Arc<BlockchainClient>>,
    pub(crate) anchor_contract: Option<Arc<AnchorContract>>,
    // Store anchored batches for proof generation
    pub(crate) anchored_batches: Arc<Mutex<HashMap<u64, (AnchoredBatch, Vec<String>)>>>, // batch_id -> (batch, patient_ids)
}

impl ModelManager {
    pub async fn new() -> Result<Self> {
        // Initialize ReductStore connection
        let store = ReductStore::new("http://127.0.0.1:8383", None).await?;

        // Try to initialize blockchain client (optional - won't fail if network unavailable)
        let (blockchain, anchor_contract) = match BlockchainClient::testnet().await {
            Ok(client) => {
                println!("->> ✅ Blockchain client initialized");
                let anchor = AnchorContract::new(client.clone());
                (Some(Arc::new(client)), Some(Arc::new(anchor)))
            }
            Err(e) => {
                println!("->> ⚠️  Blockchain client not available: {}", e);
                println!("->>    Continuing without on-chain anchoring (dev mode)");
                (None, None)
            }
        };

        Ok(ModelManager {
            store: Arc::new(store),
            pending_anchors: Arc::new(Mutex::new(Vec::new())),
            blockchain,
            anchor_contract,
            anchored_batches: Arc::new(Mutex::new(HashMap::new())),
        })
    }
    
    /// Get reference to blockchain client (if available)
    pub fn blockchain(&self) -> Option<&Arc<BlockchainClient>> {
        self.blockchain.as_ref()
    }
    
    /// Get reference to anchor contract (if available)
    pub fn anchor_contract(&self) -> Option<&Arc<AnchorContract>> {
        self.anchor_contract.as_ref()
    }

    /// Store a patient record in ReductStore
    pub async fn store_patient(&self, patient: &Patient) -> Result<()> {
        self.store.write_patient(patient).await?;
        
        // Add to pending anchors queue
        let mut queue = self.pending_anchors.lock().await;
        queue.push(patient.id.clone());
        
        Ok(())
    }

    /// Get a patient record from ReductStore
    pub async fn get_patient(&self, id: &str) -> Result<Patient> {
        self.store.read_patient(id).await
    }

    /// List all patients (for POC - in production would have pagination)
    pub async fn list_patients(&self) -> Result<Vec<Patient>> {
        self.store.list_patients().await
    }

    /// Mark patient as deleted
    pub async fn delete_patient(&self, id: &str) -> Result<()> {
        self.store.delete_patient(id).await
    }

    /// Create Merkle root from pending records and return for anchoring
    pub async fn create_anchor_batch(&self) -> Result<Option<(MerkleRoot, Vec<String>)>> {
        let mut queue = self.pending_anchors.lock().await;
        
        if queue.is_empty() {
            return Ok(None);
        }

        let mut tree = MerkleTree::new();
        let patient_ids: Vec<String> = queue.clone();
        
        // Hash each patient record WITH patient ID
        for patient_id in queue.iter() {
            if let Ok(patient) = self.get_patient(patient_id).await {
                let patient_json = serde_json::to_vec(&patient)
                    .map_err(|e| Error::MerkleError(e.to_string()))?;
                tree.add_leaf_with_id(&patient_json, patient_id.clone());
            }
        }

        let root_hash = tree.root()
            .ok_or_else(|| Error::MerkleError("Failed to compute Merkle root".to_string()))?;

        let batch_id = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let merkle_root = MerkleRoot {
            root_hash,
            algo_id: "sha256".to_string(),
            batch_id,
            record_count: tree.leaf_count(),
            timestamp: batch_id,
        };

        // Clear the queue
        queue.clear();

        Ok(Some((merkle_root, patient_ids)))
    }
    
    /// Generate a Merkle proof for a patient in a specific batch
    pub async fn generate_merkle_proof(&self, patient_id: &str) -> Result<Option<MerkleProof>> {
        let batches = self.anchored_batches.lock().await;
        
        // Find which batch contains this patient
        for (batch_id, (batch, patient_ids)) in batches.iter() {
            if let Some(index) = patient_ids.iter().position(|id| id == patient_id) {
                // Reconstruct the Merkle tree for this batch
                let mut tree = MerkleTree::new();
                for pid in patient_ids {
                    if let Ok(patient) = self.get_patient(pid).await {
                        let patient_json = serde_json::to_vec(&patient)
                            .map_err(|e| Error::MerkleError(e.to_string()))?;
                        tree.add_leaf_with_id(&patient_json, pid.clone());
                    }
                }
                
                // Generate proof
                return Ok(tree.generate_proof(index));
            }
        }
        
        Ok(None)
    }
    
    /// Store an anchored batch for later proof generation
    pub async fn store_anchored_batch(&self, batch: AnchoredBatch, patient_ids: Vec<String>) {
        let mut batches = self.anchored_batches.lock().await;
        batches.insert(batch.batch_id, (batch, patient_ids));
    }
}