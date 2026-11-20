const { chromium } = require('playwright');

(async () => {
  // First, launch Brave with remote debugging enabled (run this manually once):
  // "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" --remote-debugging-port=9222
  
  // Then connect to it:
  const browser = await chromium.connectOverCDP('http://localhost:9222');
  
  const page = await browser.newPage();
  await page.goto('https://github.com/login');
  
  console.log('Connected to your running Brave! Opened GitHub login.');
  console.log('Press Ctrl+C to disconnect...');
  
  process.stdin.resume();
})();