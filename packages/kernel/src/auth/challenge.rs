use crate::auth::{Error, Result};
use std::collections::HashMap;
use tokio::sync::RwLock;
use std::sync::Arc;
use uuid::Uuid;
use std::time::{SystemTime, UNIX_EPOCH};
use serde::{Serialize, Deserialize};

const CHALLENGE_EXPIRY_SECS: u64 = 300; // 5 minutes

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Challenge {
    pub nonce: String,
    pub did: Option<String>,
    pub expires_at: u64,
    pub created_at: u64,
}

pub struct ChallengeStore {
    challenges: Arc<RwLock<HashMap<String, Challenge>>>,
}

impl ChallengeStore {
    pub fn new() -> Self {
        Self {
            challenges: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Generate a new challenge for a DID
    pub async fn create_challenge(&self, did: Option<String>) -> Challenge {
        let nonce = Uuid::new_v4().to_string();
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let challenge = Challenge {
            nonce: nonce.clone(),
            did,
            expires_at: now + CHALLENGE_EXPIRY_SECS,
            created_at: now,
        };

        // Store challenge
        let mut store = self.challenges.write().await;
        store.insert(nonce.clone(), challenge.clone());

        // Clean up expired challenges
        self.cleanup_expired(&mut store, now);

        println!("->> Challenge: Generated nonce {} (expires in {}s)", nonce, CHALLENGE_EXPIRY_SECS);

        challenge
    }

    /// Verify and consume a challenge
    pub async fn verify_and_consume(&self, nonce: &str) -> Result<Challenge> {
        let mut store = self.challenges.write().await;

        let challenge = store.remove(nonce)
            .ok_or(Error::ChallengeNotFound)?;

        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        if now > challenge.expires_at {
            return Err(Error::ChallengeExpired);
        }

        println!("->> Challenge: Verified and consumed nonce {}", nonce);

        Ok(challenge)
    }

    /// Clean up expired challenges
    fn cleanup_expired(&self, store: &mut HashMap<String, Challenge>, now: u64) {
        store.retain(|_, challenge| challenge.expires_at > now);
    }
}

impl Clone for ChallengeStore {
    fn clone(&self) -> Self {
        Self {
            challenges: Arc::clone(&self.challenges),
        }
    }
}

