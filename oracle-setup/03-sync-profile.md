# Step 3: Sync Your Brave Profile (Run on LOCAL Machine)

## Option A: One-Command Sync (Recommended)

Run this **on your local Windows machine** (PowerShell as Admin):

```powershell
# 1. Set your VM IP
$vmIP = "xxx.xxx.xxx.xxx"  # Replace with your Oracle VM public IP

# 2. Zip and copy Brave profile
$profilePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
$zipPath = "$env:TEMP\brave-profile.tar.gz"

# Exclude cache/lock files
tar -czf $zipPath -C "$profilePath" --exclude="*Cache*" --exclude="*lock*" --exclude="*Crash*" --exclude="*Log*" --exclude="*.log" --exclude="*Session*" --exclude="*History*" "Default"

# Copy to VM
scp $zipPath ubuntu@$vmIP:~/

# 3. Extract on VM
ssh ubuntu@$vmIP << 'REMOTE'
mkdir -p ~/.config/BraveSoftware/Brave-Browser
tar -xzf ~/brave-profile.tar.gz -C ~/.config/BraveSoftware/Brave-Browser/
chown -R ubuntu:ubuntu ~/.config/BraveSoftware
rm ~/brave-profile.tar.gz
REMOTE

# 4. Restart Asil service
ssh ubuntu@$vmIP "systemctl --user restart opencode-asil"
```

---

## Option B: Manual Step-by-Step

### 1. On Local Machine (PowerShell)
```powershell
# Navigate to Brave profile
cd "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"

# Create archive (excludes junk)
tar -czf $env:TEMP\brave-profile.tar.gz `
  --exclude="*Cache*" `
  --exclude="*lock*" `
  --exclude="*Crash*" `
  --exclude="*Log*" `
  --exclude="*.log" `
  --exclude="*Session*" `
  --exclude="*History*" `
  "Default"

# Copy to VM (replace IP)
scp $env:TEMP\brave-profile.tar.gz ubuntu@YOUR_VM_IP:~/
```

### 2. On VM (SSH)
```bash
ssh ubuntu@YOUR_VM_IP

# Extract profile
mkdir -p ~/.config/BraveSoftware/Brave-Browser
tar -xzf ~/brave-profile.tar.gz -C ~/.config/BraveSoftware/Brave-Browser/
chown -R ubuntu:ubuntu ~/.config/BraveSoftware
rm ~/brave-profile.tar.gz
```

### 3. Restart Service
```bash
systemctl --user restart opencode-asil
```

---

## Verify Profile Sync Worked

```bash
# On VM - check profile exists
ls -la ~/.config/BraveSoftware/Brave-Browser/User\ Data/Default/

# Check OpenCode logs
journalctl --user -u opencode-asil -f
```

You should see Browse MCP connecting to Brave with your profile.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Profile in use" | Close all Brave windows locally before zipping |
| Extensions missing | Ensure `--profile-directory=Default` in service |
| Login cookies lost | Don't exclude `Cookies` file in tar |
| Brave won't start | Check `journalctl --user -u opencode-asil` for errors |

---

## What Gets Synced
✅ Saved passwords (encrypted)
✅ Extensions + settings
✅ Cookies/sessions (you stay logged in)
✅ Bookmarks, history
✅ Autofill data

❌ Cache (excluded to save space)
❌ Crash logs
❌ Lock files