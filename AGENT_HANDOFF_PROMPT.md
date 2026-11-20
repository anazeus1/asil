# Agent Handoff Prompt: Oracle Cloud Free Tier Setup for Asil

## 🎯 Mission
Set up a **24/7 Asil agent on Oracle Cloud Free Tier** with:
- Your real Brave browser (passwords, extensions, logins)
- Secure remote access via Tailscale
- Full browser automation via Browse MCP
- $0/month forever

---

## 📋 Prerequisites (You Provide)
- Oracle Cloud account (Free Tier eligible)
- SSH key pair (`~/.ssh/id_ed25519.pub`)
- Local Brave browser with your profiles
- NVIDIA API key for Basir vision (from https://build.nvidia.com)

---

## 🚀 Phase 1: Oracle VM Creation (Manual - 5 min)

### In Oracle Console (https://cloud.oracle.com):
1. ☰ → **Compute** → **Instances** → **Create Instance**
2. Fill exactly:
   - **Name**: `asil-agent`
   - **Image**: **Canonical Ubuntu** → **Ubuntu 22.04**
   - **Shape**: **Ampere (ARM)** → **VM.Standard.A1.Flex**
   - **OCPUs**: **4** (max)
   - **Memory**: **24 GB** (max)
   - **Network**: Create new VCN → Public subnet
   - **SSH Keys**: Paste `cat ~/.ssh/id_ed25519.pub` output
3. **Create** → Wait for "Running"
4. **Open Ports** (VCN → Security Lists → Default → Add Ingress Rules):
   | Port | Protocol | Source CIDR | Purpose |
   |------|----------|-------------|---------|
   | 22 | TCP | 0.0.0.0/0 | SSH |
   | 49374 | TCP | 100.64.0.0/10 | OpenCode MCP |
   | 41641 | UDP | 0.0.0.0/0 | Tailscale |
5. **Copy Public IP** (e.g., `129.146.xxx.xxx`)

### If No Public IP:
- Networking → Subnets → subnet-asil → Edit → Access Type: **Public** → Save
- Instance → Attached VNICs → Edit VNIC → Public IP: **Create new** → Save
- Restart instance

---

## 🤖 Phase 2: Automated VM Setup (Run from Local)

```bash
# Replace with YOUR VM Public IP
VM_IP="xxx.xxx.xxx.xxx"

# Run complete setup script on VM (3-5 min)
ssh ubuntu@$VM_IP "bash -s" < oracle-setup/vm-complete-setup.sh
```

This installs: Brave, Node.js 20, OpenCode, Browse MCP, Xvfb, Tailscale, firewall, auto-updates, systemd services.

---

## 🦁 Phase 3: Sync Brave Profile + Local Tailscale (Local Machine)

```powershell
# Run as Administrator in PowerShell
cd C:\Users\main laptop\programation\opencode\agents\Asil

# Set your VM IP
$VM_IP = "xxx.xxx.xxx.xxx"

# Run automated sync script
.\oracle-setup\setup-all.ps1 -VmIp $VM_IP
```

This:
- Zips your Brave profile (excludes cache/locks)
- Uploads to VM
- Extracts to `~/.config/BraveSoftware/Brave-Browser/`
- Restarts Asil service
- Installs Tailscale locally
- Connects both to same Tailscale network

---

## 🔒 Phase 4: Tailscale Authentication

```bash
# On VM - authenticate Tailscale
ssh ubuntu@$VM_IP "sudo tailscale up --qr"
# Scan QR code with Tailscale app on phone

# Verify connection
tailscale ping <vm-tailscale-ip>
```

---

## 🎯 Phase 5: Connect & Use

### Get VM Tailscale IP:
```bash
VM_TS_IP=$(ssh ubuntu@$VM_IP "tailscale ip -4")
echo "MCP Endpoint: http://$VM_TS_IP:49374"
```

### Connect Clients:
| Client | Config |
|--------|--------|
| **VS Code / Cursor** | OpenCode extension → Connect to `http://$VM_TS_IP:49374` |
| **Claude Code** | Add MCP server: `http://$VM_TS_IP:49374` |
| **Terminal** | `curl http://$VM_TS_IP:49374/mcp/tools` |

### Test Browser Automation:
```bash
# From any connected client
curl -X POST http://$VM_TS_IP:49374/mcp/tools/browse.navigate \
  -H "Content-Type: application/json" \
  -d '{"url": "https://github.com"}'
```

---

## 🔧 Phase 6: Basir Vision (Optional)

```powershell
# Set NVIDIA API key (same for chat + vision)
$env:NVIDIA_API_KEY = "your-key-from-build-nvidia-com"

# Analyze Oracle console screenshot
cd C:\Users\main laptop\programation\opencode\agents\Asil
# Take screenshot of Oracle tab (Win+Shift+S) → save as oracle.png
node vision/analyze.js oracle.png "Extract the Public IP address. Return ONLY xxx.xxx.xxx.xxx"
```

---

## 📁 Key Files in Repo

```
oracle-setup/
├── README.md                 # Complete guide
├── 01-create-vm.md           # Manual VM creation
├── 02-setup-vm.sh            # VM provisioning script
├── vm-complete-setup.sh      # Single-script VM setup
├── 03-sync-profile.md        # Brave profile sync
├── 04-tailscale-connect.md   # Tailscale setup
├── setup-all.ps1             # Local automated sync
└── vision/
    ├── analyze.js            # Basir core (Nemotron VL)
    ├── browse-vision.js      # Browse MCP integration
    └── basir-capture.js      # Capture + analyze
```

---

## ✅ Success Criteria

- [ ] Oracle VM running (4 ARM CPU, 24GB RAM)
- [ ] Public IP assigned
- [ ] Brave running with YOUR profile (logins work)
- [ ] OpenCode + Browse MCP running as service
- [ ] Tailscale connected on VM + local
- [ ] MCP accessible at `http://100.x.x.x:49374`
- [ ] VS Code/Claude Code can connect remotely
- [ ] Browser automation works (GitHub, etc.)

---

## 💰 Cost Verification

| Resource | Free Tier | Your Cost |
|----------|-----------|-----------|
| ARM Compute | 4 OCPU, 24GB | $0 |
| Block Storage | 200 GB | $0 |
| Outbound Data | 10 TB/mo | $0 |
| **Total** | | **$0/month forever** |

---

## 🆘 Troubleshooting

| Issue | Fix |
|-------|-----|
| Brave won't start | `journalctl --user -u opencode-asil -f` |
| Profile not loaded | Check `~/.config/BraveSoftware/Brave-Browser/User Data/Default` |
| Can't connect | `tailscale ping <ip>` |
| Port 49374 blocked | Oracle Security List → Add ingress 49374 from 100.64.0.0/10 |
| No Public IP | Subnet → Edit → Access Type: Public |

---

## 🎉 Result

**Asil runs 24/7 in cloud with YOUR real browser** - accessible securely from anywhere via Tailscale. Zero monthly cost.