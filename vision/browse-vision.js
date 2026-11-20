#!/usr/bin/env node
/**
 * Basir (بصير) - Vision Integration for Asil
 * Takes screenshots via Browse MCP and analyzes with Nemotron VL
 * Run inside OpenCode execute tool
 */

const { Basir } = require('./analyze.js');

/**
 * Analyze current browser tab with Basir vision
 * @param {Object} tools - OpenCode tools object (from execute context)
 * @param {number|string} tab - Tab ID from browse.navigate
 * @param {string} prompt - Vision prompt
 * @returns {Promise<string>} Analysis result
 */
async function basirAnalyzeTab(tools, tab, prompt) {
  const screenshot = await tools.browse.screenshot({ tab, fullPage: true });
  const basir = new Basir();
  return basir.analyze(screenshot.path, prompt);
}

/**
 * Analyze specific element region with Basir
 * @param {Object} tools - OpenCode tools
 * @param {number|string} tab - Tab ID
 * @param {string} ref - Element ref from snapshot
 * @param {string} prompt - Vision prompt
 * @returns {Promise<string>}
 */
async function basirAnalyzeElement(tools, tab, ref, prompt) {
  const screenshot = await tools.browse.screenshot({ tab, ref });
  const basir = new Basir();
  return basir.analyze(screenshot.path, prompt);
}

/**
 * Full page analysis with Basir from URL
 */
async function basirAnalyzePage(tools, url, prompt) {
  const tab = await tools.browse.navigate({ url });
  await tools.browse.wait_for({ tab: tab.tab, text: 'Oracle', timeout: 30000 });
  return basirAnalyzeTab(tools, tab.tab, prompt);
}

// Pre-built prompts for common tasks
const BASIR_PROMPTS = {
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

  findElement: `Find the element described in the prompt and return its text content, value, or state.`,

  describeUI: `Describe this user interface in detail. What application is this? What are the main elements? What actions can be taken?`
};

module.exports = {
  basirAnalyzeTab,
  basirAnalyzeElement,
  basirAnalyzePage,
  BASIR_PROMPTS,
  Basir
};

// CLI for testing outside OpenCode
if (require.main === module) {
  console.log('Basir (بصير) - Vision Agent for Asil');
  console.log('Import and use basirAnalyzeTab(tools, tab, prompt) inside OpenCode execute tool');
}