use axum::{
    Json, Router, extract::{Query, Request}, http::{Uri, Method}, middleware::{self, Next}, response::{Html, IntoResponse, Response}, routing::{get, get_service}
};
use tower_cookies::service;
use uuid::Uuid;
use std::net::SocketAddr;
use serde::Deserialize;
use tower_http::services::ServeDir;
use futures_util::stream::StreamExt;
use reduct_rs::{condition, QuotaType, ReductClient, ReductError};
use std::pin::pin;
use std::time::{Duration, SystemTime};
use tokio;
use envie::Envie;
use std::sync::Arc;
use axum::body::Body;
use serde_json::{Value, json};

use crate::{ctx::Ctx, log::log_request};

pub use self::error::{Error, Result};

mod error;
mod web;
mod model;
mod ctx;
mod log;

#[tokio::main]
async fn main() -> Result<()> {

    let mc = model::ModelController::new().await?;
    // Load environment variables
    let mut env = Envie::load().expect("Failed to load .env file");

    let port = env.get_int("PORT").unwrap_or(8080);
    let db_token = env.get("REDUCT_TOKEN").expect("TOKEN is not set");

    // let routes_apis = web::routes_patient::routes(mc.clone())
    //     .route_layer(middleware::from_fn(web::mw_auth::mw_require_auth::<Body>));

    // build our application with a single route
    let routes_all = Router::new()
        // .merge(routes_hello())
        .merge(web::routes_login::routes())
        // .nest("/api", routes_apis)
        .layer(middleware::from_fn(main_response_mapper))
        .layer(middleware::from_fn_with_state(
            mc,
            web::mw_auth::mw_ctx_resolver::<Body>
        ))
        // .layer(CookieManagerLayer::new())
        .fallback_service(routes_static());

    // fn routes_hello() -> Router {
    //     Router::new()
    //         .route("/hello", get(handler_hello))
    // }

    fn routes_static() -> Router {
        Router::new().nest_service("/", get_service(ServeDir::new("./")))
    }

    // Initialize the Reduct client
    // let client = ReductClient::builder()
    //     .url("http://127.0.0.1:8383")
    //     .api_token(&db_token.to_string())
    //     .build();

    // let store = model::ModelController::new(Arc::new(client));


    async fn main_response_mapper(
        ctx: Option<Ctx>,
        uri: Uri,
        req: Request,
        next: Next,
    ) -> Response {
        println!("->> {:<12} - main_response_mapper", "MIDDLEWARE");
        let uuid = Uuid::new_v4();
        
        let req_method = req.method().clone();

        let res = next.run(req).await;

        let service_error = res.extensions().get::<Error>();
        let client_status_error = service_error.map(|se| se.client_status_and_error());


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
        let _ = log_request(uuid, req_method.to_string(), uri, ctx, service_error, client_error).await;



        println!();
        error_response.unwrap_or(res)
    }

    #[derive(Debug, Deserialize)]
    struct HelloParams {
        name: Option<String>,
    }

    async fn handler_hello(Query(params): Query<HelloParams>) -> impl IntoResponse {
        println!("->> {:<12} - handler_hello", "HANDLER");

        let name = params.name.as_deref().unwrap_or("World");

        Html(format!("Hello, {name}!"))
    }

    // run our app with hyper, listening globally on port 3000
    let addr: SocketAddr = format!("0.0.0.0:{}", port).parse().unwrap();
    println!("->> Listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, routes_all)
        .await
        .unwrap();

    Ok(())
}