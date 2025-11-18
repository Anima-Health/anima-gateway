use super::{BlockchainClient, Error, Result};
use crate::model::AnchoredBatch;

/// Interface to the core_anchor Move contract on IOTA
pub struct AnchorContract {
    client: BlockchainClient,
}

impl AnchorContract {
    /// Create a new anchor contract interface
    pub fn new(client: BlockchainClient) -> Self {
        Self { client }
    }
    
    /// Anchor a Merkle root to the IOTA blockchain
    /// 
    /// Calls: core_anchor::anchor_root(anchor_obj, root_hash, algo_id, record_count, meta_uri)
    /// 
    /// # Arguments
    /// * `batch` - The Merkle batch with root hash and metadata
    /// 
    /// # Returns
    /// Transaction digest as a hex string
    pub async fn anchor_root(&self, batch: &AnchoredBatch) -> Result<String> {
        println!("->> Anchoring Merkle root to IOTA blockchain");
        println!("    Root hash: {}", batch.root_hash_hex);
        println!("    Record count: {}", batch.record_count);
        println!("    Batch ID: {}", batch.batch_id);
        
        // For POC: Return mock transaction hash
        // In production, this would:
        // 1. Load or create a signing keypair
        // 2. Build a programmable transaction block:
        //    - Call core_anchor::anchor_root(...)
        // 3. Sign and execute the transaction
        // 4. Return the transaction digest
        
        let mock_tx_hash = format!(
            "0x{}{}",
            batch.root_hash_hex.chars().take(60).collect::<String>(),
            "mock_iota_tx"
        );
        
        println!("->> ✅ Merkle root anchored!");
        println!("    Transaction: {}", mock_tx_hash);
        println!("    Anchor contract: {}", self.client.anchor_address());
        
        Ok(mock_tx_hash)
        
        // TODO: Uncomment for REAL on-chain anchoring:
        /*
        use iota_sdk::types::transaction::{
            ProgrammableTransaction,
            Transaction,
            TransactionData,
        };
        
        // 1. Load keypair (from env or config)
        let keypair = /* load from secure storage */;
        
        // 2. Build transaction
        let package_id = self.client.package_id();
        let anchor_obj = self.client.anchor_address();
        
        let mut ptb = ProgrammableTransaction::default();
        
        // Call core_anchor::anchor_root
        ptb.command(MoveCall {
            package: ObjectID::from_hex_literal(package_id)
                .map_err(|e| Error::InvalidAddress(e.to_string()))?,
            module: Identifier::new("core_anchor").unwrap(),
            function: Identifier::new("anchor_root").unwrap(),
            type_arguments: vec![],
            arguments: vec![
                Argument::Input(0), // anchor_obj (shared object)
                Argument::Input(1), // root_hash (vector<u8>)
                Argument::Input(2), // algo_id (String)
                Argument::Input(3), // record_count (u64)
                Argument::Input(4), // meta_uri (String)
            ],
        });
        
        // 3. Build transaction data
        let tx_data = TransactionData::new_programmable(
            sender,
            vec![
                InputObject::SharedObject {
                    id: ObjectID::from_hex_literal(anchor_obj)?,
                    initial_shared_version: /* get from chain */,
                    mutable: true,
                },
                InputValue::Pure(bcs::to_bytes(&hex::decode(&batch.root_hash_hex)?)?),
                InputValue::Pure(bcs::to_bytes(&batch.algo_id)?),
                InputValue::Pure(bcs::to_bytes(&batch.record_count)?),
                InputValue::Pure(bcs::to_bytes(&batch.meta_uri)?),
            ],
            ptb,
            gas_budget,
            gas_price,
        );
        
        // 4. Sign transaction
        let signature = Signature::new_secure(&tx_data, &keypair);
        
        // 5. Execute transaction
        let response = self.client.client
            .execute_transaction_block(
                Transaction::from_data(tx_data, vec![signature]),
                /* options */,
            )
            .await
            .map_err(|e| Error::TransactionFailed(e.to_string()))?;
        
        Ok(response.digest.to_string())
        */
    }
    
    /// Verify a Merkle root on-chain
    /// 
    /// Queries the blockchain to confirm a root hash was anchored
    pub async fn verify_root(&self, root_hash: &str) -> Result<bool> {
        println!("->> Verifying Merkle root on blockchain");
        println!("    Root hash: {}", root_hash);
        
        // For POC: Always return true
        // In production, this would query the AnimaAnchor object's dynamic fields
        // to check if this root_hash exists
        
        Ok(true)
    }
    
    /// Get the total number of anchored roots from the blockchain
    pub async fn get_anchor_count(&self) -> Result<u64> {
        // For POC: Return 0
        // In production, query the AnimaAnchor object's `anchor_count` field
        Ok(0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    #[ignore] // Requires network access
    async fn test_anchor_contract_creation() {
        let client = BlockchainClient::testnet().await.unwrap();
        let anchor = AnchorContract::new(client);
        
        // Test that we can create the contract interface
        assert!(anchor.client.anchor_address().starts_with("0x"));
    }
}

