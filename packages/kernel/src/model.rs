


use crate::{Error, Result, ctx::Ctx};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
// use reduct_rs::ReductClient;s
// use std::time::Duration;

#[derive(Clone, Debug, Serialize)]
pub struct Patient {
    pub id: u64,
    pub cid: u64,
    pub name: String,
}

#[derive(Deserialize)]
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
    pub async fn create_patient(&self, ctx: Ctx, patient: PatientForCreate) -> Result<Patient> {

        let mut store = self.patient_store.lock().unwrap();

        let id = store.len() as u64 + 1;
        let patient = Patient {
            id,
            cid: ctx.user_id(),
            name: patient.name,
        };

        store.push(Some(patient.clone()));

        Ok(patient)
    }

    pub async fn delete_patient(&self, _ctx: Ctx, id: u64) -> Result<Patient> {
        let mut store = self.patient_store.lock().unwrap();

        let patient = store.get_mut(id as usize).and_then(|t| t.take());

        patient.ok_or(Error::PatientDeleteFailNotFound { id })
    }
}