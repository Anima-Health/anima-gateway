use axum::body::Body;
use axum::middleware::Next;
use axum_extra::extract::cookie::CookieJar;
use crate::web::AUTH_TOKEN;
use crate::{Error, Result};
use axum::http::{Request, Response};

pub async  fn mw_require_auth<B>(
    cookies: CookieJar,
    req: Request<Body>,
    next: Next,
) -> Result<Response<Body>>{
    println!("->> {:<12} - mw_require_auth", "MIDDLEWARE");

    let auth_token = cookies.get(AUTH_TOKEN).map(|c| c.value().to_string());

    // Todo: Verify the auth token
    // Use format `user-[user-id].[exp].[signature]` to verify the token
    // Returns (user-id, exp, signature) if successful
    let (user_id, exp, signature) = parse_token(auth_token.unwrap())?;
    
    // auth_token.ok_or(Error::AuthFailNoAuthTokenCookie)?;
    
    Ok(next.run(req).await)
    
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