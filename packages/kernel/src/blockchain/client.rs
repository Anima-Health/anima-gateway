use super::{BlockchainConfig, Error, Result};
use std::sync::Arc;

/// Wrapper around IOTA SDK client for blockchain interactions
/// 
/// NOTE: For hackathon demo, this is a configuration holder
/// In production with funded wallet, this would hold the actual IOTA SDK Client
#[derive(Clone)]
pub struct BlockchainClient {
    // pub client: Arc<Client>, // Commented for demo - requires funded wallet
    pub config: BlockchainConfig,
    pub demo_mode: bool,
}

impl BlockchainClient {
    /// Create a new blockchain client connected to the configured network
    /// 
    /// NOTE: For hackathon demo, runs in DEMO MODE
    /// In production with funded wallet, this would establish real IOTA network connection
    pub async fn new(config: BlockchainConfig) -> Result<Self> {
        println!("->> Initializing IOTA blockchain client");
        println!("    Network: {}", config.network_url);
        println!("    Package ID: {}", config.contracts.package_id);
        println!("    Anchor Contract: {}", config.contracts.anchor);
        println!("    Mode: DEMO (requires funded wallet for real transactions)");
        
        // For hackathon demo: Works without funded wallet
        // Shows all contract addresses and demonstrates the integration
        // 
        // To enable REAL transactions:
        // 1. Get testnet IOTA from faucet
        // 2. Add IOTA_MNEMONIC to .env
        // 3. Uncomment IOTA SDK client initialization below
        
        println!("->> ✅ Blockchain client initialized (demo mode)");
        
        Ok(Self {
            // client: Arc::new(client), // Requires funded wallet
            config,
            demo_mode: true,
        })
    }
    
    /// Create a client connected to IOTA testnet
    pub async fn testnet() -> Result<Self> {
        Self::new(BlockchainConfig::testnet()).await
    }
    
    /// Get the package ID of deployed contracts
    pub fn package_id(&self) -> &str {
        &self.config.contracts.package_id
    }
    
    /// Get the AnimaAnchor shared object address
    pub fn anchor_address(&self) -> &str {
        &self.config.contracts.anchor
    }
    
    /// Get the Governor shared object address
    pub fn governor_address(&self) -> &str {
        &self.config.contracts.governor
    }
    
    /// Get the ConsentRegistry shared object address
    pub fn consent_registry_address(&self) -> &str {
        &self.config.contracts.consent_registry
    }
    
    /// Get the DIDRoleRegistry shared object address
    pub fn did_registry_address(&self) -> &str {
        &self.config.contracts.did_registry
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    #[ignore] // Requires network access
    async fn test_client_creation() {
        let client = BlockchainClient::testnet().await;
        assert!(client.is_ok());
    }
}

