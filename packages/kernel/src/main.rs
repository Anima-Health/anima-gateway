use axum::{
    routing::{get, get_service},
    Router,
    response::Html,
    response::IntoResponse,
    extract::Query,
    response::Response,
    middleware,
};
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


pub use self::error::{Error, Result};

mod error;
mod web;
mod model;

#[tokio::main]
async fn main() {
    // Load environment variables
    let mut env = Envie::load().expect("Failed to load .env file");

    let port = env.get_int("PORT").unwrap_or(8080);
    let db_token = env.get("REDUCT_TOKEN").expect("TOKEN is not set");

    // build our application with a single route
    let routes_all = Router::new()
        .merge(routes_hello())
        .merge(web::routes_login::routes())
        .layer(middleware::map_response(main_response_mapper))
        // .layer(CookieManagerLayer::new())
        .fallback_service(routes_static());

    fn routes_hello() -> Router {
        Router::new()
            .route("/hello", get(handler_hello))
    }

    fn routes_static() -> Router {
        Router::new().nest_service("/", get_service(ServeDir::new("./")))
    }

    // Initialize the Reduct client
    let client = ReductClient::builder()
        .url("http://127.0.0.1:8383")
        .api_token(&db_token.to_string())
        .build();

    // let store = model::ModelController::new(Arc::new(client));


    async fn main_response_mapper(res: Response) -> Response {
        println!("->> {:<12} - main_response_mapper", "MIDDLEWARE");

        println!();
        res
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
}