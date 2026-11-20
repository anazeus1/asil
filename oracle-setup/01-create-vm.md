# Step 1: Create Oracle Cloud Free Tier VM (Manual - 5 min)

## ⚠️ CRITICAL OCI Constraints (Read First)
| Constraint | Impact |
|------------|--------|
| **Subnet access type (Public/Private) is IMMUTABLE** | If created as Private → CANNOT change. Must recreate subnet + instance. |
| **Primary VNIC cannot be moved/detached** | Wrong subnet = new instance required. |
| **Public IP needs 3 things**: Public Subnet + Route Table (IGW) + Security List ingress | Missing any = no public access. |

**Verify with CLI after creation:**
```bash
oci network subnet get --subnet-id <ocid> --query "data.\"prohibit-public-ip-on-vnic\""
# Returns: false = Public, true = Private
```

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
7. **Networking**: 
   - **Create new VCN** → **Public subnet** ⚠️ **MUST SELECT "Public subnet"**
   - Verify: "Assign public IPv4 address" = **Yes**
8. **SSH Keys**: Paste your public key (`~/.ssh/id_ed25519.pub`)
   - Generate if needed: `ssh-keygen -t ed25519`
9. Click **Create**

## 3. Verify Subnet is Public (Before Proceeding)
```bash
# After instance shows "Running", run locally:
VM_IP="xxx.xxx.xxx.xxx"
ssh ubuntu@$VM_IP "oci network subnet list --compartment-id $(oci iam compartment list --query 'data[0].id' --raw-output) --query 'data[?contains(\"display-name\", `asil`)].{\"prohibit-public-ip-on-vnic\"}' --raw-output"
# Must return: false
```

If returns `true` → **Subnet is Private → DELETE INSTANCE + VCN + START OVER**

## 4. Note These Values
After creation, copy:
- **Public IP**: `xxx.xxx.xxx.xxx`
- **Private IP**: `10.0.x.x`
- **Username**: `ubuntu`

## 5. Open Ports (Ingress Rules)
In VCN → Security Lists → Default Security List → Add Ingress Rules:
| Port | Protocol | Source CIDR | Purpose |
|------|----------|-------------|---------|
| 22 | TCP | 0.0.0.0/0 | SSH |
| 49374 | TCP | 100.64.0.0/10 | OpenCode MCP (Tailscale only) |
| 41641 | UDP | 0.0.0.0/0 | Tailscale |

---

## Next: Run `./02-setup-vm.sh` on the VM via SSH