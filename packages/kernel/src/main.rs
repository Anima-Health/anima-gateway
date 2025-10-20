use axum::{
    routing::{get, get_service},
    Router,
    response::Html,
    response::IntoResponse,
    extract::Query,
};
use std::net::SocketAddr;
use serde::Deserialize;
use tower_http::services::ServeDir;

#[tokio::main]
async fn main() {
    // build our application with a single route
    let routes_all = Router::new()
        .merge(routes_hello())
        .fallback_service(routes_static());

    fn routes_hello() -> Router {
        Router::new()
            .route("/hello", get(handler_hello))
    }

    fn routes_static() -> Router {
        Router::new().nest_service("/", get_service(ServeDir::new("./")))
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
    let addr: SocketAddr = "0.0.0.0:8080".parse().unwrap();
    println!("->> Listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, routes_all)
        .await
        .unwrap();
}