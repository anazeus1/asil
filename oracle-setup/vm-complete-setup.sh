#!/bin/bash
# ============================================
# COMPLETE VM Setup for Asil Agent
# Run ON THE VM: curl -fsSL <url> | bash
# Or: ssh ubuntu@<ip> "bash -s" < vm-complete-setup.sh
# ============================================

set -euo pipefail

LOG_FILE="/var/log/asil-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================"
echo "🚀 Asil Agent - Complete Oracle VM Setup"
echo "Started: $(date)"
echo "============================================"

# --------------------------------------------
# Helper Functions
# --------------------------------------------
log() { echo "[$(date '+%H:%M:%S')] $*"; }
success() { log "✅ $*"; }
warn() { log "⚠️  $*"; }
error() { log "❌ $*"; exit 1; }

# --------------------------------------------
# 1. System Prep
# --------------------------------------------
log "📦 Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    curl wget gnupg2 software-properties-common \
    xvfb x11vnc novnc websockify \
    git build-essential unzip \
    fonts-liberation fonts-noto-color-emoji \
    dbus-x11 libgtk-3-0 libnss3 libxss1 libasound2 \
    htop iotop ncdu

success "System updated"

# --------------------------------------------
# 2. Brave Browser
# --------------------------------------------
log "🦁 Installing Brave Browser..."
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=arm64] \
    https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    tee /etc/apt/sources.list.d/brave-browser-release.list
apt-get update -y
apt-get install -y brave-browser

# Verify
brave-browser --version
success "Brave installed"

# --------------------------------------------
# 3. Node.js 20 LTS
# --------------------------------------------
log "📦 Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify
node --version
npm --version
success "Node.js installed"

# --------------------------------------------
# 4. OpenCode + Browse MCP
# --------------------------------------------
log "🤖 Installing OpenCode + Browse MCP..."
npm install -g @opencode/browse

# Run browse install (non-interactive)
browse install --yes 2>&1 | tail -20

# Verify
opencode --version
browse --version
success "OpenCode + Browse installed"

# --------------------------------------------
# 5. Tailscale
# --------------------------------------------
log "🔒 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

success "Tailscale installed (run 'sudo tailscale up' after)"

