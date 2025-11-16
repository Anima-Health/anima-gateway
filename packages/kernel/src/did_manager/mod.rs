mod error;
mod patient_did;
mod registry;

pub use self::error::{Error, Result};
pub use self::patient_did::{PatientDID, DIDMetadata};
pub use self::registry::DIDRegistry;

