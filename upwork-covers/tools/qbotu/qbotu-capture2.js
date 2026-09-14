// QBotu: HQ console + merchant hub. Navigate inside the SPA, not by reload.
const path = require('path'); const fs = require('fs');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qbotu-src';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const BASE = 'http://localhost:8080';

const shot = async (page, name, wait = 5000) => {
  await page.waitForTimeout(wait);
  await page.screenshot({ path: path.join(OUT, name + '.png') });
  const txt = await page.evaluate(() => document.body.innerText.replace(/\s+/g, ' ').slice(0, 70));
  console.log(name, '|', page.url().replace(BASE, ''), '|', txt);
};

const clickNav = async (page, label) => {
  try { await page.click(`a:has-text("${label}"), button:has-text("${label}")`, { timeout: 6000 }); return true; }
  catch (e) { console.log('  nav miss:', label); return false; }
};

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ executablePath: EXE });
  const mk = async () => (await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, locale: 'en-MY', timezoneId: 'Asia/Kuala_Lumpur' })).newPage();

  // ---- HQ console ----
  const p = await mk();
  await p.goto(BASE + '/myhq/login', { waitUntil: 'domcontentloaded' });
  await p.waitForTimeout(7000);
  await shot(p, 'hq-01-login', 500);
  await p.fill('input[type="email"]', 'superadmin@example.com');
  await p.fill('input[type="password"]', 'password');
  await p.click('button:has-text("Sign In")');
  await shot(p, 'hq-02-dashboard', 12000);
  for (const label of ['Companies', 'Subscriptions', 'Payments', 'Entitlements']) {
    if (await clickNav(p, label)) await shot(p, 'hq-' + label.toLowerCase(), 7000);
  }

  // ---- merchant hub ----
  const p2 = await mk();
  await p2.goto(BASE + '/amber-bites/hub/login', { waitUntil: 'domcontentloaded' });
  await p2.waitForTimeout(7000);
  await shot(p2, 'hub-01-login', 500);
  await p2.fill('#merchant-login-email', 'superadmin-d08711@example.com');
  await p2.fill('#merchant-login-password', 'password');
  await p2.click('button:has-text("Sign In")');
  await shot(p2, 'hub-02-dashboard', 14000);
  for (const label of ['Orders', 'Products', 'Staff', 'Outlets', 'Financial']) {
    if (await clickNav(p2, label)) await shot(p2, 'hub-' + label.toLowerCase(), 7000);
  }

  await browser.close();
})();
