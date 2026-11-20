# Skill: Vision Analysis

Vision analysis capability for Asil using NVIDIA Nemotron 3.5 Super VL (Vision Language Model).

## Setup

```bash
# 1. Get free API key from https://build.nvidia.com
# 2. Set environment variable
export NVIDIA_API_KEY="your-key-from-build-nvidia-com"

# Or add to .env in vision/
echo "NVIDIA_API_KEY=your-key" > vision/.env
```

## Usage in Execute Tool

```javascript
// Load the module
const { analyzeTab, analyzeElement, analyzePage, PROMPTS } = require('./vision/browse-vision.js');

// Analyze current tab with pre-built prompt
const result = await analyzeTab(tools, tabId, PROMPTS.oraclePublicIP);

// Analyze specific element
const result = await analyzeElement(tools, tabId, 'e123', 'Read the text in this element');

// Full page analysis from URL
const result = await analyzePage(tools, 'https://cloud.oracle.com', PROMPTS.extractAllText);

// Custom prompt
const result = await analyzeTab(tools, tabId, 'Find all IP addresses on this page');
```

## Pre-built Prompts

| Prompt | Use Case |
|--------|----------|
| `PROMPTS.oraclePublicIP` | Extract Public IP from Oracle console |
| `PROMPTS.oracleSubnetType` | Check subnet Access Type (Public/Private) |
| `PROMPTS.oracleVNICEdit` | Check VNIC edit dialog for public IP options |
| `PROMPTS.extractAllText` | OCR all visible text |
| `PROMPTS.findElement` | Find specific element content |

## CLI Testing

```bash
cd vision
node analyze.js screenshot.png "Extract the Public IP address"
node analyze.js https://example.com/image.png "Describe this UI"
```

## How It Works

1. **Browse MCP** takes screenshot (full page or element)
2. **Vision module** sends to NVIDIA Nemotron 3.5 Super VL via NIM API
3. **Model returns** structured analysis based on prompt

## Requirements

- Node.js 18+
- NVIDIA API key (free from build.nvidia.com)
- Browse MCP connected (for screenshots)

## Cost

- NVIDIA NIM: Free tier available
- Pay-per-use after free tier
- ~$0.001 per image analysis