# --------------------------------------------
# 6. Virtual Display (Xvfb)
# --------------------------------------------
log "🖥️ Setting up Xvfb..."
cat > /etc/systemd/system/xvfb.service << 'EOF'
[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now xvfb
sleep 3
systemctl status xvfb --no-pager
success "Xvfb running on :99"

# --------------------------------------------
# 7. Workspace & Repo
# --------------------------------------------
log "📁 Setting up workspace..."
sudo -u ubuntu bash << 'USEREOF'
cd /home/ubuntu
mkdir -p asil-workspace
cd asil-workspace

# Clone repo
if [ ! -d ".git" ]; then
    git clone https://github.com/anazeus1/asil.git .
fi

# Install deps (skip if node_modules exists)
if [ ! -d "node_modules" ]; then
    npm ci 2>/dev/null || npm install
fi

# Helper scripts
cat > start-asil.sh << 'SCRIPTEOF'
#!/bin/bash
export DISPLAY=:99
cd /home/ubuntu/asil-workspace
exec opencode serve --hostname 0.0.0.0 --port 49374
SCRIPTEOF
chmod +x start-asil.sh

cat > status.sh << 'SCRIPTEOF'
#!/bin/bash
echo "=== OpenCode Service ==="
systemctl --user status opencode-asil --no-pager 2>/dev/null || echo "Not running"
echo ""
echo "=== Xvfb ==="
systemctl status xvfb --no-pager | head -10
echo ""
echo "=== Tailscale ==="
tailscale status 2>/dev/null || echo "Not connected"
echo ""
echo "=== Ports ==="
ss -tlnp | grep -E '(49374|22)'
SCRIPTEOF
chmod +x status.sh

cat > logs.sh << 'SCRIPTEOF'
#!/bin/bash
journalctl --user -u opencode-asil -f
SCRIPTEOF
chmod +x logs.sh

USEREOF

success "Workspace ready"

# --------------------------------------------
# 8. OpenCode Systemd Service
# --------------------------------------------
log "⚙️ Creating OpenCode service..."
sudo -u ubuntu bash << 'USEREOF'
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/opencode-asil.service << 'SVC_EOF'
[Unit]
Description=OpenCode Asil Agent with Browse MCP
After=network.target xvfb.service
Requires=xvfb.service

[Service]
Type=simple
Environment=DISPLAY=:99
Environment=BROWSER_EXECUTABLE=/usr/bin/brave-browser
Environment=BROWSER_ARGS="--no-sandbox --disable-gpu --disable-dev-shm-usage --user-data-dir=/home/ubuntu/.config/BraveSoftware/Brave-Browser/User Data --profile-directory=Default"
ExecStart=/home/ubuntu/.local/bin/opencode serve --hostname 0.0.0.0 --port 49374
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SVC_EOF

# Enable lingering
loginctl enable-linger ubuntu

# Start service
systemctl --user daemon-reload
systemctl --user enable --now opencode-asil

USEREOF

success "OpenCode service created"

# --------------------------------------------
# 9. Firewall (Optional - restrict to Tailscale)
# --------------------------------------------
log "🔥 Configuring firewall..."
apt-get install -y iptables-persistent

# Allow SSH, Tailscale, and MCP from Tailscale CIDR only
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 49374 -s 100.64.0.0/10 -j ACCEPT
iptables -A INPUT -p tcp --dport 49374 -j DROP
iptables -A INPUT -p udp --dport 41641 -j ACCEPT  # Tailscale
netfilter-persistent save

success "Firewall configured (port 49374 restricted to Tailscale)"

# --------------------------------------------
# 10. Auto-update (Security)
# --------------------------------------------
log "🔄 Enabling auto-updates..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades

success "Auto-updates enabled"

# --------------------------------------------
# 11. Final Verification
# --------------------------------------------
log "🔍 Running verification..."
sleep 5

echo ""
echo "=== Service Status ==="
systemctl --user status opencode-asil --no-pager || true

echo ""
echo "=== Xvfb Status ==="
systemctl status xvfb --no-pager | head -5

echo ""
echo "=== Port 49374 ==="
ss -tlnp | grep 49374 || echo "Not listening yet"

echo ""
echo "=== Tailscale ==="
tailscale status 2>/dev/null || echo "Run: sudo tailscale up"

# Test MCP
if curl -sf http://localhost:49374/health >/dev/null 2>&1; then
    success "MCP endpoint responding!"
else
    warn "MCP not responding yet - check logs with: journalctl --user -u opencode-asil -f"
fi

# --------------------------------------------
# Complete
# --------------------------------------------
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not connected")
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")

cat << EOF

============================================
🎉 SETUP COMPLETE!
============================================

📊 SYSTEM INFO:
   Public IP:      $PUBLIC_IP
   Tailscale IP:   $TAILSCALE_IP
   MCP Endpoint:   http://$TAILSCALE_IP:49374 (via Tailscale)
   Workspace:      /home/ubuntu/asil-workspace

🔧 MANAGEMENT:
   Status:     ~/asil-workspace/status.sh
   Logs:       ~/asil-workspace/logs.sh
   Restart:    systemctl --user restart opencode-asil
   Update:     cd ~/asil-workspace && git pull && systemctl --user restart opencode-asil

📋 NEXT STEPS:
   1. Run: sudo tailscale up --qr
   2. Scan QR with Tailscale app on phone
   3. Sync Brave profile from local (see 03-sync-profile.md)
   4. Connect VS Code/Claude Code to http://$TAILSCALE_IP:49374

💰 COST: \$0/month forever (Oracle Free Tier)
============================================

Logs saved to: $LOG_FILE
EOF