use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};

/// openEHR Data Value - Text
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DvText {
    pub value: String,
}

impl DvText {
    pub fn new(value: impl Into<String>) -> Self {
        Self { value: value.into() }
    }
}

/// openEHR Data Value - Coded Text (with terminology binding)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DvCodedText {
    pub value: String,
    pub defining_code: CodePhrase,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodePhrase {
    pub terminology_id: String,
    pub code_string: String,
}

impl DvCodedText {
    pub fn new(value: impl Into<String>, terminology: impl Into<String>, code: impl Into<String>) -> Self {
        Self {
            value: value.into(),
            defining_code: CodePhrase {
                terminology_id: terminology.into(),
                code_string: code.into(),
            },
        }
    }
}

/// openEHR Data Value - Date Time
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DvDateTime {
    pub value: DateTime<Utc>,
}

impl DvDateTime {
    pub fn now() -> Self {
        Self { value: Utc::now() }
    }

    pub fn from_datetime(dt: DateTime<Utc>) -> Self {
        Self { value: dt }
    }
}

/// openEHR Data Value - Quantity (with units)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DvQuantity {
    pub magnitude: f64,
    pub units: String,
}

impl DvQuantity {
    pub fn new(magnitude: f64, units: impl Into<String>) -> Self {
        Self {
            magnitude,
            units: units.into(),
        }
    }
}

