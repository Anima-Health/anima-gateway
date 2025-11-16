use axum::{handler::HandlerWithoutStateExt, http::StatusCode, routing::MethodRouter};
use tower_http::services::ServeDir;
use axum::routing::{any_service};

const STATIC_DIR: &str = "web-folder";

pub fn serve_dir() -> MethodRouter {
    async fn handle_404() -> (StatusCode, &'static str) {
        (StatusCode::NOT_FOUND, "404 Not Found")
    }

    any_service(
        ServeDir::new(STATIC_DIR).not_found_service(handle_404.into_service())
    )
}