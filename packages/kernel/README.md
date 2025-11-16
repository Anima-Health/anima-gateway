# Anima Health - Kernel API

## 🏥 Data Notarization Layer

Privacy-preserving healthcare data provenance with **ReductStore** + **Merkle Trees** + **IOTA Blockchain**.

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     KERNEL API (Rust/Axum)                   │
├─────────────────────────────────────────────────────────────┤
│  Patient Data → ReductStore → Batch Queue → Merkle Tree    │
│                                                ↓             │
│                                         Merkle Root          │
│                                                ↓             │
│                                    IOTA Smart Contract      │
│                                    (core_anchor.move)        │
└─────────────────────────────────────────────────────────────┘
```

### **Core Workflow**:

1. **Patient Record Created** → Stored in ReductStore (off-chain, time-series DB)
2. **Added to Batch Queue** → Patient ID tracked for next anchor
3. **Manual Batch Trigger** → Creates Merkle tree from all pending records
4. **Merkle Root Computed** → SHA-256 hash of all records in batch
5. **Anchor to Blockchain** → Root hash sent to IOTA smart contract
6. **Immutable Proof** → Cryptographic proof data existed at time T

---

## 🗂️ Module Structure

```
src/
├── main.rs              # Entry point, middleware stack
├── error.rs             # Top-level error types
├── ctx/                 # Request context (user_id)
│   ├── mod.rs
│   └── error.rs
├── model/               # Data layer
│   ├── mod.rs          # ModelManager (orchestrator)
│   ├── patient.rs      # Patient CRUD (PatientBmc)
│   ├── store.rs        # ReductStore wrapper
│   ├── merkle.rs       # Merkle tree implementation
│   ├── anchor.rs       # Batch anchoring service
│   └── error.rs        # Model errors
├── log/                 # Structured logging
│   └── mod.rs
└── web/                 # HTTP layer
    ├── mod.rs
    ├── routes_login.rs  # Authentication
    ├── routes_patient.rs # Patient CRUD API
    ├── routes_anchor.rs # Anchor batch API
    ├── routes_static.rs # Static file serving
    ├── mw_auth.rs       # Auth middleware
    ├── mw_res_map.rs    # Response mapping
    └── error.rs         # Web errors
```

---

## 🚀 Quick Start

### **1. Start ReductStore**

```bash
docker run -d -p 8383:8383 \
  -v ${PWD}/data:/data \
  reduct/store:latest
```

Verify it's running:
```bash
curl http://127.0.0.1:8383/api/v1/info
```

### **2. Set Environment Variables**

Create `.env` in `/packages/kernel/`:

```env
PORT=8080
REDUCT_TOKEN=your-token-here
```

### **3. Run the Server**

```bash
cd packages/kernel
cargo run
```

Server starts on `http://localhost:8080`

### **4. Run Integration Test**

In another terminal:

```bash
cd packages/kernel
cargo run --example quick_dev
```

---

## 📡 API Endpoints

### **Authentication**

#### `POST /api/login`
Login with DID and get auth cookie

**Request**:
```json
{
  "did": "did:iota:anima:abc123",
  "nonce": "...",
  "signature": "..."
}
```

**Response**:
```json
{
  "result": {
    "success": true
  }
}
```

**Sets Cookie**: `auth-token=user-1.exp.sign`

---

### **Patient Management** (Requires Auth)

#### `POST /api/patient`
Create new patient record in ReductStore

**Request**:
```json
{
  "name": "John Doe",
  "date_of_birth": "1990-05-15",
  "medical_record_number": "MRN001"
}
```

**Response**:
```json
{
  "id": "uuid-v4",
  "name": "John Doe",
  "date_of_birth": "1990-05-15",
  "medical_record_number": "MRN001",
  "created_at": "2025-11-16T...",
  "created_by": 100
}
```

**✅ Data stored in ReductStore bucket: `anima-patients`**  
**✅ Added to pending anchor queue**

#### `GET /api/patient`
List all patients

#### `GET /api/patient/:id`
Get specific patient by ID

#### `DELETE /api/patient/:id`
Mark patient as deleted (keeps audit trail)

---

### **Anchoring** (Requires Auth)

#### `POST /api/anchor/batch`
Create Merkle batch from pending records and anchor

**Response**:
```json
{
  "success": true,
  "batch": {
    "batch_id": 1731772800,
    "root_hash_hex": "2c26b46b68ffc68ff99b453c1d30413413...",
    "algo_id": "sha256",
    "record_count": 3,
    "timestamp": 1731772800,
    "meta_uri": "reduct://anima-patients/batch-1731772800"
  },
  "tx_hash": "0x673f6e80",
  "message": "Batch created and anchored"
}
```

**What happens**:
1. Fetches all pending patient records
2. Creates Merkle tree from patient JSON data
3. Computes SHA-256 Merkle root
4. (In production) Calls `core_anchor::anchor_root()` on IOTA
5. Clears pending queue

#### `GET /api/anchor/pending`
Get count of records waiting to be anchored

**Response**:
```json
{
  "pending_count": 3
}
```

---

## 🧪 Testing Workflow

The `quick_dev` example demonstrates the complete notarization flow:

```bash
cargo run --example quick_dev
```

### **What it tests**:

1. ✅ **Static file serving** - `GET /index.html`
2. ✅ **Authentication** - `POST /api/login` (sets cookie)
3. ✅ **Create 3 patients** - `POST /api/patient` × 3
   - Stores in ReductStore
   - Adds to pending queue
4. ✅ **Check pending** - `GET /api/anchor/pending`
   - Should show: `{"pending_count": 3}`
5. ✅ **Create Merkle batch** - `POST /api/anchor/batch`
   - Computes Merkle root
   - Anchors to blockchain (simulated)
   - Clears queue
