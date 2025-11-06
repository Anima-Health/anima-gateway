use crate::{Error, Result, ctx::Ctx, error::ClientError};
use axum::http::Uri;
use serde::Serialize;
use serde_json::{Value, json};
use serde_with::skip_serializing_none;
use chrono::prelude::*;
use uuid::Uuid;


pub async fn log_request(
    uuid: Uuid,
    req_method: String,
    url: Uri,
    ctx: Option<Ctx>,
    service_error: Option<&Error>,
    client_error: Option<ClientError>,
) -> Result<()> {
    let error_type = service_error.map(|e| e.as_ref().to_string());
    let error_data = serde_json::to_value(service_error)
        .ok()
        .and_then(|mut v| v.get_mut("data").map(|v| v.take()));


    let log_line = RequestLogLine {
        uuid: uuid.to_string(),
        timestamp: Utc::now().to_string(),
        user_id: ctx.map(|c| c.user_id()),
        req_path: url.path().to_string(),
        req_method: req_method,
        client_error_type: client_error.map(|e| e.as_ref().to_string()),
        error_type,
        error_data,
    };

    // Integrate with CloudWatch Logs and Reduct

    println!("  ->> log_request: \n{}", json!(log_line));

    Ok(())
}

#[skip_serializing_none]
#[derive(Serialize)]
struct RequestLogLine {
    uuid: String,
    timestamp: String, // ISO 8601 format
    user_id: Option<u64>,
    
    req_path: String,
    req_method: String,
    
    client_error_type: Option<String>,
    error_type: Option<String>,
    error_data: Option<Value>,
}