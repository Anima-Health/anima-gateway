use crate::ctx::Ctx;
use crate::model::Result;
use crate::did_manager::PatientDID;
use crate::ehr::Composition;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

/// Patient record with DID and openEHR composition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Patient {
    /// Unique patient identifier (UUID)
    pub id: String,
    
    /// Patient's unique DID: did:iota:anima:{id}
    pub did: String,
    
    /// Demographics
    pub demographics: PatientDemographics,
    
    /// openEHR composition (clinical data organized)
    pub composition: Composition,
    
    /// DID metadata (keys, version, status)
    pub did_metadata: PatientDID,
    
    /// Audit trail
    pub created_at: DateTime<Utc>,
    pub created_by: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatientDemographics {
    pub name: String,
    pub date_of_birth: String,
    pub medical_record_number: String,
    pub gender: Option<String>,
    pub address: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct PatientForCreate {
    pub name: String,
    pub date_of_birth: String,
    pub medical_record_number: String,
    pub gender: Option<String>,
    pub address: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct PatientForUpdate {
    pub name: Option<String>,
    pub date_of_birth: Option<String>,
    pub gender: Option<String>,
    pub address: Option<String>,
}

/// PatientBmc (Backend Model Controller)
pub struct PatientBmc;

impl PatientBmc {
    pub async fn create(
        ctx: &Ctx, 
        mm: &crate::model::ModelManager, 
        patient_c: PatientForCreate
    ) -> Result<Patient> {
        // This will be handled by the EHR middleware
        // The middleware will:
        // 1. Create patient DID
        // 2. Build openEHR composition
        // 3. Organize data properly
        // 4. Then store in ReductStore
        
        // This function should not be called directly
        // Use the middleware-processed request instead
        unimplemented!("Use EHR middleware for patient creation")
    }

    pub async fn get(_ctx: &Ctx, mm: &crate::model::ModelManager, id: &str) -> Result<Patient> {
        mm.get_patient(id).await
    }

    pub async fn list(_ctx: &Ctx, mm: &crate::model::ModelManager) -> Result<Vec<Patient>> {
        mm.list_patients().await
    }

    pub async fn delete(_ctx: &Ctx, mm: &crate::model::ModelManager, id: &str) -> Result<Patient> {
        let patient = Self::get(_ctx, mm, id).await?;
        mm.delete_patient(id).await?;
        Ok(patient)
    }
}
