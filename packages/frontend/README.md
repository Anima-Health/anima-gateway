# Anima Health - Frontend Dashboard

## 🎨 Neobrutalism UI in Black & White

Bold, modern dashboard showcasing IOTA DID healthcare provenance.

---

## 🚀 Quick Start

### **Terminal 1: Backend API**
```bash
cd ../kernel
cargo run
```

**Wait for**: `->> Listening on 0.0.0.0:8080`

### **Terminal 2: Frontend**
```bash
# Install dependencies (first time only)
npm install

# Run development server
npm run dev
```

**Open**: http://localhost:3000

---

## ✅ FULLY INTEGRATED

Frontend is now **connected to real backend API**!

---

## 🎯 Features

### **Login Screen**:
- ✅ IOTA DID authentication
- ✅ Challenge-response flow explanation
- ✅ Bold neobrutalism design

### **Dashboard**:
- ✅ **CREATE PATIENT** - Form with DID generation display
- ✅ **PATIENT LIST** - View all patients with DIDs
- ✅ **ANCHOR BATCH** - Merkle tree batching UI

### **Theme**:
- ✅ Black & white neobrutalism
- ✅ Thick black borders (4px)
- ✅ Brutal shadows (8px/12px offsets)
- ✅ Bold typography
- ✅ Geometric shapes
- ✅ High contrast

---

## 🎨 Design System

### **Colors**:
```
Primary: #000000 (black)
Background: #FFFFFF (white)
Accent: #F5F5F5 (light gray)
```

### **Shadows**:
```css
shadow-brutal: 4px 4px 0px 0px #000000
shadow-brutal-lg: 8px 8px 0px 0px #000000
shadow-brutal-xl: 12px 12px 0px 0px #000000
```

### **Components**:
- `btn-brutal` - Black button with shadow
- `btn-brutal-secondary` - White button with black border
- `card-brutal` - White card with thick border and shadow
- `input-brutal` - Input with border, shadow effect on focus
- `badge-brutal` - Small black badge

---

## 📦 Project Structure

```
src/
├── app/
│   ├── layout.tsx          # Root layout
│   ├── page.tsx            # Main page (router)
│   └── globals.css         # Global styles + neobrutalism
│
└── components/
    ├── LoginPage.tsx       # DID authentication UI
    ├── Dashboard.tsx       # Main dashboard shell
    ├── PatientForm.tsx     # Create patient with DID
    ├── PatientList.tsx     # View patients with DIDs
    ├── AnchorPanel.tsx     # Merkle batching UI
    └── StatsCard.tsx       # Stats display cards
```

---

## 🔗 API Integration

### **Proxy Configuration** (next.config.js):

```javascript
async rewrites() {
  return [
    {
      source: '/api/:path*',
      destination: 'http://localhost:8080/api/:path*',
    },
  ]
}
```

**Frontend**: `http://localhost:3000/api/patient`  
**Proxies to**: `http://localhost:8080/api/patient`

---

## 🎨 Screenshots

### **Login Screen**:
- Bold "ANIMA HEALTH" title
- DID input with explanation
- Authentication flow steps
- Black and white theme

### **Create Patient**:
- Form fields with neobrutalism styling
- Shows what will be created (DID, keys, openEHR)
- Success screen displays:
  - Generated IOTA DID
  - Real Ed25519 public key
  - openEHR composition details

### **Patient List**:
- Cards with thick borders
- Click to expand and see full DID + public key
- Shows key version, status

### **Anchor Batch**:
- Pending count display
- Merkle process explanation
- Success screen shows:
  - Merkle root hash (64-char hex)
  - Batch ID, record count
  - Transaction hash

---

## 🛠️ Tech Stack

- **Framework**: Next.js 14
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Icons**: Lucide React
- **Theme**: Neobrutalism (black & white)
- **API**: Axios for HTTP requests

---

## 🎯 Key UI Elements

### **Typography**:
- Headers: Font-black, uppercase
- Body: Font-medium/bold
- Code: Font-mono

### **Borders**:
- All elements: 4px black borders
- Cards: border-4
- Inputs: border-4
- Buttons: border-4

### **Shadows**:
- Cards: 8px/12px brutal shadow
- Buttons: 4px brutal shadow
- Hover: Shadow disappears, element translates

### **Interactions**:
- Hover: Translate + shadow removal
- Click: Visual feedback
- Focus: Border highlight

---

## 🚀 Deployment

### **Vercel** (Recommended):

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Production
vercel --prod
```

### **Environment Variables**:

```env
NEXT_PUBLIC_API_URL=https://your-api-url.com
```

---

## 📸 Design Inspiration

Based on:
- Neobrutalism design trend
- Bold typography
- High contrast black/white
- Geometric shapes
- Sharp, angular elements
- Thick borders and shadows

---

## ✅ Dashboard Features

✅ **IOTA DID Authentication** - Challenge-response flow  
✅ **Patient Creation** - Generates unique DID + Ed25519 keys  
✅ **DID Display** - Shows full IOTA DID and public key  
✅ **openEHR Visualization** - Composition details  
✅ **Merkle Anchoring** - Visual batch creation  
✅ **Stats Dashboard** - Patient count, pending anchors  
✅ **Neobrutalism Theme** - Bold, modern, accessible  

---

**Run**: `npm run dev` 🎨🚀

