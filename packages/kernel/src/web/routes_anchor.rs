use crate::ctx::Ctx;
use crate::model::{ModelManager, AnchorService};
use crate::web::{Error, Result};
use axum::Json;
use axum::extract::State;
use axum::Router;
use axum::routing::{post, get};
use serde_json::{json, Value};

pub fn routes(mm: ModelManager) -> Router {
    Router::new()
        .route("/anchor/batch", post(create_batch))
        .route("/anchor/pending", get(pending_count))
        .with_state(mm)
}

/// Create a Merkle batch from pending records and get anchor info
async fn create_batch(
    State(mm): State<ModelManager>,
    _ctx: Ctx,
) -> Result<Json<Value>> {
    println!("->> {:<12} - create_batch", "HANDLER");

    let batch = AnchorService::create_batch(&mm)
        .await
        .map_err(|e| Error::Model(e))?;

    match batch {
        Some(batch) => {
            // In production, this would anchor to blockchain
            let tx_hash = AnchorService::anchor_to_blockchain(&batch)
                .await
                .map_err(|e| Error::Model(e))?;

            Ok(Json(json!({
                "success": true,
                "batch": batch,
                "tx_hash": tx_hash,
                "message": "Batch created and anchored"
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

