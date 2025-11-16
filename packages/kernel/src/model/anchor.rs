use crate::model::{Result, ModelManager, hash_to_hex};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnchoredBatch {
    pub batch_id: u64,
    pub root_hash_hex: String,
    pub algo_id: String,
    pub record_count: usize,
    pub timestamp: u64,
    pub meta_uri: String,
}

pub struct AnchorService;

impl AnchorService {
    /// Create a batch and get Merkle root for anchoring
    pub async fn create_batch(mm: &ModelManager) -> Result<Option<AnchoredBatch>> {
        let merkle_root = mm.create_anchor_batch().await?;

        if let Some(root) = merkle_root {
            let batch = AnchoredBatch {
                batch_id: root.batch_id,
                root_hash_hex: hash_to_hex(&root.root_hash),
                algo_id: root.algo_id,
                record_count: root.record_count,
                timestamp: root.timestamp,
                meta_uri: format!("reduct://anima-patients/batch-{}", root.batch_id),
            };

            println!("->> ANCHOR: Created batch #{} with {} records", batch.batch_id, batch.record_count);
            println!("    Root Hash: {}", batch.root_hash_hex);

            Ok(Some(batch))
        } else {
            Ok(None)
        }
    }

    /// In a real implementation, this would call the smart contract
    /// For POC, we'll just return the batch info
    pub async fn anchor_to_blockchain(batch: &AnchoredBatch) -> Result<String> {
        // TODO: Call IOTA Move contract core_anchor::anchor_root()
        // For now, just simulate
        println!("->> BLOCKCHAIN: Anchoring batch #{}", batch.batch_id);
        println!("    Root: {}", batch.root_hash_hex);
        println!("    Contract Call: core_anchor::anchor_root()");
        
        // Return mock transaction hash
        Ok(format!("0x{:x}", batch.batch_id))
    }

    /// Get current pending count (for monitoring)
    pub async fn pending_count(mm: &ModelManager) -> usize {
        let queue = mm.pending_anchors.lock().await;
        queue.len()
    }
}

