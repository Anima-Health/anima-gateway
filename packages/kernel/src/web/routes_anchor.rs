use crate::ctx::Ctx;
use crate::model::{ModelManager, AnchorService, verify_proof};
use crate::web::{Error, Result};
use axum::Json;
use axum::extract::{State, Path};
use axum::Router;
use axum::routing::{post, get};
use serde_json::{json, Value};

pub fn routes(mm: ModelManager) -> Router {
    Router::new()
        .route("/anchor/batch", post(create_batch))
        .route("/anchor/pending", get(pending_count))
        .route("/anchor/verify/:patient_id", get(verify_patient))
        .with_state(mm)
}

/// Create a Merkle batch from pending records and get anchor info
async fn create_batch(
    State(mm): State<ModelManager>,
    _ctx: Ctx,
) -> Result<Json<Value>> {
    println!("->> {:<12} - create_batch", "HANDLER");

    let result = AnchorService::create_batch(&mm)
        .await
        .map_err(|e| Error::Model(e))?;

    match result {
        Some((batch, patient_ids)) => {
            // Anchor to IOTA blockchain using deployed smart contract
            let tx_hash = AnchorService::anchor_to_blockchain(&mm, &batch)
                .await
                .map_err(|e| Error::Model(e))?;
            
            // Store the batch for proof generation
            mm.store_anchored_batch(batch.clone(), patient_ids.clone()).await;

            Ok(Json(json!({
                "success": true,
                "batch": batch,
                "tx_hash": tx_hash,
                "patient_ids": patient_ids,
                "message": "Batch created and anchored to IOTA"
            })))
        }
        None => {
            Ok(Json(json!({
                "success": false,
                "message": "No pending records to anchor"
            })))
        }
    }
}

/// Get count of pending records waiting to be anchored
async fn pending_count(
    State(mm): State<ModelManager>,
    _ctx: Ctx,
) -> Result<Json<Value>> {
    println!("->> {:<12} - pending_count", "HANDLER");

    let count = AnchorService::pending_count(&mm).await;

    Ok(Json(json!({
        "pending_count": count
    })))
}

/// Verify a patient record using Merkle proof
async fn verify_patient(
    State(mm): State<ModelManager>,
    Path(patient_id): Path<String>,
    _ctx: Ctx,
) -> Result<Json<Value>> {
    println!("->> {:<12} - verify_patient: {}", "HANDLER", patient_id);

    // Generate Merkle proof for this patient
    let proof = mm.generate_merkle_proof(&patient_id)
        .await
        .map_err(|e| Error::Model(e))?;

    match proof {
        Some(proof) => {
            // Verify the proof
            let is_valid = verify_proof(&proof);
            
            println!("    Proof generated for patient {}", patient_id);
            println!("    Root hash: {}", proof.root_hash);
            println!("    Proof valid: {}", is_valid);

            Ok(Json(json!({
                "success": true,
                "patient_id": patient_id,
                "proof": proof,
                "verified": is_valid,
                "message": if is_valid { 
                    "Patient record cryptographically verified in Merkle tree" 
                } else { 
                    "Verification failed - data may have been tampered with" 
                }
            })))
        }
        None => {
            Ok(Json(json!({
                "success": false,
                "message": "Patient not found in any anchored batch. Create a batch first."
            })))
        }
    }
}

