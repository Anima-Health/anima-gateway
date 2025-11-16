# Frontend Setup - Quick Start

## 🎨 Neobrutalism Dashboard in Black & White

---

## ⚡ Run the Frontend (2 commands)

### **Terminal 1: Backend API**

```bash
cd packages/kernel
cargo run
```

**Wait for**: `->> Listening on 0.0.0.0:8080`

---

### **Terminal 2: Frontend**

```bash
cd packages/frontend

# Install dependencies (first time only)
npm install

# Run development server
npm run dev
```

**Open**: http://localhost:3000

---

## 🎯 What You'll See

### **Login Screen**:
```
┌─────────────────────────────────────┐
│           ANIMA                     │
│           HEALTH                    │
│                                     │
│    [IOTA DID AUTHENTICATION]        │
│                                     │
│    LOG IN                           │
│    No passwords. Just crypto proof. │
│                                     │
│    Your DID                         │
│    [did:iota:anima:abc123]          │
│                                     │
│    AUTHENTICATION FLOW:             │
│    1. Request challenge nonce       │
│    2. Sign with Ed25519             │
│    3. Verify signature              │
│    4. Get 24h token                 │
│                                     │
│    [AUTHENTICATE WITH DID] ←Button │
└─────────────────────────────────────┘
```

### **Dashboard Tabs**:

**Tab 1: CREATE PATIENT**
- Form fields (name, DOB, MRN, gender, address)
- Info box: "What will be created"
- Submit → Shows generated DID + public key
- Displays full openEHR composition details

**Tab 2: PATIENT LIST**
- 3 patient cards with DIDs
- Click to expand → See full public key
- Shows key version, status
- openEHR composition badge

**Tab 3: ANCHOR BATCH**
- Pending count display
- Merkle process steps (1-5)
- Create batch button
- Success → Shows Merkle root hash
- Displays batch ID, tx hash

---

## 🎨 Neobrutalism Features

✅ **Bold Typography** - Font-black, uppercase headers  
✅ **Thick Borders** - 4px black borders on everything  
✅ **Brutal Shadows** - 8px/12px offset shadows  
✅ **High Contrast** - Pure black (#000) and white (#FFF)  
✅ **Geometric** - Sharp, angular elements  
✅ **Hover Effects** - Shadow disappears, element shifts  

---

## 🔗 Backend Integration

**API Proxy** (configured in next.config.js):
```
Frontend: localhost:3000/api/patient
    ↓
Proxies to: localhost:8080/api/patient
```

**No CORS issues!** ✅

---

## 📦 Components Created

```
LoginPage.tsx      - DID authentication UI
Dashboard.tsx      - Main shell with tabs
PatientForm.tsx    - Create patient form + DID display
PatientList.tsx    - Patient cards with expand detail
AnchorPanel.tsx    - Merkle batching UI
StatsCard.tsx      - Stats display cards
```

**Total**: 6 components, fully styled with neobrutalism theme

---

## 🎯 Demo Flow

1. **Start backend**: `cd packages/kernel && cargo run`
2. **Start frontend**: `cd packages/frontend && npm run dev`
3. **Open**: http://localhost:3000
4. **Click**: "AUTHENTICATE WITH DID"
5. **Click**: "CREATE PATIENT" tab
6. **Fill form** and submit
7. **See**: Generated DID and Ed25519 public key!
8. **Click**: "ANCHOR BATCH" tab
9. **Click**: "CREATE MERKLE BATCH"
10. **See**: Merkle root hash and tx hash!

**Done in 2 minutes!** 🎉

---

## 🎨 Color Scheme

```
Black:  #000000  - Borders, buttons, text
White:  #FFFFFF  - Backgrounds, button text
Gray:   #F5F5F5  - Info boxes, subtle backgrounds
```

**Pure neobrutalism** - No colors, just black and white! ✅

---

## ✨ What Makes It Special

✅ **Shows Real Data**:
- Actual IOTA DIDs: `did:iota:anima:{uuid}`
- Real Ed25519 keys (64-char hex)
- Merkle root hashes (SHA-256)
- Transaction hashes

✅ **Educational**:
- Explains authentication flow
- Shows Merkle tree process
- Displays openEHR composition
- Privacy-first messaging

✅ **Professional**:
- Clean, modern design
- Bold, confident aesthetic
- Responsive layout
- Accessible typography

---

## 🏆 Hackathon Ready

**This dashboard showcases**:
- IOTA DID authentication
- Unique DID per patient
- Real cryptographic keys
- openEHR compositions
- Merkle tree anchoring
- Privacy-preserving design

**All in a bold, modern neobrutalism UI!** 🎨⛓️

---

**Start now**: `npm install && npm run dev` 🚀

