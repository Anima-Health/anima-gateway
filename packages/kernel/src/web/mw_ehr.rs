use axum::body::Body;
use axum::extract::{Request, State};
use axum::middleware::Next;
use axum::response::Response;
use axum::Json;
use serde_json::Value;
use crate::ctx::Ctx;
use crate::model::{Patient, PatientForCreate, ModelManager};
use crate::did_manager::DIDRegistry;
use crate::ehr::{CompositionBuilder, CompositionCategory, Entry, Observation, ObservationValue, DvText, DvCodedText};
use crate::web::{Error, Result};

#[derive(Clone)]
pub struct EHRState {
    pub mm: ModelManager,
    pub did_registry: DIDRegistry,
}

/// Middleware to organize patient data into openEHR composition before storage
/// 
/// Flow:
/// 1. Extract raw patient data from request
/// 2. Create unique DID for patient
/// 3. Build openEHR composition structure
/// 4. Store organized data in ReductStore
/// 5. Return complete patient record
pub async fn mw_ehr_organize(
    State(ehr_state): State<EHRState>,
    ctx: Ctx,
    req: Request,
) -> Result<Response> {
    println!("->> {:<12} - mw_ehr_organize", "MIDDLEWARE");

    // This middleware processes patient creation requests
    // For now, we'll handle it in the route handler directly
    // This is a placeholder for future EHR-specific middleware

    Ok(Response::new(Body::empty()))
}

/// Helper to create patient with DID and openEHR structure
pub async fn create_patient_with_ehr(
    ctx: &Ctx,
    mm: &ModelManager,
    did_registry: &DIDRegistry,
    patient_c: PatientForCreate,
) -> Result<Patient> {
    let patient_id = uuid::Uuid::new_v4().to_string();
    
    println!("->> EHR: Creating patient with ID: {}", patient_id);

    // Step 1: Create patient DID
    let patient_did = did_registry
        .create_patient_did(patient_id.clone(), ctx.user_id())
        .await
        .map_err(|e| Error::Model(crate::model::Error::SerializationError(format!("DID creation failed: {}", e))))?;

    let patient_id_clone = patient_id.clone();

    println!("   ✅ DID created: {}", patient_did.did);

    // Step 2: Build openEHR composition
    let composition_id = format!("{}_demographics_v1", patient_id);
    let archetype_id = "openEHR-EHR-COMPOSITION.person.v1";
    
    let mut composition_builder = CompositionBuilder::new(
        composition_id,
        patient_did.did.clone(),
        archetype_id,
        "Patient Demographics",
        format!("user:{}", ctx.user_id()),
    );

    // Add demographics as observations
    let demographics_obs = Observation::new(
        "Patient Demographics",
        "openEHR-EHR-OBSERVATION.demographics.v1"
    )
    .add_item("Name", ObservationValue::Text(DvText::new(&patient_c.name)))
    .add_item("Date of Birth", ObservationValue::Text(DvText::new(&patient_c.date_of_birth)))
    .add_item("MRN", ObservationValue::Text(DvText::new(&patient_c.medical_record_number)));

    // Add gender if provided
    let demographics_obs = if let Some(ref gender) = patient_c.gender {
        demographics_obs.add_item("Gender", ObservationValue::CodedText(
            DvCodedText::new(gender, "ISO_5218", gender)
        ))
    } else {
        demographics_obs
    };

    composition_builder = composition_builder
        .category(CompositionCategory::Persistent)
        .add_entry(Entry::Observation(demographics_obs));

    // Add address if provided
    if let Some(ref address) = patient_c.address {
        let address_obs = Observation::new(
            "Address",
            "openEHR-EHR-OBSERVATION.address.v1"
        )
        .add_item("Full Address", ObservationValue::Text(DvText::new(address)));

        composition_builder = composition_builder.add_entry(Entry::Observation(address_obs));
    }

    let composition = composition_builder.build();

    println!("   ✅ openEHR composition built (category: {:?})", composition.category);

    // Step 3: Create complete patient record
    let patient = Patient {
        id: patient_id_clone.clone(),
        did: patient_did.did.clone(),
        demographics: crate::model::PatientDemographics {
            name: patient_c.name,
            date_of_birth: patient_c.date_of_birth,
            medical_record_number: patient_c.medical_record_number,
            gender: patient_c.gender,
            address: patient_c.address,
        },
        composition,
        did_metadata: patient_did,
        created_at: chrono::Utc::now(),
        created_by: ctx.user_id(),
    };

    println!("   ✅ Patient record structured");

    // Step 4: Store in ReductStore
    mm.store_patient(&patient).await
        .map_err(|e| Error::Model(e))?;

    println!("   ✅ Stored in ReductStore");
    println!("   📊 Patient {} ready for anchoring", patient.id);

    Ok(patient)
}

