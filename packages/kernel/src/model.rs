


use crate::{Error, Result};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
// use reduct_rs::ReductClient;s
// use std::time::Duration;

#[derive(Clone, Debug, Serialize)]
pub struct Patient {
    pub id: u64,
    pub name: String,
}

pub struct PatientForCreate {
    pub name: String,
}

#[derive(Clone)]
pub struct ModelController {
    patient_store: Arc<Mutex<Vec<Option<Patient>>>>,
}

impl ModelController {
    pub async fn new() -> Result<Self> {
        Ok(Self { 
            patient_store: Arc::default(),
        })
    }
}

impl ModelController {
    pub async fn create_patient(&self, patient: PatientForCreate) -> Result<Patient> {

        let mut store = self.patient_store.lock().unwrap();

        let id = store.len() as u64 + 1;
        let patient = Patient {
            id,
            name: patient.name,
        };

        store.push(Some(patient.clone()));

        Ok(patient)
    }

    // pub async fn delete_patient(&self, id: u64) -> Result<Patient> {
    //     let mut store = self.patient_store.lock().unwrap();

    //     let patient = store.get_mut(id as usize).and_then(|t| t.take());

    //     Ok()
    // }
}