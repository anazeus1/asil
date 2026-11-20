# Skill: Basir (بصير) - Vision Analysis Agent

Vision analysis agent for Asil using NVIDIA Nemotron 3.5 Super VL (Vision Language Model).

**Name**: Basir (بصير) - Arabic for "perceptive, insightful, seer"

## Setup

```bash
# 1. Get free API key from https://build.nvidia.com
# 2. Set environment variable (same key works for chat + vision)
export NVIDIA_API_KEY="your-key-from-build-nvidia-com"

# Or add to .env in vision/
echo "NVIDIA_API_KEY=your-key" > vision/.env
```

## Usage in Execute Tool

```javascript
// Load Basir
const { basirAnalyzeTab, basirAnalyzeElement, basirAnalyzePage, BASIR_PROMPTS } = require('./vision/browse-vision.js');

// Analyze current tab with pre-built prompt
const result = await basirAnalyzeTab(tools, tabId, BASIR_PROMPTS.oraclePublicIP);

// Analyze specific element
const result = await basirAnalyzeElement(tools, tabId, 'e123', 'Read the text in this element');

// Full page analysis from URL
const result = await basirAnalyzePage(tools, 'https://cloud.oracle.com', BASIR_PROMPTS.extractAllText);

// Custom prompt
const result = await basirAnalyzeTab(tools, tabId, 'Find all IP addresses on this page');
```

## Pre-built Prompts

| Prompt | Use Case |
|--------|----------|
| `BASIR_PROMPTS.oraclePublicIP` | Extract Public IP from Oracle console |
| `BASIR_PROMPTS.oracleSubnetType` | Check subnet Access Type (Public/Private) |
| `BASIR_PROMPTS.oracleVNICEdit` | Check VNIC edit dialog for public IP options |
| `BASIR_PROMPTS.extractAllText` | OCR all visible text |
| `BASIR_PROMPTS.findElement` | Find specific element content |
| `BASIR_PROMPTS.describeUI` | Full UI description |

## CLI Testing

```bash
cd vision
node analyze.js screenshot.png "Extract the Public IP address"
node analyze.js https://example.com/image.png "Describe this UI"
```

## How It Works

1. **Browse MCP** takes screenshot (full page or element)
2. **Basir** sends to NVIDIA Nemotron 3.5 Super VL via NIM API
3. **Model returns** structured analysis based on prompt

## Requirements

- Node.js 18+
- NVIDIA API key (free from build.nvidia.com) - **same key as chat model**
- Browse MCP connected (for screenshots)

## Cost

- NVIDIA NIM: Free tier available
- Pay-per-use after free tier
- ~$0.001 per image analysis