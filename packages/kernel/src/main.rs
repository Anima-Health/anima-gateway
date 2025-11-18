use axum::body::Body;
use axum::{
    Router,
    middleware,
};
use tower_cookies::CookieManagerLayer;
use std::net::SocketAddr;
use tokio;
use envie::Envie;

// use crate::{ctx::Ctx, log::log_request};
use crate::web::{mw_res_map::mw_reponse_map, routes_login, routes_patient, routes_anchor, routes_health, routes_static};
use crate::web::mw_auth::mw_ctx_resolve;
use crate::model::ModelManager;

pub use self::error::{Error, Result};

mod error;
mod web;
mod model;
mod ctx;
mod log;
mod auth;
mod did_manager;
mod ehr;
mod blockchain;

#[tokio::main]
async fn main() -> Result<()> {

    let mm = ModelManager::new().await?;
    
    // Initialize DID registry for patient DIDs
    let did_registry = crate::did_manager::DIDRegistry::new();
    
    // Initialize auth system
    let auth_state = routes_login::AuthState {
        challenge_store: crate::auth::ChallengeStore::new(),
        did_resolver: crate::auth::DIDResolver::new(),
    };
    
    // Load environment variables
    let env = Envie::load().expect("Failed to load .env file");

    let port = env.get_int("PORT").unwrap_or(8080);
    let _db_token = env.get("REDUCT_TOKEN").unwrap_or("".to_string());

    let routes_apis = Router::new()
        .merge(routes_patient::routes(mm.clone(), did_registry.clone()))
        .merge(routes_anchor::routes(mm.clone()))
        .route_layer(middleware::from_fn(web::mw_auth::mw_ctx_require::<Body>));

    // Build complete application with all routes
    let routes_all = Router::new()
        .merge(routes_health::routes())  // Health check (no auth required)
        .merge(routes_login::routes(auth_state))
        .nest("/api", routes_apis)
        .layer(middleware::map_response(mw_reponse_map))
        .layer(CookieManagerLayer::new())
        .layer(middleware::from_fn_with_state(
                mm.clone(), mw_ctx_resolve::<Body>
            ))
        .fallback_service(routes_static::serve_dir());
    
    println!("✅ IOTA DID authentication enabled");
    println!("✅ openEHR compositions enabled");
    println!("✅ Merkle anchoring enabled");
    println!("✅ ReductStore integration ready");
    println!("✅ Welcome to Anima");


    // Initialize the Reduct client
    // let client = ReductClient::builder()
    //     .url("http://127.0.0.1:8383")
    //     .api_token(&db_token.to_string())
    //     .build();

    // let store = model::ModelController::new(Arc::new(client));

    // run our app with hyper, listening globally on port 3000
    let addr: SocketAddr = format!("127.0.0.1:{}", port).parse().unwrap();
    println!("->> Listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, routes_all)
        .await
        .unwrap();

    Ok(())
}