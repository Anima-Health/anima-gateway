use axum::{RequestPartsExt, async_trait};
use axum::body::Body;
use axum::extract::{FromRequestParts, State};
use axum::http::request::Parts;
use axum::middleware::Next;
use axum_extra::extract::cookie::{CookieJar, Cookie};
use crate::ctx::Ctx;
use crate::model::ModelController;
use crate::web::AUTH_TOKEN;
use crate::{Error, Result};
use axum::http::{Request, Response};

pub async  fn mw_require_auth<B>(
    ctx: Result<Ctx>,
    req: Request<Body>,
    next: Next,
) -> Result<Response<Body>>{
    println!("->> {:<12} - mw_require_auth", "MIDDLEWARE");

    ctx?;
    
    // auth_token.ok_or(Error::AuthFailNoAuthTokenCookie)?;
    
    Ok(next.run(req).await)
    
}

pub async fn mw_ctx_resolver<B>(
    State(_mc): State<ModelController>,
    cookies: CookieJar,
    mut req: Request<Body>,
    next: Next,
) -> Result<Response<Body>> {
    println!("->> {:<12} - mw_ctx_resolver", "MIDDLEWARE");

    let auth_token = cookies.get(AUTH_TOKEN).map(|c| c.value().to_string());

    let result_ctx = match auth_token 
        .ok_or(Error::AuthFailNoAuthTokenCookie)
        .and_then(parse_token)
    {
        Ok((user_id, _exp, _sign)) => {
            Ok(Ctx::new(user_id))
        }
        Err(e) => Err(e),
    };

    if result_ctx.is_err() && !matches!(result_ctx, Err(Error::AuthFailNoAuthTokenCookie)) {
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
            .get::<Result<Ctx>>().ok_or(Error::AuthFailCtxNotInRequestExt)?
            .clone()

    }
}


fn parse_token(token: String) -> Result<(u64, String, String)> {

    let (_whole, user_id, exp, signature) = lazy_regex::regex_captures!(
        r"^user-(\d+)\.(.+)\.(.+)$",
        &token
    ).ok_or(Error::AuthFailInvalidTokenFormat)?;

    let user_id = user_id.parse().map_err(|_| Error::AuthFailInvalidTokenFormat)?;
    let exp = exp.to_string();
    let signature = signature.to_string();

    Ok((user_id, exp, signature))
}