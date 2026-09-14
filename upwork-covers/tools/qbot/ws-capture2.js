const path = require('path'); const fs = require('fs');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qbot-src';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const STORE = 'http://lagoon-park-kuala-terengganu.localhost:8124';

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ executablePath: EXE });
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, locale: 'en-MY', timezoneId: 'Asia/Kuala_Lumpur' });
  const page = await ctx.newPage();

  // storefront ticket catalogue
  await page.goto(STORE + '/tickets', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(6500);
  await page.evaluate(() => window.scrollTo(0, 940));
  await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(OUT, 'ws-tickets.png') });
  console.log('ws-tickets', page.url());

  // bump two quantities so the cart summary appears
  const plus = await page.$$('.product-card button:last-of-type');
  for (let i = 0; i < Math.min(3, plus.length); i++) { try { await plus[i].click(); await page.waitForTimeout(900); } catch (e) {} }
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT, 'ws-tickets-qty.png') });
  console.log('ws-tickets-qty');

  // cart
  await page.goto(STORE + '/carts', { waitUntil: 'domcontentloaded' }).catch(() => {});
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(OUT, 'ws-cart.png') });
  console.log('ws-cart', page.url());

  // kitchen display
  await page.goto(STORE + '/kitchen-queues/kds', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(4500);
  await page.screenshot({ path: path.join(OUT, 'ws-kds.png') });
  console.log('ws-kds', page.url());

  await browser.close();
})();
