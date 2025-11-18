# Anima Health
**Healthcare meets blockchain. Privacy meets provenance. Patients meet control.**

**Privacy-Preserving Healthcare Data Provenance with IOTA Blockchain**

> Zero PHI on-chain | DID-based Identity | openEHR Standard | Merkle Tree Anchoring

---

## 🏆 IOTA Hackathon 2025 Submission

**Problem:** Healthcare data is siloed, insecure, and patients have no control. $496B lost annually to data inefficiency. 133M records breached in 2023.

**Solution:** Anima Health uses IOTA Move contracts + IOTA DID to provide tamper-proof, privacy-preserving healthcare records with cryptographic verification.

**Status:** ✅ Fully functional | ✅ Deployed on IOTA Testnet | ✅ Frontend + Backend integrated

---

## 🎯 What is Anima Health?

A **blockchain-verified healthcare data management system** that provides:

✅ **Immutable audit trail** - Who accessed what, when, and why  
✅ **Privacy-first** - All PHI stored off-chain (HIPAA compliant)  
✅ **Patient-controlled** - Unique DID per patient  
✅ **Standards-compliant** - openEHR + W3C DID + IOTA  
✅ **Cryptographically proven** - Merkle roots on IOTA blockchain  

---

## 🏗️ Architecture

TBC

## 🚀 Quick Start

### **Full Stack** (Backend + Frontend): (Super preferred)

```bash
# Terminal 1: Backend API
cd packages/kernel && cargo run

# Terminal 2: Frontend Dashboard
cd packages/frontend && npm install && npm run dev

# Browser
open http://localhost:3000
```

**See**: Bold neobrutalism dashboard with real IOTA integration!

### **Manual Setup**:

```bash
# 1. Start ReductStore (optional - has fallback)
docker run -d -p 8383:8383 -v ${PWD}/data:/data reduct/store:latest

# 2. Run Backend API (Terminal 1)
cd packages/kernel && cargo run

# 3. Run Frontend Dashboard (Terminal 2)
cd packages/frontend && npm install && npm run dev

# 4. Open Browser
open http://localhost:3000

# 5. Test API (Terminal 3 - optional)
cd packages/kernel && cargo run --example quick_dev
---

## 📦 Project Structure

```
anima-health/
├── packages/
│   ├── contracts/          # IOTA Move Smart Contracts
│   │   ├── sources/        # 5 contracts
│   │   └── tests/          # 71 tests ✅ 
│   │
│   ├── kernel/            # Rust Backend API
│   │   ├── src/           # 30+ modules
│   │   ├── Dockerfile     # Container configuration
│   │   └── examples/      # Integration tests
│   │
│   └── frontend/          # Next.js Dashboard (NEW!) 🎨
│       ├── src/app/       # Next.js 14 app router
│       ├── src/components/# Neobrutalism UI components
│       └── README.md      # Frontend setup guide
│
├── docker-compose.yml     # Full stack deployment
└── FLY_IO_DEPLOY.md       # Deployment guide
```

---

## ⛓️ IOTA Smart Contracts

### **5 Production-Ready Modules** (71/71 tests passing ✅):

1. **`core_anchor.move`** - Merkle root anchoring with witness quorum
2. **`consent_attestor.move`** - Hash-only consent proofs
3. **`did_role_registry.move`** - DID-account binding & roles
4. **`anima_governor.move`** - Governance with timelock
5. **`access_control.move`** - Reusable RBAC component

```bash
# Test smart contracts
cd packages/contracts
iota move test

# Output: ✅ 71/71 tests passing - Need to add more tests in the future
```

---


## 🔐 IOTA DID Authentication - Experimenting with this for this hackathon

### **Challenge-Response Flow**:

**Step 1**: Request challenge nonce
```bash
POST /api/auth/challenge
{"did": "did:iota:anima:abc123"}
```

**Step 2**: Sign with DID private key
```
Message: "Anima Health Auth:{nonce}"
Sign with Ed25519 private key
```

**Step 3**: Submit signed challenge
```bash
POST /api/login
{
  "did": "did:iota:anima:abc123",
  "nonce": "uuid-from-step-1",
  "signature": "ed25519-signature"
}
```

**Step 4**: Use access token (24h validity)
```
Cookie: auth-token=user-{id}.{exp}.{hmac}
```

---


## 🏥 Patient Data Management

### **Create Patient** (Generates unique DID + openEHR):

```bash
POST /api/patient
{
  "name": "John Doe",
  "date_of_birth": "1990-05-15",
  "medical_record_number": "MRN001",
  "gender": "male",
  "address": "123 Health St, London, UK"
}
```

**What happens**:
1. Generate patient UUID
2. Create IOTA DID: `did:iota:anima:{uuid}`
3. Generate Ed25519 keypair (REAL crypto!)
4. Build openEHR composition
5. Store in ReductStore
6. Add to Merkle anchor queue


---


## 🌳 Merkle Tree Anchoring - Implemented as POC

### **Batch Multiple Records** → **Single Blockchain Transaction**:

```bash
# Check pending
GET /api/anchor/pending
→ {"pending_count": 3}

