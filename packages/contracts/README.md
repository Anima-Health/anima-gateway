# Anima Health - Smart Contracts

## 🏥 Overview

**Anima Health** is a privacy-preserving healthcare data provenance platform using IOTA Move smart contracts for immutable audit trails while keeping Protected Health Information (PHI) completely off-chain.

**Core Principle**: Zero PHI on-chain - only cryptographic hashes are stored, ensuring HIPAA compliance and privacy protection.

---

## 📊 Project Status

### ✅ Smart Contracts: **Undergoing Testing**

- **5 Contract Modules** (1,875 lines)
- **71 Tests** - 100% passing ✅
- **4,048 lines of test code**
- **Complete integration** across all contracts

---

## 🏗️ Contract Architecture

### 1. **`access_control.move`**
**Purpose**: Reusable Role-Based Access Control (RBAC) component

**Features**:
- Embedded `AccessControl` struct used by all contracts
- Roles: Admin, Anchorer, Witness, Consent Attester
- Role granting/revoking with event emissions

**API**:
```move
new(admin, ctx) → AccessControl
has_role(ac, account, role) → bool
require_role(ac, account, role)
require_admin(ac, ctx)
grant_role(ac, account, role, clock, ctx)
revoke_role(ac, account, role, clock, ctx)
transfer_admin(ac, new_admin, clock, ctx)
```

---

### 2. **`core_anchor.move`**
**Purpose**: Immutable registry of Merkle batch roots with witness quorum validation

**Key Functions**:
- `anchor_root()` - Anchor Merkle roots (requires ROLE_ANCHORER)
- `witness_attest()` - Witness attestation (requires ROLE_WITNESS)
- `submit_mirror()` - Cross-chain mirror references
- `update_quorum()` - Update witness quorum threshold
- `grant_role()`, `revoke_role()`, `transfer_admin()` - Access control

---

### 3. **`consent_attestor.move`**
**Purpose**: On-chain proof that actions comply with consent policies (hash-only, zero PHI)

**Key Functions**:
- `attest()` - Create consent attestation (requires ROLE_CONSENT_ATTESTER)
- `revoke()` - Revoke attestation (admin only, keeps tombstone)
- `get_attestation()`, `find_by_anchor()`, `latest_attestations()` - View functions
- `grant_role()`, `revoke_role()`, `transfer_admin()` - Access control

---

### 4. **`did_role_registry.move`**
**Purpose**: DID-account bindings and system-wide role management

**Key Functions**:
- `bind_did()`, `unbind_did()` - DID-account binding (multi-account support)
- `grant_role()`, `revoke_role()` - System-wide role management
- `set_did_doc_uri()` - Set DID document URI
- `rotate_key()` - Key rotation with version tracking
- `has_role()`, `get_roles()` - Role checking

---

### 5. **`anima_governor.move`**
**Purpose**: Centralized governance with timelock, pause/unpause, and parameter management

**Key Functions**:
- `schedule()`, `execute()`, `cancel()` - Timelock operations
- `pause()`, `unpause()` - Circuit breaker (pause/unpause contracts)
- `set_param()`, `get_param()` - Parameter management
- `set_timelock_delay()`, `set_unpause_window()` - Configuration
- `grant_role()`, `revoke_role()`, `transfer_admin()` - Access control

**Roles**:
- `ROLE_ADMIN` (1), `ROLE_GOVERNOR` (32), `ROLE_GUARDIAN` (64)

---

## 🔄 How Contracts Work Together

### End-to-End Workflow

```
1. Kernel/Pod makes commit → Journal (off-chain)
   ↓
2. Batcher builds Merkle root → Anchorer calls AnimaAnchor.anchorRoot()
   ↓ (emits AnchorCommitted event)
3. Witness nodes call witness_attest()
   ↓ (3 witnesses → QuorumMet event)
4. Policy engine evaluates consent
   ↓ (hashes consent state & decision)
5. Attester calls ConsentAttestor.attest()
   ↓ (emits ConsentAttested event)
6. Complete audit trail: Data → Anchor → Witnesses → Consent
```

### Role Verification Flow

```
DIDRoleRegistry.is_registered(did) → verify caller's role
   ↓
Check role permissions → Allow/Deny operation
   ↓
AnimaGovernor.pause() → Can pause contracts if needed
```

### Governance Flow

```
Sensitive operations → AnimaGovernor.schedule()
   ↓
Timelock delay (default 24 hours)
   ↓
AnimaGovernor.execute() → Execute operation
   ↓
All changes journaled via events (on-chain + off-chain)
```

---

## 🔐 Security Features

✅ **Zero PHI on-chain** - Only cryptographic hashes stored  
✅ **Role-based access control** - Granular permissions across all contracts  
✅ **Timelock protection** - Sensitive operations require delay (default 24h)  
✅ **Circuit breaker** - Emergency pause/unpause with guardian role  
✅ **Write-once guarantees** - Immutable anchors prevent tampering  
✅ **Witness quorum** - M-of-N attestation for data validation  
✅ **Parameter management** - Configurable settings via governance  
✅ **Admin transfer** - Controlled ownership transfer capability  

---

## 🧪 Testing

### Test Suite Overview

- **Total Tests**: 71 tests (More to be added in future)
- **Success Rate**: 100% ✅
- **Test Distribution**:

### Running Tests

```bash
cd packages/contracts
iota move test
```

---

## 🌐 Cross-Chain Mirroring

### Use Case: Multi-Blockchain Access

```
1. Hospital creates patient records → Merkle batch
   ↓
2. Anchor on IOTA (primary blockchain)
   ↓
3. Insurance company needs proof
   ↓
4. Mirror to Ethereum → submit_mirror()
   ↓
5. Submit mirror reference pointing to Ethereum TX
   ↓
6. Patient moves to EU hospital
   ↓
7. Mirror to EU-compliant chain
   ↓
Result: One source of truth with multiple access points
```

---

## 🏛️ Architecture Patterns

### 1. **Composition Over Inheritance**
```
AccessControl (reusable component)
    ↓
Embedded in: CoreAnchor, ConsentAttestor, DIDRoleRegistry, AnimaGovernor
```

### 2. **Privacy-First Design**
```
Patient Data (Off-chain) → Hash → On-chain Proof
     ↓
ReductStore/IPFS → Merkle Batch → AnimaAnchor
     ↓                                    ↓
Only hash stored                  Only hash stored
```

### 3. **Multi-Layer Security**
```
Layer 1: AccessControl (role-based permissions)
Layer 2: DIDRoleRegistry (identity & trust)
Layer 3: CoreAnchor (write-once guarantees)
Layer 4: ConsentAttestor (policy compliance proof)
Layer 5: AnimaGovernor (centralized governance)
```

---

## 🚀 Development

```bash
cd packages/contracts
iota move build
```

### Running Tests

```bash
cd packages/contracts
iota move test
```

---

## 🔮 Future Enhancements

## Notes on AI use
Its interesting to see how I have intergrates AI into my workflow for this hackathon.
They are quite good in code commenting and bug troubleshooting. This however must still be with caution.

- `data_permit.move` - Time-boxed access tokens