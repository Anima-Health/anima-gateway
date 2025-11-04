#![allow(unused)]

use anyhow::Result;
use serde_json::json;

#[tokio::test]
async fn quick_dev() -> Result<()> {
    let hc = httpc_test::new_client("http://localhost:8080")?;

    // hc.do_get("/hello?name=John").await?.print().await?;

    // hc.do_get("/src/main.rs").await?.print().await?;

    let req_login = hc.do_post(
        "/api/login",
        json!({
            "did": "did:iota:anima:abc123",
            "nonce": "3a1f9c84b7e5d2a4c6f0e1b3a9c8d7f6e5c4b3a2918273645f0e1d2c3b4a596",
            "signature": "a1b2c3D4e5F6g7H8i9J0kLmNOpQrStUvWxYzA1B2C3D4E5F6G7H8I9J0K-L_MnOpQrStUvWxYzA1B2C3D4E5F6",
        }),
    );

    req_login.await?.print().await?;

    let req_create_patient = hc.do_post(
        "/api/patient",
        json!({
            "name": "John Doe",
        }),
    );

    req_create_patient.await?.print().await?;

    // let req_delete_patient = hc.do_delete(
    //     "/api/patient/1",
    // );

    // req_delete_patient.await?.print().await?;

    Ok(())
}