# Create batch
POST /api/anchor/batch
→ {
    "root_hash_hex": "a7317181b621ee046587fc5eeb55e22741bc8b891286bee20716ff3b7525d5ed",
    "record_count": 3,
    "batch_id": 1763282779
  }
```

**This Merkle root proves**:
- 3 specific patient records existed at time T
- Each with full openEHR composition + DID
- Cryptographically verifiable
- Immutable on IOTA blockchain

---

## 🔑 Key Features

### **1. Privacy-First Design**:
- ✅ Zero PHI on blockchain
- ✅ Only cryptographic hashes stored
- ✅ Full data in ReductStore (off-chain)

### **2. IOTA DID Integration**:
- ✅ `did:iota:anima:{patient_id}` format
- ✅ Real Ed25519 keypairs (ed25519-dalek 2.0)
- ✅ IOTA SDK v1.0 + identity_iota v1.6.0-beta
- ✅ Testnet-ready

### **3. openEHR Compliance**:
- ✅ International healthcare standard
- ✅ Compositions, Observations, Evaluations
- ✅ Terminology binding (ISO_5218)
- ✅ Archetype-based

### **4. Blockchain Anchoring**:
- ✅ SHA-256 Merkle trees
- ✅ Batch efficiency (100 records → 1 tx)
- ✅ Witness quorum validation
- ✅ Cross-chain mirrors

---

## 🧪 Testing

### **Integration Test**:

```bash
cd packages/kernel
cargo run --example quick_dev
```

**Test Flow**:
1. Request authentication challenge
2. Login with DID
3. Create 3 patients (each with unique DID)
4. Check pending anchors
5. Create Merkle batch
6. Verify batch info

### **Smart Contract Tests**:

```bash
cd packages/contracts
iota move test
```

---

## 📡 API Endpoints

**Base URL**: `http://localhost:8080` (Development)

### **🔓 Public Endpoints** (No Auth Required):

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check for monitoring |
| GET | `/api/info` | API capabilities and info |
| POST | `/api/auth/challenge` | Request authentication nonce |
| POST | `/api/login` | Submit signed DID challenge |

### **🔐 Protected Endpoints** (Require Auth Cookie):

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/patient` | Create patient with DID + openEHR |
| GET | `/api/patient` | List all patients |
| GET | `/api/patient/:id` | Get specific patient |
| DELETE | `/api/patient/:id` | Delete patient |
| POST | `/api/anchor/batch` | Create Merkle batch and anchor |
| GET | `/api/anchor/pending` | Get pending anchor count |

**📖 Complete API Reference**: See `API_ENDPOINTS.md`

### **Quick Test**:

```bash
# Health check
curl http://localhost:8080/health

# API info
curl http://localhost:8080/api/info

---


## Documentation - TEsting out a new system with multi-docs

- **`DEPLOYMENT.md`** - Complete deployment guide
- **`ARCHITECTURE.md`** - System architecture
- **`IMPLEMENTATION_SUMMARY.md`** - Technical details
- **`IOTA_INTEGRATION_STATUS.md`** - IOTA integration proof
- **`packages/kernel/README.md`** - Kernel API guide
- **`packages/kernel/DID_AUTH.md`** - DID authentication
- **`packages/kernel/PATIENT_DID_EHR.md`** - Patient DID + openEHR
- **`packages/contracts/README.md`** - Smart contracts

---

## 🏆 For IOTA Hackathon Judges

### **This Project Uses IOTA**:

✅ **IOTA Move Smart Contracts**
✅ **IOTA DID Method** - `did:iota:anima:{id}`  
✅ **Real Ed25519 Cryptography** - Not mocks!  
✅ **IOTA SDK** - v1.0 with testnet client  
✅ **identity_iota** - v1.6.0-beta library  
✅ **Standards Compliant** - W3C DID + openEHR  

### **Innovation**:

🌟 **Unique DID per patient** - Self-sovereign identity  
🌟 **openEHR compositions** - Healthcare standard  
🌟 **Zero PHI on-chain** - Privacy-preserving  
🌟 **Merkle batching** - Efficient anchoring  
🌟 **Witness quorum** - Distributed validation  

---


## 📄 License

MIT

---

## 👨‍💻 Built for IOTA Hackathon by Akanimoh Osutuk

**Healthcare meets blockchain. Privacy meets provenance. Patients meet control.** 🏥⛓️
