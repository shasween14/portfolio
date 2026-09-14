// Final capture pass: February Bloom admin, 1920x1080, sanitized DB.
const path = require('path');
const fs = require('fs');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');

const BASE = 'http://127.0.0.1:8123';
const OUT = process.env.OUT || 'C:/laragon/www/portfolio/upwork-covers/fb-src-final';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';

const SHOTS = [
  { id: 'orders',      url: '/admin/orders' },
  { id: 'order-edit',  url: '/admin/orders/12814/edit', scroll: 470 },
  { id: 'members',     url: '/admin/members' },
  { id: 'permissions', url: '/admin/permissions' },
  { id: 'past-orders', url: '/admin/past-orders' },
  {
    id: 'report-sales', url: '/admin/reports/order/sales',
    prep: async (page) => {
      // pick a fortnight instead of the default single day, then Apply
      await page.evaluate(() => {
        const el = document.querySelector('#range');
        if (el) el.value = '28/08/2026 - 10/09/2026';
      });
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 60000 }).catch(() => {}),
        page.click('button.btn-primary[type="submit"]'),
      ]);
      await page.waitForTimeout(2000);
    },
  },
];

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ executablePath: EXE });
  const ctx = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    deviceScaleFactor: 1,
    locale: 'en-MY',
    timezoneId: 'Asia/Kuala_Lumpur',
  });
  const page = await ctx.newPage();

  await page.goto(BASE + '/admin/login', { waitUntil: 'domcontentloaded' });
  await page.fill('input[name="login"]', 'admin');
  await page.fill('input[name="password"]', 'password');
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 60000 }),
    page.click('button[type="submit"], input[type="submit"]'),
  ]);
  if (/login/.test(page.url())) { console.log('LOGIN FAILED'); await browser.close(); process.exit(1); }

  for (const s of SHOTS) {
    try {
      const res = await page.goto(BASE + s.url, { waitUntil: 'domcontentloaded', timeout: 60000 });
      await page.waitForTimeout(2500);
      try { await page.waitForLoadState('networkidle', { timeout: 8000 }); } catch (e) {}
      if (s.prep) await s.prep(page);
      if (s.scroll) { await page.evaluate((y) => window.scrollTo(0, y), s.scroll); await page.waitForTimeout(500); }
      await page.waitForTimeout(500);
      await page.screenshot({ path: path.join(OUT, s.id + '.png') });
      console.log(String(res && res.status()), s.id, '<-', page.url());
    } catch (e) {
      console.log('FAIL', s.id, e.message.split('\n')[0]);
    }
  }
  await browser.close();
})();
