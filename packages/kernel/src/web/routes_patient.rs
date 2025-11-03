use crate::model::{ModelController, PatientForCreate, Patient};
use crate::Result;
use axum::Json;
use axum::extract::{State, Path};
use axum::Router;
use axum::routing::{post, delete};
use axum::extract::FromRef;

#[derive(Clone, FromRef)]
struct AppState {
    mc: ModelController,
}

pub fn routes(mc: ModelController) -> Router {
    let app_state = AppState { mc };
    Router::new()
        .route("/patient", post(create_patient))
        .route("/patient/:id", delete(delete_patient))
        .with_state(app_state)
}

async fn create_patient(
    State(mc): State<ModelController>,
    Json(patient): Json<PatientForCreate>,
) -> Result<Json<Patient>> {
    println!("->> {:<12} - create_patient", "HANDLER");

    let patient = mc.create_patient(patient).await?;

    Ok(Json(patient))
}

async fn delete_patient(
    State(mc): State<ModelController>,
    Path(id): Path<u64>,
) -> Result<Json<Patient>> {
    println!("->> {:<12} - delete_patient", "HANDLER");

    let patient = mc.delete_patient(id).await?;

    Ok(Json(patient))
}