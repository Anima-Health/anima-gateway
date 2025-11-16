# Deploy to Fly.io (RECOMMENDED)

## 🚀 Yes, Fly.io Uses Your Dockerfile!

Fly.io **automatically detects and uses your Dockerfile** for deployment.

---

## ⚡ Quick Deploy (5 Minutes)

### **Step 1: Install Fly CLI**

```bash
# macOS/Linux
curl -L https://fly.io/install.sh | sh

# Or with Homebrew
brew install flyctl
```

### **Step 2: Login**

```bash
fly auth login
```

### **Step 3: Launch App**

```bash
cd packages/kernel

# This will use your Dockerfile automatically
fly launch --name anima-health-kernel --region lhr

# Follow prompts:
# - Would you like to copy configuration?: Yes (uses fly.toml)
# - Would you like to set up a PostgreSQL database?: No
# - Would you like to deploy now?: Yes
```

### **Step 4: Deploy**

```bash
fly deploy
```

**That's it!** Your app is live at: `https://anima-health-kernel.fly.dev`

---

## 🐳 What Fly.io Does

```
1. Reads your Dockerfile ✅
2. Builds Docker image in the cloud
3. Pushes to Fly.io registry
4. Deploys to edge locations globally
5. Provides HTTPS automatically
6. Gives you: https://anima-health-kernel.fly.dev
```

**You don't need to wait for local Docker build!** Fly.io builds it in the cloud with powerful machines.

---

## ⚙️ Configuration

The `fly.toml` file I created configures:
- ✅ Port 8080
- ✅ Auto HTTPS
- ✅ Auto-scaling (scales to 0 when idle - free tier!)
- ✅ Health checks
- ✅ 512MB RAM

---

## 🔧 Useful Commands

```bash
# Deploy
fly deploy

# Check status
fly status

# View logs
fly logs

# Open in browser
fly open

# SSH into machine
fly ssh console

# Scale up
fly scale count 2

# Scale memory
fly scale memory 1024

# Set secrets
fly secrets set REDUCT_TOKEN=your-token
fly secrets set IOTA_MNEMONIC="your twelve words here"
```

---

## 💰 Cost

**Free tier includes**:
- ✅ Up to 3 shared-cpu-1x 256MB VMs
- ✅ 160GB outbound data transfer
- ✅ Auto HTTPS certificates
- ✅ Global Anycast IPs

**Your app**: Uses 512MB, scales to 0 when idle → **FREE** ✅

---

## 🎯 For Hackathon

**Deploy NOW**:

```bash
cd packages/kernel
fly launch
fly deploy
```

**Share this URL in your presentation**:
```
https://anima-health-kernel.fly.dev/health
https://anima-health-kernel.fly.dev/api/info
```

**The Docker build on Fly.io is FAST** (their servers are powerful) - unlike local Docker which is slow!

---

## ✅ Fly.io Uses Docker

**Your Dockerfile** → **Fly.io builds it** → **Deployed globally**

No need to wait for local Docker build! 🚀

