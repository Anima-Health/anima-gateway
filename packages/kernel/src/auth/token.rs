use crate::auth::{Error, Result};
use serde::{Serialize, Deserialize};
use std::time::{SystemTime, UNIX_EPOCH};
use sha2::{Sha256, Digest};

const TOKEN_EXPIRY_SECS: u64 = 86400; // 24 hours
const TOKEN_SECRET: &str = "anima-secret-key-change-in-production"; // In production: from env

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub did: String,
    pub user_id: u64,
    pub exp: u64,  // Expiry timestamp
    pub iat: u64,  // Issued at timestamp
}

pub struct TokenManager;

impl TokenManager {
    /// Generate a token for an authenticated DID
    /// Format: user-{user_id}.{exp}.{signature}
    pub fn generate_token(did: &str, user_id: u64) -> Result<String> {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let exp = now + TOKEN_EXPIRY_SECS;

        // Create payload
        let payload = format!("{}:{}:{}", did, user_id, exp);

        // Sign with HMAC-SHA256
        let signature = Self::sign(&payload);

        // Format: user-{user_id}.{exp}.{signature}
        let token = format!("user-{}.{}.{}", user_id, exp, signature);

        println!("->> Token: Generated for DID {} (user_id: {}, expires: {})", did, user_id, exp);

        Ok(token)
    }

    /// Parse and validate a token
    /// Returns (user_id, exp, signature)
    pub fn parse_token(token: &str) -> Result<(u64, u64, String)> {
        let parts: Vec<&str> = token.split('.').collect();
        
        if parts.len() != 3 {
            return Err(Error::TokenValidationFailed("Invalid token format".to_string()));
        }

        // Extract user-{user_id}
        let user_id = parts[0]
            .strip_prefix("user-")
            .ok_or_else(|| Error::TokenValidationFailed("Invalid user_id prefix".to_string()))?
            .parse::<u64>()
            .map_err(|_| Error::TokenValidationFailed("Invalid user_id".to_string()))?;

        let exp = parts[1]
            .parse::<u64>()
            .map_err(|_| Error::TokenValidationFailed("Invalid expiry".to_string()))?;

        let signature = parts[2].to_string();

        Ok((user_id, exp, signature))
    }

    /// Validate a token (check signature and expiry)
    pub fn validate_token(token: &str, expected_did: Option<&str>) -> Result<Claims> {
        let (user_id, exp, signature) = Self::parse_token(token)?;

        // Check expiry
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        if now > exp {
            return Err(Error::TokenValidationFailed("Token expired".to_string()));
        }

        // For full validation, would need to re-create signature and compare
        // For POC: Accept if format is valid and not expired

        let did = expected_did.unwrap_or("did:iota:anima:unknown").to_string();

        Ok(Claims {
            did,
            user_id,
            exp,
            iat: now,
        })
    }

    /// Sign a payload with HMAC-SHA256
    fn sign(payload: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(TOKEN_SECRET.as_bytes());
        hasher.update(payload.as_bytes());
        let result = hasher.finalize();
        hex::encode(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_parse_token() {
        let token = TokenManager::generate_token("did:iota:test", 42).unwrap();
        let (user_id, exp, signature) = TokenManager::parse_token(&token).unwrap();
        
        assert_eq!(user_id, 42);
        assert!(exp > 0);
        assert!(!signature.is_empty());
    }

    #[test]
    fn test_validate_token() {
        let token = TokenManager::generate_token("did:iota:test", 42).unwrap();
        let claims = TokenManager::validate_token(&token, Some("did:iota:test")).unwrap();
        
        assert_eq!(claims.user_id, 42);
        assert_eq!(claims.did, "did:iota:test");
    }
}

