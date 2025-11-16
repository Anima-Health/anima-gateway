#![allow(unused)]

use anyhow::Result;
use serde_json::json;

// For testing the API endpoints
#[tokio::main]
async fn main() -> Result<()> {
    let hc = httpc_test::new_client("http://localhost:8080")?;

    // Test static file
    // hc.do_get("/index.html").await?.print().await?;

    // Test authentication endpoints
    println!("\n==================== STEP 1: REQUEST CHALLENGE ====================");
    // Step 1: Request challenge nonce
    let req_challenge = hc.do_post(
        "/api/auth/challenge",
        json!({
            "did": "did:iota:anima:abc123"
        }),
    );
    let challenge_res = req_challenge.await?;
    challenge_res.print().await?;
    
    // Extract nonce from response
    let challenge_data: serde_json::Value = challenge_res.json_body()?;
    let nonce = challenge_data["nonce"].as_str()
        .ok_or_else(|| anyhow::anyhow!("No nonce in response"))?;
    
    println!("   🔑 Received nonce: {}", nonce);

    println!("\n==================== STEP 2: SIGN CHALLENGE ====================");
    // Step 2: Sign the challenge
    // Message format: "Anima Health Auth:{nonce}"
    // In real implementation, client would:
    // - Create message: "Anima Health Auth:{nonce}"
    // - Sign with DID's private key (Ed25519)
    // - Encode signature as base64/hex
    
    let message = format!("Anima Health Auth:{}", nonce);
    println!("   📝 Message to sign: {}", message);
    println!("   🔐 Signing with DID private key (mock)");
    
    // Mock signature (in production, use identity_iota to sign)
    let signature = "mock_signature_would_be_base64_encoded_ed25519_signature";

    println!("\n==================== STEP 3: LOGIN WITH SIGNED CHALLENGE ====================");
    // Step 3: Submit DID + nonce + signature
    let req_login = hc.do_post(
        "/api/login",
        json!({
            "did": "did:iota:anima:abc123",
            "nonce": nonce,
            "signature": signature,
        }),
    );
    req_login.await?.print().await?;

    println!("\n==================== CREATE PATIENTS ====================");
    // Create first patient with full demographics
    let req_create_1 = hc.do_post(
        "/api/patient",
        json!({
            "name": "John Doe",
            "date_of_birth": "1990-05-15",
            "medical_record_number": "MRN001",
            "gender": "male",
            "address": "123 Health St, London, UK"
        }),
    );
    req_create_1.await?.print().await?;

    // Create second patient
    let req_create_2 = hc.do_post(
        "/api/patient",
        json!({
            "name": "Jane Smith",
            "date_of_birth": "1985-08-22",
            "medical_record_number": "MRN002",
            "gender": "female"
        }),
    );
    req_create_2.await?.print().await?;

    // Create third patient (minimal data)
    let req_create_3 = hc.do_post(
        "/api/patient",
        json!({
            "name": "Bob Johnson",
            "date_of_birth": "1978-12-03",
            "medical_record_number": "MRN003"
        }),
    );
    req_create_3.await?.print().await?;

    println!("\n==================== CHECK PENDING ====================");
    // Check pending anchor count
    hc.do_get("/api/anchor/pending").await?.print().await?;

    println!("\n==================== CREATE ANCHOR BATCH ====================");
    // Create Merkle batch and anchor
    hc.do_post("/api/anchor/batch", json!({})).await?.print().await?;

    println!("\n==================== LIST PATIENTS ====================");
    // List all patients
    hc.do_get("/api/patient").await?.print().await?;

    println!("\n==================== TEST COMPLETE ====================");

    Ok(())
}