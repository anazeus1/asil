#!/usr/bin/env node
/**
 * Basir - Vision Analysis Agent for Asil
 * Uses NVIDIA Nemotron 3.5 Super VL via NIM API
 * Takes screenshots via Browse MCP and analyzes with vision model
 * 
 * Name: Basir (بصير) - Arabic for "perceptive/insightful/seer"
 */

const fs = require('fs');
const path = require('path');

// Configuration
const VISION_MODEL = 'nvidia/nemotron-3.5-super-vl-120b-a12b';
const NIM_API_BASE = process.env.NIM_API_BASE || 'https://integrate.api.nvidia.com/v1';
const NIM_API_KEY = process.env.NVIDIA_API_KEY || process.env.NIM_API_KEY;

class Basir {
  constructor(options = {}) {
    this.apiKey = options.apiKey || NIM_API_KEY;
    this.apiBase = options.apiBase || NIM_API_BASE;
    this.model = options.model || VISION_MODEL;
    this.name = 'Basir';
  }

  /**
   * Analyze an image with the vision model
   * @param {string} imagePath - Path to image file, base64 data URL, or HTTP URL
   * @param {string} prompt - Analysis prompt
   * @returns {Promise<string>} Model response
   */
  async analyze(imagePath, prompt) {
    if (!this.apiKey) {
      throw new Error('NVIDIA_API_KEY environment variable required. Get from https://build.nvidia.com');
    }

    let base64Image;
    
    if (imagePath.startsWith('data:')) {
      base64Image = imagePath;
    } else if (imagePath.startsWith('http')) {
      const response = await fetch(imagePath);
      const buffer = await response.arrayBuffer();
      base64Image = `data:${response.headers.get('content-type') || 'image/png'};base64,${Buffer.from(buffer).toString('base64')}`;
    } else {
      const ext = path.extname(imagePath).toLowerCase();
      const mime = ext === '.jpg' || ext === '.jpeg' ? 'image/jpeg' : 
                   ext === '.webp' ? 'image/webp' : 'image/png';
      const buffer = fs.readFileSync(imagePath);
      base64Image = `data:${mime};base64,${buffer.toString('base64')}`;
    }

    const response = await fetch(`${this.apiBase}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        model: this.model,
        messages: [{
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            { type: 'image_url', image_url: { url: base64Image } }
          ]
        }],
        max_tokens: 2048,
        temperature: 0.2
      })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`${this.name} vision error: ${response.status} - ${error}`);
    }

    const data = await response.json();
    return data.choices[0]?.message?.content || 'No response';
  }

  /**
   * Analyze screenshot from Browse MCP
   * @param {Object} screenshotResult - Result from tools.browse.screenshot
   * @param {string} prompt - Analysis prompt
   * @returns {Promise<string>}
   */
  async analyzeScreenshot(screenshotResult, prompt) {
    return this.analyze(screenshotResult.path, prompt);
  }
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.log(`
${'═'.repeat(50)}
  Basir (بصير) - Vision Analysis Agent
${'═'.repeat(50)}

Usage:
  node analyze.js <image-path-or-url> "<prompt>"

Examples:
  node analyze.js screenshot.png "Extract all text from this Oracle Cloud console"
  node analyze.js screenshot.png "Find the Public IP address in this image"
  node analyze.js https://example.com/image.png "Describe this UI"

Environment:
  NVIDIA_API_KEY - Required (get from https://build.nvidia.com)
  NIM_API_BASE - Optional (default: https://integrate.api.nvidia.com/v1)
`);
    process.exit(1);
  }

  const [imagePath, prompt] = args;
  
  const basir = new Basir();
  
  basir.analyze(imagePath, prompt)
    .then(result => {
      console.log(`\n=== ${basir.name} Vision Analysis ===\n`);
      console.log(result);
    })
    .catch(err => {
      console.error('Error:', err.message);
      process.exit(1);
    });
}

module.exports = { Basir };