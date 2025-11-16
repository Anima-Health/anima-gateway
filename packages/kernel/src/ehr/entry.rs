use crate::ehr::{DvText, DvDateTime, DvCodedText, DvQuantity};
use serde::{Serialize, Deserialize};

/// openEHR Entry - clinical statement
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum Entry {
    Observation(Observation),
    Evaluation(Evaluation),
    Instruction(Instruction),
    Action(Action),
}

/// Observation - recorded facts
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Observation {
    pub name: DvText,
    pub archetype_id: String,
    pub time: DvDateTime,
    pub data: ObservationData,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObservationData {
    pub items: Vec<ObservationItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObservationItem {
    pub name: DvText,
    pub value: ObservationValue,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "value_type")]
pub enum ObservationValue {
    Text(DvText),
    CodedText(DvCodedText),
    Quantity(DvQuantity),
    DateTime(DvDateTime),
}

/// Evaluation - clinical assessment/judgment
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Evaluation {
    pub name: DvText,
    pub archetype_id: String,
    pub time: DvDateTime,
    pub data: EvaluationData,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvaluationData {
    pub summary: DvText,
    pub items: Vec<EvaluationItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvaluationItem {
    pub name: DvText,
    pub value: DvText,
}

/// Instruction - care plan/order
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Instruction {
    pub name: DvText,
    pub narrative: DvText,
}

/// Action - healthcare action performed
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Action {
    pub name: DvText,
    pub time: DvDateTime,
    pub description: DvText,
}

// Helper constructors
impl Observation {
    pub fn new(name: impl Into<String>, archetype_id: impl Into<String>) -> Self {
        Self {
            name: DvText::new(name),
            archetype_id: archetype_id.into(),
            time: DvDateTime::now(),
            data: ObservationData { items: Vec::new() },
        }
    }

    pub fn add_item(mut self, name: impl Into<String>, value: ObservationValue) -> Self {
        self.data.items.push(ObservationItem {
            name: DvText::new(name),
            value,
        });
        self
    }
}

impl Evaluation {
    pub fn new(name: impl Into<String>, archetype_id: impl Into<String>, summary: impl Into<String>) -> Self {
        Self {
            name: DvText::new(name),
            archetype_id: archetype_id.into(),
            time: DvDateTime::now(),
            data: EvaluationData {
                summary: DvText::new(summary),
                items: Vec::new(),
            },
        }
    }

    pub fn add_item(mut self, name: impl Into<String>, value: impl Into<String>) -> Self {
        self.data.items.push(EvaluationItem {
            name: DvText::new(name),
            value: DvText::new(value),
        });
        self
    }
}

