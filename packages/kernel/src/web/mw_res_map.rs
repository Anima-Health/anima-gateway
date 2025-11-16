use axum::Json;
use axum::http::Uri;
use crate::ctx::Ctx;
use crate::web;
use axum::http::Method;
use axum::response::{Response, IntoResponse};
use uuid::Uuid;
use serde_json::json;
use crate::log::log_request;

pub async fn mw_reponse_map(
    ctx: Option<Ctx>, 
    uri: Uri, 
    req_method: Method, 
    res: Response,
) -> Response {
    println!("->> {:<12} - main_response_mapper", "MIDDLEWARE");
    let uuid = Uuid::new_v4();


    let web_error = res.extensions().get::<web::Error>();
    let client_status_error = web_error.map(|se| se.client_status_and_error());

    let error_response = client_status_error
        .as_ref()
        .map(|(status_code, client_error)| {
            let client_error_body = json!({
                "error": {
                    "type": client_error.as_ref(),
                    "req_uuid": uuid.to_string(),
                }
            });
            println!("     ->> client_error_body: {client_error_body}");

            (*status_code, Json(client_error_body)).into_response()
        });

    let client_error = client_status_error.unzip().1;

    let _ = log_request(
        uuid,
        req_method.to_string(),
        uri,
        ctx,
        web_error,
        client_error,
    )
    .await;

    println!();
    error_response.unwrap_or(res)
}
