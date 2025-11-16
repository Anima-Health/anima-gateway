use crate::model::{Error, Result, Patient};
use reduct_rs::ReductClient;
use std::collections::HashMap;
use tokio::sync::RwLock;
use std::sync::Arc;

const BUCKET_NAME: &str = "anima-patients";
const ENTRY_NAME: &str = "patient-records";

pub struct ReductStore {
    client: Option<ReductClient>,
    // For POC: in-memory storage (fallback when ReductStore unavailable)
    // Maps patient_id -> (patient_data, timestamp)
    in_memory_store: Arc<RwLock<HashMap<String, (Patient, u64)>>>,
    use_memory_fallback: bool,
}

impl ReductStore {
    pub async fn new(url: &str, api_token: Option<&str>) -> Result<Self> {
        let mut builder = ReductClient::builder().url(url);
        
        if let Some(token) = api_token {
            builder = builder.api_token(token);
        }

        let client = builder.build();

        // Try to connect to ReductStore
        let store = Self { 
            client: Some(client),
            in_memory_store: Arc::new(RwLock::new(HashMap::new())),
            use_memory_fallback: false,
        };

        match store.ensure_bucket().await {
            Ok(_) => {
                println!("✅ ReductStore: Connected successfully");
                Ok(store)
            }
            Err(e) => {
                println!("⚠️  ReductStore: Connection failed - {}", e);
                println!("📝 Using in-memory storage fallback (POC mode)");
                Ok(Self {
                    client: None,
                    in_memory_store: Arc::new(RwLock::new(HashMap::new())),
                    use_memory_fallback: true,
                })
            }
        }
    }

    async fn ensure_bucket(&self) -> Result<()> {
        let client = self.client.as_ref()
            .ok_or_else(|| Error::StoreError("No ReductStore client".to_string()))?;

        // Try to get bucket, create if doesn't exist
        match client.get_bucket(BUCKET_NAME).await {
            Ok(_) => {
                println!("->> ReductStore: Bucket '{}' exists", BUCKET_NAME);
                Ok(())
            }
            Err(e) if e.status() == reduct_rs::ErrorCode::NotFound => {
                println!("->> ReductStore: Creating bucket '{}'", BUCKET_NAME);
                client
                    .create_bucket(BUCKET_NAME)
                    .send()
                    .await
                    .map_err(|e| Error::StoreError(format!("Failed to create bucket: {}", e)))?;
                Ok(())
            }
            Err(e) => Err(Error::StoreError(format!("Bucket check failed: {}", e))),
        }
    }

    pub async fn write_patient(&self, patient: &Patient) -> Result<()> {
        let timestamp = chrono::Utc::now().timestamp_micros() as u64;

        if self.use_memory_fallback {
            // In-memory fallback
            let mut store = self.in_memory_store.write().await;
            store.insert(patient.id.clone(), (patient.clone(), timestamp));
            println!("->> MemoryStore: Wrote patient {} at timestamp {}", patient.id, timestamp);
            return Ok(());
        }

        // ReductStore mode
        let client = self.client.as_ref()
            .ok_or_else(|| Error::StoreError("No ReductStore client".to_string()))?;

        let bucket = client
            .get_bucket(BUCKET_NAME)
            .await
            .map_err(|e| Error::StoreError(format!("Failed to get bucket: {}", e)))?;

        // Serialize patient to JSON
        let data = serde_json::to_vec(patient)
            .map_err(|e| Error::StoreError(format!("Failed to serialize patient: {}", e)))?;

        // Write to ReductStore
        bucket
            .write_record(ENTRY_NAME)
            .data(data)
            .timestamp_us(timestamp)
            .add_label("patient_id", &patient.id)
            .add_label("created_by", &patient.created_by.to_string())
            .send()
            .await
            .map_err(|e| Error::StoreError(format!("Failed to write record: {}", e)))?;

        // Also keep in index for quick lookups
        let mut store = self.in_memory_store.write().await;
        store.insert(patient.id.clone(), (patient.clone(), timestamp));

        println!("->> ReductStore: Wrote patient {} at timestamp {}", patient.id, timestamp);
        Ok(())
    }

    pub async fn read_patient(&self, id: &str) -> Result<Patient> {
        // Read from in-memory index (used in both modes for quick lookups)
        let store = self.in_memory_store.read().await;
        store.get(id)
            .map(|(patient, _)| patient.clone())
            .ok_or_else(|| Error::PatientNotFound { id: id.to_string() })
    }

    pub async fn list_patients(&self) -> Result<Vec<Patient>> {
        let store = self.in_memory_store.read().await;
        let patients: Vec<Patient> = store.values()
            .map(|(patient, _)| patient.clone())
            .collect();

        println!("->> Store: Listed {} patients", patients.len());
        Ok(patients)
    }

    pub async fn delete_patient(&self, id: &str) -> Result<()> {
        // For audit trail, we don't actually delete
        // Just remove from in-memory index (in production, would add "deleted" label)
        let mut store = self.in_memory_store.write().await;
        store.remove(id);
        
        println!("->> Store: Marked patient {} as deleted", id);
        Ok(())
    }
}
