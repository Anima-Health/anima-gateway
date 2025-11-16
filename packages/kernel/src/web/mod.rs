mod error;

pub mod routes_login;
pub mod routes_patient;
pub mod routes_anchor;
pub mod routes_health;
pub mod mw_auth;
pub mod mw_ehr;
pub mod routes_static;
pub mod mw_res_map;

pub const AUTH_TOKEN: &str = "auth-token";

pub use self::error::{Error, Result};
pub use self::error::ClientError;