mod error;

pub use self::error::{Error, Result};

#[derive(Clone, Debug)]
pub struct  Ctx {
    user_id: u64,
}

impl Ctx {
    pub fn root_ctx() -> Self {
        Ctx { user_id: 0 }
    }
    
    pub fn new(user_id: u64) -> Result<Self> {
        if user_id == 0 {
            Err(Error::CtxCannotNewRootCtx)
        } else {
            Ok(Self { user_id })
        }
    }
}

impl Ctx {
    pub fn user_id(&self) -> u64 {
        self.user_id
    }
}