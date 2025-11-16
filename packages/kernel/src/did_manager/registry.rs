use crate::did_manager::{Error, Result, PatientDID};
use std::collections::HashMap;
use tokio::sync::RwLock;
use std::sync::Arc;

/// Registry for managing patient DIDs
pub struct DIDRegistry {
    // patient_id -> PatientDID
    patient_dids: Arc<RwLock<HashMap<String, PatientDID>>>,
    // did -> patient_id (reverse index)
    did_to_patient: Arc<RwLock<HashMap<String, String>>>,
}

impl DIDRegistry {
    pub fn new() -> Self {
        Self {
            patient_dids: Arc::new(RwLock::new(HashMap::new())),
            did_to_patient: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Create and register a new patient DID
    pub async fn create_patient_did(&self, patient_id: String, created_by: u64) -> Result<PatientDID> {
        // Check if patient already has a DID
        {
            let registry = self.patient_dids.read().await;
            if registry.contains_key(&patient_id) {
                return Err(Error::DIDAlreadyExists(patient_id));
            }
        }

        // Create new DID
        let patient_did = PatientDID::create(patient_id.clone(), created_by)?;

        // Store in registry
        {
            let mut registry = self.patient_dids.write().await;
            registry.insert(patient_id.clone(), patient_did.clone());
        }

        // Update reverse index
        {
            let mut index = self.did_to_patient.write().await;
            index.insert(patient_did.did.clone(), patient_id.clone());
        }

        println!("->> DIDRegistry: Registered DID {} for patient {}", 
                 patient_did.did, patient_id);

        Ok(patient_did)
    }

    /// Get patient DID by patient_id
    pub async fn get_by_patient_id(&self, patient_id: &str) -> Result<PatientDID> {
        let registry = self.patient_dids.read().await;
        registry.get(patient_id)
            .cloned()
            .ok_or_else(|| Error::DIDNotFound(patient_id.to_string()))
    }

    /// Get patient DID by DID string
    pub async fn get_by_did(&self, did: &str) -> Result<PatientDID> {
        let index = self.did_to_patient.read().await;
        let patient_id = index.get(did)
            .ok_or_else(|| Error::DIDNotFound(did.to_string()))?;

        self.get_by_patient_id(patient_id).await
    }

    /// Update existing DID (for key rotation)
    pub async fn update_did(&self, patient_did: PatientDID) -> Result<()> {
        let mut registry = self.patient_dids.write().await;
        registry.insert(patient_did.patient_id.clone(), patient_did);
        Ok(())
    }

    /// List all patient DIDs
    pub async fn list_all(&self) -> Vec<PatientDID> {
        let registry = self.patient_dids.read().await;
        registry.values().cloned().collect()
    }

    /// Get count of registered DIDs
    pub async fn count(&self) -> usize {
        let registry = self.patient_dids.read().await;
        registry.len()
    }
}

impl Clone for DIDRegistry {
    fn clone(&self) -> Self {
        Self {
            patient_dids: Arc::clone(&self.patient_dids),
            did_to_patient: Arc::clone(&self.did_to_patient),
        }
    }
}

