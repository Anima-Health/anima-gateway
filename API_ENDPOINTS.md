# Anima Health - API Endpoints Reference

## 📡 Base URL

**Development**: `http://localhost:8080`  
**Production**: `https://your-domain.com`

---

## 🔓 Public Endpoints (No Authentication Required)

### **GET /health**

Health check for monitoring and load balancers.

```bash
curl http://localhost:8080/health
```

**Response**:
```json
{
  "status": "healthy",
  "service": "anima-health-kernel",
  "version": "0.1.0"
}
```

---

### **GET /api/info**

API capabilities and endpoint documentation.

```bash
curl http://localhost:8080/api/info
```

**Response**:
```json
{
  "name": "Anima Health Kernel API",
  "version": "0.1.0",
  "features": {
    "iota_did_auth": true,
    "openehr_compositions": true,
    "merkle_anchoring": true,
    "reductstore_integration": true
  },
  "iota": {
    "did_method": "did:iota:anima",
    "testnet": "https://api.testnet.iotaledger.net",
    "smart_contracts": 5
  }
}
```

---

### **POST /api/auth/challenge**

Request authentication challenge nonce.

**Request**:
```bash
curl -X POST http://localhost:8080/api/auth/challenge \
  -H "Content-Type: application/json" \
  -d '{"did": "did:iota:anima:abc123"}'
```

**Body**:
```json
{
  "did": "did:iota:anima:abc123"  // Optional
}
```

**Response**:
```json
{
  "nonce": "b618dc40-0aee-4718-9d22-c23d2de9558f",
  "expires_at": 1763370000
}
```

**Details**:
- Nonce expires in 5 minutes
- Use this nonce for login
- Sign message: `"Anima Health Auth:{nonce}"`

---

### **POST /api/login**

Authenticate with signed DID challenge.

**Request**:
```bash
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{
    "did": "did:iota:anima:abc123",
    "nonce": "b618dc40-0aee-4718-9d22-c23d2de9558f",
    "signature": "ed25519_signature_here"
  }'
```

**Body**:
```json
{
  "did": "did:iota:anima:abc123",
  "nonce": "uuid-from-challenge",
  "signature": "base64_encoded_ed25519_signature"
}
```

**Response**:
```json
{
  "success": true,
  "user_id": 409701,
  "did": "did:iota:anima:abc123",
  "message": "Authentication successful"
}
```

**Sets Cookie**:
```
auth-token=user-409701.1763370000.b853221244bc294c7396af1489cd5041c2630049fc2aa351364ddb9d1530835f
```

---

## 🔐 Protected Endpoints (Require Authentication)

**All requests must include**: `Cookie: auth-token=...`

Or save cookie with `-c cookies.txt` and use with `-b cookies.txt`

---

### **POST /api/patient**

Create patient record with unique DID and openEHR composition.

**Request**:
```bash
curl -X POST http://localhost:8080/api/patient \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "name": "John Doe",
    "date_of_birth": "1990-05-15",
    "medical_record_number": "MRN001",
    "gender": "male",
    "address": "123 Health St, London, UK"
  }'
```

**Body**:
```json
{
  "name": "John Doe",
  "date_of_birth": "1990-05-15",
  "medical_record_number": "MRN001",
  "gender": "male",      // Optional
  "address": "..."       // Optional
}
```

**Response**:
```json
{
  "id": "7fd7f780-2842-4065-b447-6cb00e1fbd84",
  "did": "did:iota:anima:7fd7f780-2842-4065-b447-6cb00e1fbd84",
  
  "demographics": {
    "name": "John Doe",
    "date_of_birth": "1990-05-15",
    "medical_record_number": "MRN001",
    "gender": "male",
    "address": "123 Health St, London, UK"
  },
  
  "composition": {
    "uid": "7fd7f780_demographics_v1",
    "subject_did": "did:iota:anima:7fd7f780-2842-4065-b447-6cb00e1fbd84",
    "category": "persistent",
    "archetype_id": "openEHR-EHR-COMPOSITION.person.v1",
    "composer": "user:409701",
    "content": [
      {
        "type": "Observation",
        "archetype_id": "openEHR-EHR-OBSERVATION.demographics.v1",
        "data": {
          "items": [
            {"name": "Name", "value": "John Doe"},
            {"name": "Date of Birth", "value": "1990-05-15"},
            {"name": "MRN", "value": "MRN001"},
            {"name": "Gender", "value": {
              "value_type": "CodedText",
              "value": "male",
              "defining_code": {
                "terminology_id": "ISO_5218",
                "code_string": "male"
              }
            }}
          ]
        }
      }
    ]
  },
  
  "did_metadata": {
    "did": "did:iota:anima:7fd7f780-2842-4065-b447-6cb00e1fbd84",
    "public_key": "b1380f1d6a1fdef473e645c655ee1273288f2a7d8fc24e3b4bf88269f84719ad",
    "private_key": "881a76591a32fc5460faaa89f79a97843c6c40c4f0cf7f670fa155a401c174b5",
    "key_version": 1,
    "status": "Active"
  },
  
  "created_at": "2025-11-16T09:04:12.650141Z",
  "created_by": 409701
}
```

