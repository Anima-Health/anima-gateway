mod error;
mod patient;
mod merkle;
mod store;
mod anchor;

pub use self::error::{Error, Result};
pub use self::patient::{Patient, PatientDemographics, PatientForCreate, PatientForUpdate, PatientBmc};
pub use self::merkle::{MerkleTree, MerkleRoot, hash_data, hash_to_hex};
pub use self::store::ReductStore;
pub use self::anchor::{AnchorService, AnchoredBatch};

use std::sync::Arc;
use tokio::sync::Mutex;

#[derive(Clone)]
pub struct ModelManager {
    store: Arc<ReductStore>,
    // Batch queue for Merkle tree anchoring
    pub(crate) pending_anchors: Arc<Mutex<Vec<String>>>, // Patient IDs waiting to be anchored
}

impl ModelManager {
    pub async fn new() -> Result<Self> {
        // Initialize ReductStore connection
        let store = ReductStore::new("http://127.0.0.1:8383", None).await?;

        Ok(ModelManager {
            store: Arc::new(store),
            pending_anchors: Arc::new(Mutex::new(Vec::new())),
        })
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
    pub async fn create_anchor_batch(&self) -> Result<Option<MerkleRoot>> {
        let mut queue = self.pending_anchors.lock().await;
        
        if queue.is_empty() {
            return Ok(None);
        }

        let mut tree = MerkleTree::new();
        
        // Hash each patient record
        for patient_id in queue.iter() {
            if let Ok(patient) = self.get_patient(patient_id).await {
                let patient_json = serde_json::to_vec(&patient)
                    .map_err(|e| Error::MerkleError(e.to_string()))?;
                tree.add_leaf(&patient_json);
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

        Ok(Some(merkle_root))
    }
}