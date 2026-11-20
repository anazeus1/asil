#!/bin/bash
# Vision Module Setup for Asil Agent

echo "🔧 Setting up Vision Analysis for Asil..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Install Node.js 20+"
    exit 1
fi

# Install dependencies (none for now - uses fetch API)
echo "✅ No npm dependencies needed (uses native fetch)"

# Check API key
if [ -z "$NVIDIA_API_KEY" ] && [ -z "$NIM_API_KEY" ]; then
    echo ""
    echo "⚠️  NVIDIA_API_KEY not set!"
    echo "Get your free API key from: https://build.nvidia.com"
    echo ""
    echo "Add to your shell profile (~/.bashrc, ~/.zshrc, or PowerShell profile):"
    echo 'export NVIDIA_API_KEY="your-key-here"'
    echo ""
    echo "Or create .env file in vision/ directory:"
    echo 'NVIDIA_API_KEY=your-key-here'
fi

# Create .env template
cat > .env.example << 'EOF'
# Get free API key from https://build.nvidia.com
NVIDIA_API_KEY=your-nvidia-api-key-here
NIM_API_BASE=https://integrate.api.nvidia.com/v1
EOF

echo "✅ Vision module ready!"
echo ""
echo "Usage in OpenCode execute tool:"
echo "  const { analyzeTab, PROMPTS } = require('./vision/browse-vision.js');"
echo "  const result = await analyzeTab(tools, tabId, PROMPTS.oraclePublicIP);"
echo ""
echo "CLI test (after setting NVIDIA_API_KEY):"
echo "  node analyze.js screenshot.png \"Extract the Public IP\""