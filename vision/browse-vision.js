#!/usr/bin/env node
/**
 * Browse + Vision Integration for Asil
 * Takes screenshots via Browse MCP and analyzes with Nemotron VL
 * Run inside OpenCode execute tool
 */

const { VisionAnalyzer } = require('./analyze.js');

/**
 * Analyze current browser tab with vision
 * @param {Object} tools - OpenCode tools object (from execute context)
 * @param {number|string} tab - Tab ID from browse.navigate
 * @param {string} prompt - Vision prompt
 * @returns {Promise<string>} Analysis result
 */
async function analyzeTab(tools, tab, prompt) {
  // Take screenshot
  const screenshot = await tools.browse.screenshot({ tab, fullPage: true });
  
  // Analyze with vision
  const analyzer = new VisionAnalyzer();
  const result = await analyzer.analyze(screenshot.path, prompt);
  
  return result;
}

/**
 * Analyze specific element region
 * @param {Object} tools - OpenCode tools
 * @param {number|string} tab - Tab ID
 * @param {string} ref - Element ref from snapshot
 * @param {string} prompt - Vision prompt
 * @returns {Promise<string>}
 */
async function analyzeElement(tools, tab, ref, prompt) {
  const screenshot = await tools.browse.screenshot({ tab, ref });
  const analyzer = new VisionAnalyzer();
  return analyzer.analyze(screenshot.path, prompt);
}

/**
 * Full page analysis with custom prompt
 */
async function analyzePage(tools, url, prompt) {
  const tab = await tools.browse.navigate({ url });
  await tools.browse.wait_for({ tab: tab.tab, text: 'Oracle', timeout: 30000 });
  return analyzeTab(tools, tab.tab, prompt);
}

// Pre-built prompts for common tasks
const PROMPTS = {
  oraclePublicIP: `You are looking at an Oracle Cloud Infrastructure console screenshot.
Find and extract the PUBLIC IP ADDRESS of the instance.
Look for fields labeled: "Public IP", "Public IP address", "Public IPv4", or similar.
Return ONLY the IP address (format: xxx.xxx.xxx.xxx) or "NOT FOUND" if not visible.`,

  oracleSubnetType: `You are looking at an Oracle Cloud console screenshot showing a subnet detail page.
Find the "Access type" field for this subnet.
Return ONLY "Public" or "Private" based on what you see.`,

  oracleVNICEdit: `You are looking at an Oracle Cloud VNIC edit dialog.
Check if there's a "Public IP" dropdown, "Assign public IP" checkbox, or similar option.
Return what public IP options are visible, or "NONE" if not present.`,

  extractAllText: `Extract ALL visible text from this screenshot.
Return as clean, structured text preserving labels and values.`,

  findElement: `Find the element described in the prompt and return its text content, value, or state.`
};

module.exports = {
  analyzeTab,
  analyzeElement,
  analyzePage,
  PROMPTS,
  VisionAnalyzer
};

// CLI for testing outside OpenCode
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.log('Usage: node browse-vision.js <tab-id> "<prompt>"');
    process.exit(1);
  }
  // Note: This won't work outside OpenCode execute context
  console.log('This module must be used inside OpenCode execute tool');
  console.log('Import and use analyzeTab(tools, tab, prompt)');
}