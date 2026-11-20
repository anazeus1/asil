<#
.SYNOPSIS
    Complete Oracle Cloud setup for Asil Agent - Run on LOCAL Windows machine
.DESCRIPTION
    This script automates the local-side setup:
    1. Zips and uploads Brave profile to VM
    2. Configures Tailscale on local machine
    3. Tests connection
.NOTES
    Run as Administrator in PowerShell
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$VmIp,

    [Parameter(Mandatory=$false)]
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519",

    [Parameter(Mandatory=$false)]
    [string]$BraveProfilePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
)

Write-Host "🚀 Asil Oracle Cloud Setup - Local Side" -ForegroundColor Cyan
Write-Host "VM IP: $VmIp" -ForegroundColor Yellow

# --------------------------------------------
# 1. Validate Prerequisites
# --------------------------------------------
Write-Host "`n📋 Checking prerequisites..." -ForegroundColor Cyan

if (-not (Test-Path $SshKeyPath)) {
    Write-Error "SSH key not found at $SshKeyPath"
    Write-Host "Generate with: ssh-keygen -t ed25519" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $BraveProfilePath)) {
    Write-Error "Brave profile not found at $BraveProfilePath"
    exit 1
}

# Check SSH connectivity
try {
    $sshTest = ssh -i $SshKeyPath -o ConnectTimeout=5 -o BatchMode=yes ubuntu@$VmIp "echo OK" 2>$null
    if ($sshTest -ne "OK") { throw "SSH failed" }
    Write-Host "✅ SSH connection OK" -ForegroundColor Green
} catch {
    Write-Error "Cannot SSH to $VmIp. Check IP, key, and security groups."
    exit 1
}

# --------------------------------------------
# 2. Sync Brave Profile
# --------------------------------------------
Write-Host "`n🦁 Syncing Brave profile..." -ForegroundColor Cyan

$zipPath = "$env:TEMP\brave-profile-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar.gz"

Write-Host "Creating archive (excluding cache/locks)..."
tar -czf $zipPath -C $BraveProfilePath `
    --exclude="*Cache*" `
    --exclude="*lock*" `
    --exclude="*Crash*" `
    --exclude="*Log*" `
    --exclude="*.log" `
    --exclude="*Session*" `
    --exclude="*History*" `
    --exclude="GPUCache" `
    --exclude="ShaderCache" `
    "Default" 2>$null

$sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
Write-Host "Archive size: $sizeMB MB" -ForegroundColor Yellow

Write-Host "Uploading to VM..."
scp -i $SshKeyPath $zipPath ubuntu@$VmIp:~/brave-profile.tar.gz

Write-Host "Extracting on VM..."
ssh -i $SshKeyPath ubuntu@$VmIp @"
    mkdir -p ~/.config/BraveSoftware/Brave-Browser
    tar -xzf ~/brave-profile.tar.gz -C ~/.config/BraveSoftware/Brave-Browser/
    chown -R ubuntu:ubuntu ~/.config/BraveSoftware
    rm ~/brave-profile.tar.gz
    systemctl --user restart opencode-asil
"@

Remove-Item $zipPath -Force
Write-Host "✅ Brave profile synced and Asil restarted" -ForegroundColor Green

# --------------------------------------------
# 3. Install/Configure Tailscale (Local)
# --------------------------------------------
Write-Host "`n🔒 Setting up Tailscale..." -ForegroundColor Cyan

if (-not (Get-Command "tailscale" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Tailscale..."
    winget install --id Tailscale.Tailscale --silent --accept-source-agreements --accept-package-agreements 2>$null
    # Or: msiexec /i https://pkgs.tailscale.com/stable/tailscale-setup-latest.msi /quiet
    Write-Host "✅ Tailscale installed" -ForegroundColor Green
} else {
    Write-Host "✅ Tailscale already installed" -ForegroundColor Green
}

Write-Host "Starting Tailscale (sign in with same account as VM)..."
tailscale up --accept-dns=false

# Get local Tailscale IP
$localTsIp = tailscale ip -4 2>$null | Select-Object -First 1
Write-Host "Your local Tailscale IP: $localTsIp" -ForegroundColor Yellow

# --------------------------------------------
# 4. Verify VM Connection
# --------------------------------------------
Write-Host "`n🔍 Verifying VM connection..." -ForegroundColor Cyan

$vmTsIp = ssh -i $SshKeyPath ubuntu@$VmIp "tailscale ip -4" 2>$null | Select-Object -First 1
Write-Host "VM Tailscale IP: $vmTsIp" -ForegroundColor Yellow

# Test MCP endpoint
$health = Invoke-RestMethod -Uri "http://$vmTsIp:49374/health" -TimeoutSec 10 -ErrorAction SilentlyContinue
if ($health.status -eq "ok") {
    Write-Host "✅ OpenCode MCP responding at http://$vmTsIp:49374" -ForegroundColor Green
} else {
    Write-Warning "MCP not responding yet. Check logs: ssh ubuntu@$VmIp 'journalctl --user -u opencode-asil -f'"
}

# --------------------------------------------
# 5. Summary
# --------------------------------------------
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎉 SETUP COMPLETE!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"
📋 CONNECTION INFO:
   VM Public IP:      $VmIp
   VM Tailscale IP:   $vmTsIp
   Your Tailscale IP: $localTsIp
   OpenCode MCP:      http://$vmTsIp:49374

🔗 CONNECT FROM:
   • VS Code/Cursor: OpenCode extension → Connect to http://$vmTsIp:49374
   • Claude Code:    Add MCP server http://$vmTsIp:49374
   • Terminal:       curl http://$vmTsIp:49374/mcp/tools
   • Browser:        http://$vmTsIp:49374 (if enabled)

📝 USEFUL COMMANDS:
   Check status:     ssh ubuntu@$VmIp '~/asil-workspace/status.sh'
   View logs:        ssh ubuntu@$VmIp 'journalctl --user -u opencode-asil -f'
   Restart Asil:     ssh ubuntu@$VmIp 'systemctl --user restart opencode-asil'
   Update code:      ssh ubuntu@$VmIp 'cd ~/asil-workspace && git pull && systemctl --user restart opencode-asil'

💰 COST: \$0/month forever (Oracle Free Tier)
"@

Write-Host "`n🎯 Asil is now running 24/7 with YOUR Brave browser!" -ForegroundColor Green