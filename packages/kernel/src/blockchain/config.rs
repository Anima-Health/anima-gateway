use serde::{Deserialize, Serialize};

/// Configuration for IOTA blockchain connection and deployed contracts
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BlockchainConfig {
    /// IOTA network URL (testnet or mainnet)
    pub network_url: String,
    
    /// Contract addresses on-chain
    pub contracts: ContractAddresses,
    
    /// Optional faucet URL for testnet
    pub faucet_url: Option<String>,
}

/// Addresses of deployed Anima Health smart contracts
/// 
/// Extracted from deployment transaction:
/// Transaction Digest: 5xsAFe2GCTKqdWXRVj69K3fyZznm74fnMohV8smGdqbZ
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ContractAddresses {
    /// Package ID of the deployed contracts
    /// Contains all modules: access_control, anima_governor, consent_attestor, core_anchor, did_role_registry
    pub package_id: String,
    
    /// AnimaGovernor shared object
    /// Type: anima_governor::AnimaGovernor
    pub governor: String,
    
    /// AnimaAnchor shared object (core_anchor module)
    /// Type: core_anchor::AnimaAnchor
    /// This is where Merkle roots are anchored
    pub anchor: String,
    
    /// ConsentRegistry shared object
    /// Type: consent_attestor::ConsentRegistry
    pub consent_registry: String,
    
    /// DIDRoleRegistry shared object
    /// Type: did_role_registry::DIDRoleRegistry
    pub did_registry: String,
}

impl BlockchainConfig {
    /// Create configuration for IOTA testnet with deployed contracts
    pub fn testnet() -> Self {
        Self {
            network_url: "https://api.testnet.iota.cafe:443".to_string(),
            faucet_url: Some("https://faucet.testnet.iota.cafe".to_string()),
            contracts: ContractAddresses {
                // Package ID from PUB_ADDR.md
                package_id: "0xa79a18c3b241a6c4e07a867f4a0d91c72da9b993af9d304ea44e1c6efb1bb21b".to_string(),
                
                // Shared objects from deployment
                governor: "0x60ac84612b7871b8b5f83ed950e1f2b1eb6afc279746f7ba55c697340ef634aa".to_string(),
                anchor: "0xa593714c58cc09ca801f7063463d7a024be198bcb07fe10d22c876a8e12653ca".to_string(),
                consent_registry: "0xc4f3152366a7b643dc9608ab0875ca2a84c38db31e215f59d5287403c1b82088".to_string(),
                did_registry: "0xd5a01037f6f016285c4cecf970a71414379d6829f80e5d3dddd874362cc338db".to_string(),
            },
        }
    }
    
    /// Create configuration for IOTA mainnet (when ready for production)
    pub fn mainnet() -> Self {
        Self {
            network_url: "https://api.iota.cafe:443".to_string(),
            faucet_url: None,
            contracts: ContractAddresses {
                // TODO: Update with mainnet deployment addresses
                package_id: "0x0000000000000000000000000000000000000000000000000000000000000000".to_string(),
                governor: "0x0000000000000000000000000000000000000000000000000000000000000000".to_string(),
                anchor: "0x0000000000000000000000000000000000000000000000000000000000000000".to_string(),
                consent_registry: "0x0000000000000000000000000000000000000000000000000000000000000000".to_string(),
                did_registry: "0x0000000000000000000000000000000000000000000000000000000000000000".to_string(),
            },
        }
    }
    
    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        let network = std::env::var("IOTA_NETWORK").unwrap_or_else(|_| "testnet".to_string());
        
        match network.as_str() {
            "mainnet" => Self::mainnet(),
            _ => Self::testnet(),
        }
    }
}

impl Default for BlockchainConfig {
    fn default() -> Self {
        Self::testnet()
    }
}

