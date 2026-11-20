# Step 1: Create Oracle Cloud Free Tier VM (Manual - 5 min)

## 1. Sign Up
1. Go to: https://cloud.oracle.com/free
2. Click "Start for free"
3. Sign in or create Oracle account
4. **Verify with phone + credit card** (no charge for Always Free)
5. Select home region (choose closest to you)

## 2. Create VM Instance
1. In Oracle Console → **Instances** → **Create Instance**
2. **Name**: `asil-agent`
3. **Compartment**: Your compartment
4. **Placement**: Availability domain 1
5. **Image**: **Ubuntu 22.04** (Canonical Ubuntu)
6. **Shape**: **Ampere (ARM)** → **VM.Standard.A1.Flex**
   - OCPUs: **4** (max free)
   - Memory: **24 GB** (max free)
7. **Networking**: Create new VCN → **Public subnet**
8. **SSH Keys**: Paste your public key (`~/.ssh/id_rsa.pub`)
   - Generate if needed: `ssh-keygen -t ed25519`
9. Click **Create**

## 3. Note These Values
After creation, copy:
- **Public IP**: `xxx.xxx.xxx.xxx`
- **Private IP**: `10.0.x.x`
- **Username**: `ubuntu`

## 4. Open Ports (Ingress Rules)
In VCN → Security Lists → Default Security List → Add Ingress Rules:
| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH |
| 49374 | TCP | OpenCode MCP |
| 443 | TCP | HTTPS (optional) |
| 80 | TCP | HTTP (optional) |

**Source CIDR**: `0.0.0.0/0` (or restrict to your Tailscale IPs later)

---

## Next: Run `./02-setup-vm.sh` on the VM via SSH