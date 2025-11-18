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
    pub async fn create_batch(mm: &ModelManager) -> Result<Option<(AnchoredBatch, Vec<String>)>> {
        let result = mm.create_anchor_batch().await?;

        if let Some((root, patient_ids)) = result {
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
            println!("    Patient IDs: {:?}", patient_ids);

            Ok(Some((batch, patient_ids)))
        } else {
            Ok(None)
        }
    }

    /// Anchor batch to IOTA blockchain using deployed smart contract
    /// 
    /// Calls the deployed core_anchor::anchor_root() function on-chain
    pub async fn anchor_to_blockchain(mm: &ModelManager, batch: &AnchoredBatch) -> Result<String> {
        println!("->> BLOCKCHAIN: Anchoring batch #{}", batch.batch_id);
        println!("    Root: {}", batch.root_hash_hex);
        
        // Try to use real blockchain if available
        if let Some(anchor_contract) = mm.anchor_contract() {
            println!("    ✅ Using REAL IOTA blockchain!");
            println!("    Contract: {}", mm.blockchain().unwrap().anchor_address());
            
            match anchor_contract.anchor_root(batch).await {
                Ok(tx_hash) => {
                    println!("    ✅ Transaction: {}", tx_hash);
                    return Ok(tx_hash);
                }
                Err(e) => {
                    println!("    ⚠️  Blockchain call failed: {}", e);
                    println!("    Falling back to mock mode");
                }
            }
        } else {
            println!("    ⚠️  Blockchain not available (dev mode)");
        }
        
        // Fallback: Return mock transaction hash
        println!("    Using mock transaction hash");
        Ok(format!("0xmock_{:x}_testnet", batch.batch_id))
    }

    /// Get current pending count (for monitoring)
    pub async fn pending_count(mm: &ModelManager) -> usize {
        let queue = mm.pending_anchors.lock().await;
        queue.len()
    }
}

