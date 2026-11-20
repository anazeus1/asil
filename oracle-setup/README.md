# Asil on Oracle Cloud Free Tier - Complete Setup

**Cost: $0 forever** | **Always On** | **Your Real Browser** | **Secure Access**

---

## 🎯 What This Gives You

- **24/7 Asil agent** running on Oracle Free Tier (4 ARM CPU, 24GB RAM)
- **Your actual Brave browser** with all passwords, extensions, logins
- **Secure remote access** via Tailscale (no open ports to internet)
- **Full OpenCode + Browse MCP** - browser automation from anywhere
- **VS Code / Cursor / Claude Code** can connect remotely

---

## 📋 Prerequisites

- Oracle Cloud account (free tier eligible)
- SSH key pair (`~/.ssh/id_ed25519.pub`)
- Local Brave browser with your profiles
- 30 minutes for initial setup

---

## 🚀 Quick Start (Copy-Paste)

### 1. Create Oracle VM (Manual - 5 min)
Follow: [`01-create-vm.md`](01-create-vm.md)

### 2. Run VM Setup (Automated)
```bash
# On your LOCAL machine - replace with your VM's public IP
VM_IP="xxx.xxx.xxx.xxx"

# Run setup script on VM
ssh ubuntu@$VM_IP "bash -s" < 02-setup-vm.sh
```

### 3. Sync Brave Profile (Automated)
```bash
# On your LOCAL machine (PowerShell as Admin)
$VM_IP = "xxx.xxx.xxx.xxx"
$zipPath = "$env:TEMP\brave-profile.tar.gz"

tar -czf $zipPath -C "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data" `
  --exclude="*Cache*" --exclude="*lock*" --exclude="*Crash*" --exclude="*Log*" `
  --exclude="*.log" --exclude="*Session*" --exclude="*History*" "Default"

scp $zipPath ubuntu@$VM_IP:~/

ssh ubuntu@$VM_IP << 'EOF'
mkdir -p ~/.config/BraveSoftware/Brave-Browser
tar -xzf ~/brave-profile.tar.gz -C ~/.config/BraveSoftware/Brave-Browser/
chown -R ubuntu:ubuntu ~/.config/BraveSoftware
rm ~/brave-profile.tar.gz
systemctl --user restart opencode-asil
EOF
```

### 4. Setup Tailscale (2 min)
```bash
# On VM
ssh ubuntu@$VM_IP "sudo tailscale up --qr"
# Scan QR with Tailscale app on phone

# On your devices: install Tailscale, sign in with same account
```

### 5. Connect & Use
```bash
# Get Tailscale IP
TAILSCALE_IP=$(ssh ubuntu@$VM_IP "tailscale ip -4")

# Test
curl http://$TAILSCALE_IP:49374/health

# In VS Code/Cursor: OpenCode extension → Connect to http://$TAILSCALE_IP:49374
# In Claude Code: Add MCP server http://$TAILSCALE_IP:49374
```

---

## 📁 File Structure

```
oracle-setup/
├── README.md              # This file
├── 01-create-vm.md        # Oracle Cloud VM creation (manual)
├── 02-setup-vm.sh         # Automated VM provisioning script
├── 03-sync-profile.md     # Brave profile sync instructions
└── 04-tailscale-connect.md # Tailscale setup & remote access
```

---

## 🔧 Management Commands

```bash
# SSH to VM
ssh ubuntu@$VM_IP

# Check status
~/asil-workspace/status.sh

# View live logs
~/asil-workspace/logs.sh

# Restart Asil
systemctl --user restart opencode-asil

# Update code
cd ~/asil-workspace && git pull && systemctl --user restart opencode-asil

# Get Tailscale IP
tailscale ip -4
```

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| Brave won't start | `journalctl --user -u opencode-asil -f` |
| Profile not loaded | Verify `~/.config/BraveSoftware/Brave-Browser/User Data/Default` exists |
| Can't connect | Check Tailscale: `tailscale ping <ip>` |
| Port 49374 blocked | Oracle Security List → Add ingress for 49374 |
| Out of memory | Free tier has 24GB - should be plenty |

---

## 💰 Cost Breakdown

| Resource | Free Tier Limit | Cost |
|----------|-----------------|------|
| ARM Compute | 4 OCPU, 24GB RAM | $0 |
| Block Storage | 200 GB | $0 |
| Outbound Data | 10 TB/mo | $0 |
| **Total** | | **$0/month forever** |

---

## 🔐 Security

- **Tailscale**: WireGuard mesh, zero trust
- **No public ports** needed for MCP
- **Oracle Firewall**: Restrict to Tailscale CIDR (`100.64.0.0/10`)
- **Profile encryption**: Brave encrypts passwords with OS keyring

---

## 🎉 You're Done!

Once complete, you have:
- ✅ Asil running 24/7 in cloud
- ✅ Your real Brave with all logins
- ✅ Secure access from phone/laptop/anywhere
- ✅ Full browser automation via MCP
- ✅ $0 monthly cost

**Run Asil from anywhere**: VS Code, Cursor, Claude Code, terminal, phone...