use crate::ehr::{Entry, DvText, DvDateTime, DvCodedText};
use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};

/// openEHR Composition - top-level clinical document
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Composition {
    /// Unique identifier for this composition
    pub uid: String,
    
    /// Patient DID this composition belongs to
    pub subject_did: String,
    
    /// Category of composition (event, persistent, episode)
    pub category: CompositionCategory,
    
    /// Composition archetype (template identifier)
    pub archetype_id: String,
    
    /// Human-readable name
    pub name: DvText,
    
    /// Composer (who created this composition)
    pub composer: String,
    
    /// Composition time
    pub context: CompositionContext,
    
    /// The actual clinical content
    pub content: Vec<Entry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompositionContext {
    pub start_time: DvDateTime,
    pub end_time: Option<DvDateTime>,
    pub setting: DvCodedText,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum CompositionCategory {
    Event,      // Single event (e.g., consultation)
    Persistent, // Ongoing (e.g., problem list)
    Episode,    // Care episode
}

/// Builder for creating openEHR Compositions
pub struct CompositionBuilder {
    composition: Composition,
}

impl CompositionBuilder {
    pub fn new(
        uid: String,
        subject_did: String,
        archetype_id: impl Into<String>,
        name: impl Into<String>,
        composer: impl Into<String>,
    ) -> Self {
        Self {
            composition: Composition {
                uid,
                subject_did,
                category: CompositionCategory::Event,
                archetype_id: archetype_id.into(),
                name: DvText::new(name.into()),
                composer: composer.into(),
                context: CompositionContext {
                    start_time: DvDateTime::now(),
                    end_time: None,
                    setting: DvCodedText::new(
                        "primary medical care",
                        "openehr",
                        "229"
                    ),
                },
                content: Vec::new(),
            },
        }
    }

    pub fn category(mut self, category: CompositionCategory) -> Self {
        self.composition.category = category;
        self
    }

    pub fn setting(mut self, setting: DvCodedText) -> Self {
        self.composition.context.setting = setting;
        self
    }

    pub fn add_entry(mut self, entry: Entry) -> Self {
        self.composition.content.push(entry);
        self
    }

    pub fn build(self) -> Composition {
        self.composition
    }
}

impl Composition {
    /// Create a hash of this composition for Merkle tree
    pub fn compute_hash(&self) -> Vec<u8> {
        let json = serde_json::to_vec(self).unwrap_or_default();
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(&json);
        hasher.finalize().to_vec()
    }
}

