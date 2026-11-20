# Step 4: Tailscale Setup & Remote Access

## 1. On VM: Authenticate Tailscale

```bash
ssh ubuntu@YOUR_VM_IP

# Start Tailscale (opens browser link for auth)
sudo tailscale up

# If headless, use:
sudo tailscale up --qr
# Scan QR code with Tailscale app on phone

# Or get auth key from https://login.tailscale.com/admin/settings/keys
sudo tailscale up --authkey=tskey-xxx...
```

## 2. Get VM's Tailscale IP

```bash
tailscale ip -4
# Output: 100.x.x.x  (this is your permanent private IP)
```

## 3. Install Tailscale on Your Devices

| Device | Install |
|--------|---------|
| **Windows** | https://tailscale.com/download/windows |
| **macOS** | https://tailscale.com/download/mac |
| **Linux** | `curl -fsSL https://tailscale.com/install.sh \| sh` |
| **iOS** | App Store → Tailscale |
| **Android** | Play Store → Tailscale |

Sign in with **same account** (Google/GitHub/Microsoft).

## 4. Verify Connection

```bash
# On ANY device with Tailscale
tailscale ping 100.x.x.x  # VM's Tailscale IP

# Access OpenCode MCP
curl http://100.x.x.x:49374/health
# Should return: {"status":"ok"}
```

## 5. Connect IDE/Clients to Remote Asil

### VS Code / Cursor (OpenCode Extension)
1. Install **OpenCode** extension
2. `Ctrl+Shift+P` → "OpenCode: Connect to Server"
3. Enter: `http://100.x.x.x:49374`

### Claude Code / Zed / Other MCP Clients
Add to MCP config:
```json
{
  "mcpServers": {
    "asil-remote": {
      "url": "http://100.x.x.x:49374"
    }
  }
}
```

### Direct API Access
```bash
# List tools
curl http://100.x.x.x:49374/mcp/tools

# Call browse.navigate
curl -X POST http://100.x.x.x:49374/mcp/tools/browse.navigate \
  -H "Content-Type: application/json" \
  -d '{"url": "https://github.com"}'
```

## 6. Optional: Expose via HTTPS (Cloudflare Tunnel)

If you need public HTTPS without Tailscale:

```bash
# On VM
cloudflared tunnel login
cloudflared tunnel create asil-agent
cloudflared tunnel route dns asil-agent asil.yourdomain.com

# Run as service
sudo tee /etc/systemd/system/cloudflared.service << 'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudflared tunnel run asil-agent
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable --now cloudflared
```

Now access at: `https://asil.yourdomain.com`

---

## Quick Reference Card

| Task | Command |
|------|---------|
| **Check status** | `~/asil-workspace/status.sh` |
| **View logs** | `~/asil-workspace/logs.sh` |
| **Restart Asil** | `systemctl --user restart opencode-asil` |
| **VM Tailscale IP** | `tailscale ip -4` |
| **All Tailscale peers** | `tailscale status` |
| **Update Asil code** | `cd ~/asil-workspace && git pull && systemctl --user restart opencode-asil` |
| **VM Public IP** | `curl ifconfig.me` |

---

## Security Notes

- **Tailscale**: Encrypted mesh, only your devices can connect
- **Oracle Security Lists**: Restrict port 49374 to Tailscale CIDR (`100.64.0.0/10`)
- **No public exposure**: MCP only accessible via Tailscale
- **Auto-updates**: `unattended-upgrades` enabled by default on Ubuntu

```bash
# Restrict Oracle firewall to Tailscale only (run on VM)
sudo iptables -A INPUT -p tcp --dport 49374 -s 100.64.0.0/10 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 49374 -j DROP
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```