6. ✅ **List patients** - `GET /api/patient`
   - Retrieves from ReductStore

---

## 🔐 Security Features

✅ **Cookie-based auth** - Session management  
✅ **Context extraction** - User ID tracked for audit  
✅ **Protected routes** - `/api/*` requires authentication  
✅ **Structured logging** - UUID-tracked requests  
✅ **Error masking** - Client-friendly error messages  

---

## 🏗️ Key Components

### **ModelManager**
Central orchestrator for data operations:
- ReductStore client management
- Pending anchor queue (Thread-safe with `Arc<Mutex>`)
- Patient CRUD operations
- Merkle batch creation

### **ReductStore**
Time-series database wrapper:
- Bucket: `anima-patients`
- Entry: `patient-records`
- Labels: `patient_id`, `created_by`
- In-memory index for POC (production would use ReductStore queries)

### **MerkleTree**
SHA-256 Merkle tree implementation:
- Add leaves (auto-hashes data)
- Compute root hash
- Deterministic (same inputs → same root)
- Handles odd-numbered leaves

### **AnchorService**
Batch anchoring orchestration:
- Creates batches from pending queue
- Computes Merkle roots
- Generates metadata URIs
- (Production) Calls IOTA smart contract

---

## 🔄 Data Flow

### **Creating a Patient**:

```
POST /api/patient
    ↓
Ctx::new(100) from auth cookie
    ↓
PatientBmc::create(ctx, mm, patient_data)
    ↓
patient.id = UUID
patient.created_by = ctx.user_id()
    ↓
ReductStore::write_patient()
    ├─> Serialize to JSON
    ├─> Write to bucket with labels
    └─> Store in index: patient_id → timestamp
    ↓
Add to pending_anchors queue
    ↓
Response: Patient JSON
```

### **Anchoring a Batch**:

```
POST /api/anchor/batch
    ↓
AnchorService::create_batch(mm)
    ↓
Lock pending_anchors queue
    ↓
For each patient_id:
    ├─> Get patient from ReductStore
    ├─> Serialize to JSON
    └─> Add to Merkle tree
    ↓
Compute Merkle root (SHA-256)
    ↓
Create AnchoredBatch {
    root_hash_hex: "2c26b46...",
    batch_id: timestamp,
    record_count: 3,
    meta_uri: "reduct://..."
}
    ↓
(Production) Call smart contract:
    core_anchor::anchor_root(
        root_hash,
        "sha256",
        batch_id,
        meta_uri,
        ...
    )
    ↓
Clear pending queue
    ↓
Response: Batch info + tx_hash
```

---

## 🛠️ Development

### **Auto-reload server**:
```bash
cargo watch -q -c -w src/ -x run
```

### **Auto-run tests**:
```bash
cargo watch -q -c -x "run --example quick_dev"
```

### **Check compilation**:
```bash
cargo check
```

---

## 📝 Next Steps

### **For Production**:

1. **Integrate IOTA SDK**:
   - Call actual smart contract `core_anchor::anchor_root()`
   - Submit witness attestations
   - Submit cross-chain mirrors

2. **Enhanced Querying**:
   - Replace in-memory index with proper ReductStore labels/queries
   - Implement time-range queries
   - Add pagination

3. **Automated Anchoring**:
   - Background task that batches every N minutes or M records
   - Configurable batch sizes

4. **Consent Layer**:
   - Check consent policies before data access
   - Call `consent_attestor::attest()` for compliant accesses
   - Store consent state hashes

5. **DID Verification**:
   - Verify IOTA DID signatures in login
   - Integrate `identity_iota` library
   - Link DIDs to `did_role_registry` contract

6. **Access Permits**:
   - Time-boxed data access tokens
   - Call `data_permit` contract (to be implemented)
   - Enforce permit expiry

---

## 🎯 POC Goals

✅ **Store patient data off-chain** (ReductStore)  
✅ **Track pending records** (Batch queue)  
✅ **Compute Merkle roots** (SHA-256 tree)  
✅ **Simulate blockchain anchoring** (Mock tx hash)  
✅ **Auth-protected APIs** (Cookie-based)  
✅ **RESTful interface** (Axum)  

### **Demo Flow**:
1. Start ReductStore
2. Start Kernel API
3. Run `quick_dev` example
4. Observe: 3 patients created → Merkle root computed → Batch anchored

---

## 📚 Dependencies

- **axum** - Web framework
- **reduct-rs** - Time-series database client
- **sha2** - SHA-256 hashing
- **serde/serde_json** - Serialization
- **tower-cookies** - Cookie management
- **chrono** - Timestamps
- **uuid** - Unique IDs

---

## 🔮 Future Enhancements

- Automatic batch scheduling (cron-like)
- Webhook notifications on anchor completion
- GraphQL API for complex queries
- WebSocket for real-time updates
- Merkle proof generation (prove record in batch)
- IPFS integration for large files
- Multi-tenant support
- Access control lists per patient

---

## 📞 Testing

**Minimum viable test**:

```bash
# Terminal 1: Start ReductStore
docker run -p 8383:8383 -v ${PWD}/data:/data reduct/store:latest

# Terminal 2: Start API
cd packages/kernel
cargo run

# Terminal 3: Run test
cargo run --example quick_dev
```

**Expected output**:
- 3 patients created ✅
- Pending count: 3 ✅
- Batch created with Merkle root ✅
- All patients listed ✅

---

## 🏆 Achievement Unlocked

You now have a **working data notarization layer** that:
- Stores healthcare data securely off-chain
- Batches data into Merkle trees
- Generates cryptographic proofs (Merkle roots)
- Ready for blockchain anchoring
- Maintains complete audit trail

**This is the foundation for HIPAA-compliant, blockchain-verified healthcare data management!** 🎉

