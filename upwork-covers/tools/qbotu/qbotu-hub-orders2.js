const path = require('path');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qbotu-src';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const BASE = 'http://localhost:8080';

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const p = await (await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, locale: 'en-MY', timezoneId: 'Asia/Kuala_Lumpur' })).newPage();
  await p.goto(BASE + '/amber-bites/hub/login', { waitUntil: 'domcontentloaded' });
  await p.waitForTimeout(12000);
  await p.fill('#merchant-login-email', 'superadmin-d08711@example.com');
  await p.fill('#merchant-login-password', 'password');
  await p.click('button:has-text("Sign In")');
  await p.waitForTimeout(15000);

  const navLinks = await p.$$eval('a, button', els => els.map(e => (e.tagName + '|' + e.textContent.trim().slice(0, 18))).filter(t => t.length > 2).slice(0, 40));
  console.log('nav:', JSON.stringify(navLinks.slice(0, 25)));

  // expand SALES group (chevron button) then click Orders
  try { await p.click('button:has-text("SALES")', { timeout: 5000 }); await p.waitForTimeout(2500); } catch (e) { console.log('no SALES button'); }
  const after = await p.$$eval('a', els => els.map(e => e.textContent.trim().slice(0, 18)).filter(Boolean).slice(0, 20));
  console.log('links after:', JSON.stringify(after));
  try { await p.click('a:has-text("Orders")', { timeout: 8000 }); console.log('clicked Orders'); } catch (e) { console.log('still no Orders link'); }
  await p.waitForTimeout(10000);
  await p.screenshot({ path: path.join(OUT, 'hub-03-orders.png') });
  console.log('final:', p.url().replace(BASE, ''), '|', (await p.evaluate(() => document.body.innerText.replace(/\s+/g, ' ').slice(0, 80))));
  await browser.close();
})();
