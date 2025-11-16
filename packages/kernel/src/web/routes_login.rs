use crate::web::{Error, Result};
use crate::auth::{ChallengeStore, DIDResolver, TokenManager};
use serde::{Deserialize, Serialize};
use axum::{Json, Router, routing::post, extract::State};
use axum_extra::extract::cookie::{Cookie, CookieJar};
use serde_json::{Value, json};
use crate::web;

#[derive(Clone)]
pub struct AuthState {
    pub challenge_store: ChallengeStore,
    pub did_resolver: DIDResolver,
}

pub fn routes(auth_state: AuthState) -> Router {
    Router::new()
        .route("/api/auth/challenge", post(request_challenge))
        .route("/api/login", post(api_login))
        .with_state(auth_state)
}

// ==================== Step 1: Request Challenge ====================

/// Client requests a challenge nonce for DID authentication
async fn request_challenge(
    State(auth_state): State<AuthState>,
    Json(payload): Json<ChallengeRequest>,
) -> Result<Json<ChallengeResponse>> {
    println!("->> {:<12} - request_challenge", "HANDLER");

    // Generate challenge nonce (expires in 5 minutes)
    let challenge = auth_state.challenge_store.create_challenge(payload.did).await;

    let response = ChallengeResponse {
        nonce: challenge.nonce,
        expires_at: challenge.expires_at,
    };

    Ok(Json(response))
}

// ==================== Step 2: Login with Signed Challenge ====================

/// Client submits DID + signed challenge for authentication
async fn api_login(
    State(auth_state): State<AuthState>,
    jar: CookieJar,
    Json(payload): Json<LoginPayload>,
) -> Result<(CookieJar, Json<Value>)> {
    println!("->> {:<12} - api_login - DID: {}", "HANDLER", payload.did);

    // Step 1: Verify the challenge hasn't expired
    let challenge = auth_state.challenge_store
        .verify_and_consume(&payload.nonce)
        .await
        .map_err(|e| Error::AuthFail(format!("Challenge verification failed: {}", e)))?;

    println!("   ✅ Challenge verified");

    // Step 2: Resolve DID document from IOTA Tangle
    let _did_doc = auth_state.did_resolver
        .resolve(&payload.did)
        .await
        .map_err(|e| Error::AuthFail(format!("DID resolution failed: {}", e)))?;

    println!("   ✅ DID document resolved");

    // Step 3: Verify signature against DID's public key
    // Message format: "Anima Health Auth:{nonce}"
    let message = format!("Anima Health Auth:{}", payload.nonce);
    
    let signature_valid = auth_state.did_resolver
        .verify_signature(&payload.did, &message, &payload.signature)
        .await
        .map_err(|e| Error::AuthFail(format!("Signature verification failed: {}", e)))?;

    if !signature_valid {
        return Err(Error::AuthFail("Invalid signature".to_string()));
    }

    println!("   ✅ Signature verified");

    // Step 4: Generate access token (JWT-like)
    // For POC: Simple user_id mapping (in production: lookup from DID registry)
    let user_id = did_to_user_id(&payload.did);

    let token = TokenManager::generate_token(&payload.did, user_id)
        .map_err(|e| Error::AuthFail(format!("Token generation failed: {}", e)))?;

    println!("   ✅ Access token generated");

    // Step 5: Set cookie with token
    let jar = jar.add(Cookie::new(web::AUTH_TOKEN, token));

    // Success response
    let body = Json(json!({
        "success": true,
        "user_id": user_id,
        "did": payload.did,
        "message": "Authentication successful"
    }));

    Ok((jar, body))
}

/// Map DID to user_id (for POC - in production would query did_role_registry contract)
fn did_to_user_id(did: &str) -> u64 {
    // Simple hash-based mapping for POC
    // In production: Call did_role_registry::get_did_accounts()
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    
    let mut hasher = DefaultHasher::new();
    did.hash(&mut hasher);
    let hash = hasher.finish();
    
    // Convert to user_id (ensure not 0 for root_ctx protection)
    (hash % 1_000_000) + 1
}

// ==================== Request/Response Structures ====================

#[derive(Debug, Deserialize)]
pub struct ChallengeRequest {
    /// Optional DID of the caller (for logging/tracking)
    pub did: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ChallengeResponse {
    /// Random nonce to be signed by the client
    pub nonce: String,
    /// Unix timestamp when challenge expires
    pub expires_at: u64,
}

#[derive(Debug, Deserialize)]
pub struct LoginPayload {
    /// DID of the caller, e.g. "did:iota:anima:abc123"
    pub did: String,
    /// The nonce received from /api/auth/challenge
    pub nonce: String,
    /// Signature over the message "Anima Health Auth:{nonce}"
    /// Signed with the DID's private key
    pub signature: String,
}
