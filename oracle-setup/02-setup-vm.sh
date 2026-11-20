#!/bin/bash
# ============================================
# Oracle Cloud VM Setup for Asil Agent
# Run on VM: ssh ubuntu@<public-ip> "bash -s" < 02-setup-vm.sh
# ============================================

set -euo pipefail

echo "🚀 Setting up Asil Agent on Oracle Cloud Free Tier..."

# --------------------------------------------
# 1. System Updates & Base Packages
# --------------------------------------------
echo "📦 Installing base packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
    curl wget gnupg2 software-properties-common \
    xvfb x11vnc novnc websockify \
    git build-essential unzip \
    fonts-liberation fonts-noto-color-emoji \
    dbus-x11 libgtk-3-0 libnss3 libxss1 libasound2

# --------------------------------------------
# 2. Install Brave Browser
# --------------------------------------------
echo "🦁 Installing Brave Browser..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=arm64] \
    https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt-get update -y
sudo apt-get install -y brave-browser

# --------------------------------------------
# 3. Install Node.js 20 (LTS)
# --------------------------------------------
echo "📦 Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# --------------------------------------------
# 4. Install OpenCode & Browse MCP
# --------------------------------------------
echo "🤖 Installing OpenCode + Browse MCP..."
npm install -g @opencode/browse
browse install  # Installs extension, configures OpenCode

# Verify installation
opencode --version
browse --version

# --------------------------------------------
# 5. Install Tailscale (Secure Mesh VPN)
# --------------------------------------------
echo "🔒 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# --------------------------------------------
# 6. Setup Virtual Display (for headless Brave)
# --------------------------------------------
echo "🖥️ Setting up virtual display..."
sudo tee /etc/systemd/system/xvfb.service > /dev/null << 'EOF'
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

sudo systemctl daemon-reload
sudo systemctl enable --now xvfb

# --------------------------------------------
# 7. Create Asil Working Directory
# --------------------------------------------
echo "📁 Creating workspace..."
mkdir -p ~/asil-workspace
cd ~/asil-workspace

# Clone the repo
git clone https://github.com/anazeus1/asil.git .
npm ci 2>/dev/null || npm install

# --------------------------------------------
# 8. Create OpenCode Service (runs as ubuntu user)
# --------------------------------------------
echo "⚙️ Creating OpenCode systemd service..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/opencode-asil.service << 'EOF'
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
EOF

# Enable lingering so service runs after logout
sudo loginctl enable-linger ubuntu

# Start user systemd
systemctl --user daemon-reload
systemctl --user enable --now opencode-asil

# --------------------------------------------
# 9. Create Helper Scripts
# --------------------------------------------
cat > ~/asil-workspace/start-asil.sh << 'EOF'
#!/bin/bash
# Start Asil with virtual display
export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
sleep 2
cd ~/asil-workspace
opencode serve --hostname 0.0.0.0 --port 49374
EOF
chmod +x ~/asil-workspace/start-asil.sh

cat > ~/asil-workspace/status.sh << 'EOF'
#!/bin/bash
echo "=== OpenCode Service ==="
systemctl --user status opencode-asil --no-pager
echo ""
echo "=== Xvfb Service ==="
systemctl status xvfb --no-pager
echo ""
echo "=== Tailscale Status ==="
tailscale status
echo ""
echo "=== Ports ==="
ss -tlnp | grep -E '(49374|22)'
EOF
chmod +x ~/asil-workspace/status.sh

cat > ~/asil-workspace/logs.sh << 'EOF'
#!/bin/bash
journalctl --user -u opencode-asil -f
EOF
chmod +x ~/asil-workspace/logs.sh

# --------------------------------------------
# 10. Final Status
# --------------------------------------------
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run Tailscale auth: tailscale up"
echo "2. Copy your Brave profile from local machine (see 03-sync-profile.md)"
echo "3. Restart service: systemctl --user restart opencode-asil"
echo "4. Check status: ~/asil-workspace/status.sh"
echo ""
echo "Access OpenCode MCP at: http://<tailscale-ip>:49374"