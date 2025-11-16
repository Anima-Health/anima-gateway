use axum::{
    http::StatusCode,
    response::IntoResponse,
    response::Response,
};
use serde::Serialize;
use crate::web;
use crate::model;


pub type Result<T> = core::result::Result<T, Error>;

#[derive(Clone, Debug, Serialize, strum_macros::AsRefStr)]
#[serde(tag = "type", content = "data")]
pub enum Error { 
    LoginFail,
    AuthFail(String),

    CtxExt(web::mw_auth::CtxExtError),
    
    Model(model::Error),
}

impl IntoResponse for Error {
    fn into_response(self) -> Response {
        println!("->> {:<12} - {self:?}", "INTO_RESPONSE");

        let mut response = StatusCode::INTERNAL_SERVER_ERROR.into_response();
        response.extensions_mut().insert(self);

        response
    }
}

impl core::fmt::Display for Error {
    fn fmt(
        &self,
        fmt: &mut core::fmt::Formatter
    ) -> core::result::Result<(), core::fmt::Error> {
        write!(fmt, "{self:?}")
    }
}
impl std::error::Error for Error {}

impl Error {
    pub fn client_status_and_error(&self) -> (StatusCode, ClientError) {

        use web::Error::*;

        #[allow(unreachable_patterns)]
        match self {
            LoginFail | AuthFail(_) => (StatusCode::UNAUTHORIZED, ClientError::LOGIN_FAIL),
            
            CtxExt(_) => (StatusCode::FORBIDDEN, ClientError::NO_AUTH),
            
            Model(model::Error::PatientNotFound { .. }) => (
                StatusCode::NOT_FOUND,
                ClientError::ENTITY_NOT_FOUND
            ),

            _ => (
                StatusCode::INTERNAL_SERVER_ERROR, 
                ClientError::SERVICE_ERROR
            ),
        }
    }
}

#[derive(Debug, strum_macros::AsRefStr)]
#[allow(non_camel_case_types)]
pub enum ClientError {
    LOGIN_FAIL,
    NO_AUTH,
    ENTITY_NOT_FOUND,
    SERVICE_ERROR,
}