**What Gets Created**:
1. ✅ Unique patient UUID
2. ✅ IOTA DID: `did:iota:anima:{uuid}`
3. ✅ Real Ed25519 keypair (32-byte keys)
4. ✅ openEHR composition with demographics
5. ✅ Stored in ReductStore
6. ✅ Queued for Merkle anchoring

---

### **GET /api/patient**

List all patients.

**Request**:
```bash
curl http://localhost:8080/api/patient \
  -b cookies.txt
```

**Response**:
```json
[
  {
    "id": "7fd7f780-2842-4065-b447-6cb00e1fbd84",
    "did": "did:iota:anima:7fd7f780-2842-4065-b447-6cb00e1fbd84",
    "demographics": { /* ... */ },
    "composition": { /* ... */ },
    "did_metadata": { /* ... */ }
  },
  { /* patient 2 */ },
  { /* patient 3 */ }
]
```

---

### **GET /api/patient/:id**

Get specific patient by ID.

**Request**:
```bash
curl http://localhost:8080/api/patient/7fd7f780-2842-4065-b447-6cb00e1fbd84 \
  -b cookies.txt
```

**Response**: Same as individual patient object.

---

### **DELETE /api/patient/:id**

Mark patient as deleted.

**Request**:
```bash
curl -X DELETE http://localhost:8080/api/patient/7fd7f780-2842-4065-b447-6cb00e1fbd84 \
  -b cookies.txt
```

**Response**:
```json
{
  "id": "7fd7f780-2842-4065-b447-6cb00e1fbd84",
  "did": "did:iota:anima:7fd7f780...",
  /* full patient record */
}
```

**Note**: Record removed from active index but preserved in ReductStore for audit.

---

### **POST /api/anchor/batch**

Create Merkle batch from pending records.

**Request**:
```bash
curl -X POST http://localhost:8080/api/anchor/batch \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

**Response**:
```json
{
  "success": true,
  "batch": {
    "batch_id": 1763282779,
    "root_hash_hex": "a7317181b621ee046587fc5eeb55e22741bc8b891286bee20716ff3b7525d5ed",
    "algo_id": "sha256",
    "record_count": 3,
    "timestamp": 1763282779,
    "meta_uri": "reduct://anima-patients/batch-1763282779"
  },
  "tx_hash": "0x6919905b",
  "message": "Batch created and anchored"
}
```

**What Happens**:
1. Fetches all pending patient records (with DIDs + openEHR)
2. Computes SHA-256 Merkle root
3. (Production) Anchors to IOTA blockchain
4. Clears pending queue

---

### **GET /api/anchor/pending**

Check how many records are waiting to be anchored.

**Request**:
```bash
curl http://localhost:8080/api/anchor/pending \
  -b cookies.txt
```

**Response**:
```json
{
  "pending_count": 3
}
```

---

## 📋 Quick Reference

### **Authentication Flow**:
```
1. POST /api/auth/challenge → Get nonce
2. Sign message with DID private key
3. POST /api/login → Get auth cookie
4. Use cookie for all protected endpoints
```

### **Patient Flow**:
```
1. POST /api/patient → Creates patient with DID
2. GET /api/patient → List all
3. POST /api/anchor/batch → Anchor to blockchain
```

---

## 🎯 All Endpoints Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health` | No | Health check |
| GET | `/api/info` | No | API info |
| POST | `/api/auth/challenge` | No | Request nonce |
| POST | `/api/login` | No | Authenticate |
| POST | `/api/patient` | Yes | Create patient + DID |
| GET | `/api/patient` | Yes | List patients |
| GET | `/api/patient/:id` | Yes | Get patient |
| DELETE | `/api/patient/:id` | Yes | Delete patient |
| POST | `/api/anchor/batch` | Yes | Create Merkle batch |
| GET | `/api/anchor/pending` | Yes | Check pending |
| GET | `/` | No | Static files |

**Total**: **11 endpoints** ready for hackathon! ✅

---

## 🚀 Deployment Advice

### **For Hackathon Demo** (RECOMMENDED):

**Run Natively** (avoids Docker complexity):
```bash
cd packages/kernel
cargo run
```

**Why**:
- ✅ No Docker dependency issues
- ✅ Faster iteration
- ✅ Easy debugging
- ✅ Works immediately

### **For Presentation**:

**Access at**: `http://localhost:8080`

**Test with**:
```bash
cargo run --example quick_dev
```

---

## 📚 Where Endpoints are Documented

✅ **`API_ENDPOINTS.md`** - This file (complete reference)  
✅ **`API_GATEWAY.md`** - Detailed integration guide  
✅ **`README.md`** - Quick overview  
✅ **`GET /api/info`** - Self-documenting endpoint  
✅ **`HACKATHON_DEMO.md`** - Demo script with examples  

---

**All endpoints are documented and ready to use!** 🎉
