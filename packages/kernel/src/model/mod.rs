

mod error;

pub use self::error::{Error, Result};


pub struct ModelController {}


impl ModelController {
    pub async fn new() -> Result<Self> {

        Ok(ModelController {})
    }
}