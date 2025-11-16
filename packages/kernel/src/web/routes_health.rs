use axum::{Json, Router, routing::get};
use serde_json::{json, Value};

pub fn routes() -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/api/info", get(api_info))
}

/// Health check endpoint for load balancers and monitoring
async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "healthy",
        "service": "anima-health-kernel",
        "version": env!("CARGO_PKG_VERSION"),
    }))
}

/// API information endpoint
async fn api_info() -> Json<Value> {
    Json(json!({
        "name": "Anima Health Kernel API",
        "version": env!("CARGO_PKG_VERSION"),
        "description": "Privacy-preserving healthcare data provenance with IOTA",
        "features": {
            "iota_did_auth": true,
            "openehr_compositions": true,
            "merkle_anchoring": true,
            "reductstore_integration": true
        },
        "endpoints": {
            "auth": [
                "POST /api/auth/challenge - Request authentication challenge",
                "POST /api/login - Submit signed challenge"
            ],
            "patients": [
                "POST /api/patient - Create patient with DID and openEHR",
                "GET /api/patient - List all patients",
                "GET /api/patient/:id - Get patient by ID",
                "DELETE /api/patient/:id - Delete patient"
            ],
            "anchoring": [
                "POST /api/anchor/batch - Create Merkle batch and anchor",
                "GET /api/anchor/pending - Get pending anchor count"
            ]
        },
        "iota": {
            "did_method": "did:iota:anima",
            "testnet": "https://api.testnet.iotaledger.net",
            "explorer": "https://explorer.iota.org/testnet/",
            "smart_contracts": 5
        }
    }))
}

