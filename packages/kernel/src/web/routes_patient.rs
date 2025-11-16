use crate::ctx::Ctx;
use crate::model::{ModelManager, PatientBmc, PatientForCreate, Patient};
use crate::did_manager::DIDRegistry;
use crate::web::{Error, Result, mw_ehr};
use axum::Json;
use axum::extract::{State, Path};
use axum::Router;
use axum::routing::{post, get, delete};

#[derive(Clone)]
pub struct PatientState {
    pub mm: ModelManager,
    pub did_registry: DIDRegistry,
}

pub fn routes(mm: ModelManager, did_registry: DIDRegistry) -> Router {
    let state = PatientState { mm, did_registry };
    
    Router::new()
        .route("/patient", post(create_patient))
        .route("/patient", get(list_patients))
        .route("/patient/:id", get(get_patient))
        .route("/patient/:id", delete(delete_patient))
        .with_state(state)
}

/// Create patient with DID and openEHR composition
async fn create_patient(
    State(state): State<PatientState>,
    ctx: Ctx,
    Json(patient_c): Json<PatientForCreate>,
) -> Result<Json<Patient>> {
    println!("->> {:<12} - create_patient", "HANDLER");
    println!("   📝 Name: {}", patient_c.name);
    println!("   🎂 DOB: {}", patient_c.date_of_birth);
    println!("   🏥 MRN: {}", patient_c.medical_record_number);

    // Use EHR helper to create patient with DID + openEHR structure
    let patient = mw_ehr::create_patient_with_ehr(
        &ctx,
        &state.mm,
        &state.did_registry,
        patient_c,
    ).await?;

    println!("   ✅ Patient created successfully");
    println!("   🆔 Patient ID: {}", patient.id);
    println!("   🔗 DID: {}", patient.did);

    Ok(Json(patient))
}

async fn get_patient(
    State(state): State<PatientState>,
    ctx: Ctx,
    Path(id): Path<String>,
) -> Result<Json<Patient>> {
    println!("->> {:<12} - get_patient - {id}", "HANDLER");

    let patient = PatientBmc::get(&ctx, &state.mm, &id)
        .await
        .map_err(|e| Error::Model(e))?;

    Ok(Json(patient))
}

async fn list_patients(
    State(state): State<PatientState>,
    ctx: Ctx,
) -> Result<Json<Vec<Patient>>> {
    println!("->> {:<12} - list_patients", "HANDLER");

    let patients = PatientBmc::list(&ctx, &state.mm)
        .await
        .map_err(|e| Error::Model(e))?;

    Ok(Json(patients))
}

async fn delete_patient(
    State(state): State<PatientState>,
    ctx: Ctx,
    Path(id): Path<String>,
) -> Result<Json<Patient>> {
    println!("->> {:<12} - delete_patient - {id}", "HANDLER");

    let patient = PatientBmc::delete(&ctx, &state.mm, &id)
        .await
        .map_err(|e| Error::Model(e))?;

    Ok(Json(patient))
}
