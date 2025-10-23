use crate::{Error, Result};
use serde::{Deserialize, Serialize};
use axum::{Json, Router, routing::post};
use axum_extra::extract::cookie::{Cookie, CookieJar};
use serde_json::{Value, json};
use uuid::Uuid;
use std::time::{SystemTime, UNIX_EPOCH};
use crate::web;

pub fn routes() -> Router {
    Router::new().route("/api/login", post(api_login))
}


// Maybe this part is issued by the issuing authority
async fn init_login(payload: Json<ChallengeRequest>) -> Result<Json<ChallengeResponse>> {
    println!("->> {:<12} - init_login", "HANDLER");

    // Mock nonce generation
    let nonce = Uuid::new_v4().to_string();
    let expires_at = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() + 60 * 5;

    let response = ChallengeResponse { nonce, expires_at };

    Ok(Json(response))
}

async fn api_login(jar: CookieJar, payload: Json<LoginPayload>) -> Result<(CookieJar, Json<Value>)> {
    println!("->> {:<12} - api_login", "HANDLER");


    // Todo: Implement the login logic
    if payload.did != "did:iota:anima:abc123" {
        return Err(Error::LoginFail);
    }

    // Todo: Verify the signature and set cookie if successful
    let jar = jar.add(Cookie::new(web::AUTH_TOKEN, "user-1.exp.sign"));

    // Create success body
    let body = Json(json!({
        "result": {
            "success": true,
        }
    }));

    Ok((jar, body))
}

#[derive(Debug, Deserialize)]
struct ChallengeRequest {
    // DID of the caller should be optional
    pub did: Option<String>,
}


#[derive(Debug, Serialize)]
struct ChallengeResponse {
    pub nonce: String,
    pub expires_at: u64,
}

// Todo: Need to refactor this payload struct in future
#[derive(Debug, Deserialize)]
struct LoginPayload {
    /// DID of the caller, e.g. "did:iota:anima:abc123"
    pub did: String,
    /// Base64url of the server-issued challenge
    pub nonce: String,
    /// Base64url signature over message
    pub signature: String,
}