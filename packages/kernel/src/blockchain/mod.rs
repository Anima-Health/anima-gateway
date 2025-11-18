// Blockchain integration with deployed IOTA Move contracts
//
// This module handles all on-chain interactions with the Anima Health
// smart contracts deployed on IOTA testnet.

pub mod config;
pub mod client;
pub mod anchor;
pub mod error;

pub use self::config::{BlockchainConfig, ContractAddresses};
pub use self::client::BlockchainClient;
pub use self::anchor::AnchorContract;
pub use self::error::{Error, Result};

