use axum::{async_trait};
use axum::body::Body;
use axum::extract::{FromRequestParts, State};
use axum::http::request::Parts;
use axum::middleware::Next;
use axum_extra::extract::cookie::{CookieJar, Cookie};
use serde::Serialize;
use crate::ctx::Ctx;
use crate::model::ModelManager;
use crate::auth::TokenManager;
use crate::web::AUTH_TOKEN;
use crate::web::{Error, Result};
use axum::http::{Request, Response};

#[allow(dead_code)]
pub async fn mw_ctx_require<B>(
    ctx: Result<Ctx>,
    req: Request<Body>,
    next: Next,
) -> Result<Response<Body>>{
    println!("->> {:<12} - mw_ctx_require - {ctx:?}", "MIDDLEWARE");

    ctx?;
    
    // auth_token.ok_or(Error::AuthFailNoAuthTokenCookie)?;
    
    Ok(next.run(req).await)
    
}

pub async fn mw_ctx_resolve<B>(
    State(_mm): State<ModelManager>,
    cookies: CookieJar,
    mut req: Request<Body>,
    next: Next,
) -> Result<Response<Body>> {
    println!("->> {:<12} - mw_ctx_resolve", "MIDDLEWARE");

    let auth_token = cookies.get(AUTH_TOKEN).map(|c| c.value().to_string());

    // Parse and validate token
    let result_ctx = match auth_token {
        Some(token) => {
            // Validate token using TokenManager
            match TokenManager::validate_token(&token, None) {
                Ok(claims) => {
                    println!("   ✅ Token valid - user_id: {}, DID: {}", claims.user_id, claims.did);
                    Ctx::new(claims.user_id).map_err(|ex| CtxExtError::CtxCreateFail(ex.to_string()))
                }
                Err(e) => {
                    println!("   ->> Token validation failed: {:?}", e);
                    Err(CtxExtError::CtxCreateFail(format!("{:?}", e)))
                }
            }
        }
        None => {
            println!("   ->> No auth token in cookie");
            Err(CtxExtError::TokenNotInCookie)
        }
    };

    // Remove invalid tokens
    if result_ctx.is_err() && !matches!(result_ctx, Err(CtxExtError::TokenNotInCookie)) {
        let _cookies = cookies.remove(Cookie::from(AUTH_TOKEN));
    }

    req.extensions_mut().insert(result_ctx);

    Ok(next.run(req).await)
}


// Implementing Ctx as extractor
#[async_trait]
impl<S: Send + Sync> FromRequestParts<S> for Ctx {
    type Rejection = Error;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self> {
        println!("->> {:<12} - Ctx", "EXTRACTOR");

        parts
            .extensions
            .get::<CtxExtResult>()
            .ok_or(Error::CtxExt(CtxExtError::CtxNotInRequestExt))?
            .clone()
            .map_err(Error::CtxExt)

    }
}

type CtxExtResult = core::result::Result<Ctx, CtxExtError>;

#[derive(Debug, Serialize, Clone)]
pub enum CtxExtError {
    CtxNotInRequestExt,
    CtxCreateFail(String),
    TokenNotInCookie,
}

// fn parse_token(token: String) -> Result<(u64, String, String)> {

//     let (_whole, user_id, exp, signature) = lazy_regex::regex_captures!(
//         r"^user-(\d+)\.(.+)\.(.+)$",
//         &token
//     ).ok_or(Error::AuthFailInvalidTokenFormat)?;

//     let user_id = user_id.parse().map_err(|_| Error::AuthFailInvalidTokenFormat)?;
//     let exp = exp.to_string();
//     let signature = signature.to_string();

//     Ok((user_id, exp, signature))
// }