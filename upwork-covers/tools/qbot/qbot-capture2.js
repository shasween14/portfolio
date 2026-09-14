// QBot final capture with UI-driven filters.
const path = require('path'); const fs = require('fs');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');
const OUT = process.env.OUT || 'C:/laragon/www/portfolio/upwork-covers/qbot-src';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const BO = 'http://backoffice.localhost:8124';
const BE = 'http://backend.localhost:8124';

const widenFilters = async (page, submitSel) => {
  await page.evaluate(() => {
    const d = new Date(); d.setDate(d.getDate() - 30);
    const fmt = d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
    const from = document.querySelector('#date_from'); if (from) from.value = fmt;
    ['#status_id', '#store_id'].forEach(sel => {
      const el = document.querySelector(sel);
      if (el) { el.value = ''; el.dispatchEvent(new Event('change', { bubbles: true })); }
    });
  });
  await page.click(submitSel);
  await page.waitForTimeout(3500);
};

const SHOTS = {
  bo: [
    { id: 'bo-dashboard-month', url: '/dashboard', prep: async p => { await p.click('text=This Month'); await p.waitForTimeout(3500); } },
    { id: 'bo-orders-30d', url: '/orders', prep: async p => { await widenFilters(p, '#filter-btn'); } },
    { id: 'bo-report-sales-30d', url: '/reports/orders/sales-summary', prep: async p => { await widenFilters(p, 'button[name="action"]'); } },
    { id: 'bo-permissions', url: '/permissions' },
    { id: 'bo-store-edit', url: '/stores/1/edit' },
    { id: 'bo-employees', url: '/employees' },
    { id: 'bo-products', url: '/products' },
  ],
  be: [
    { id: 'be-accounts', url: '/accounts' },
    { id: 'be-subscriptions', url: '/subscriptions' },
  ],
};

async function shoot(page, base, list) {
  for (const s of list) {
    try {
      const res = await page.goto(base + s.url, { waitUntil: 'domcontentloaded', timeout: 60000 });
      await page.waitForTimeout(2600);
      try { await page.waitForLoadState('networkidle', { timeout: 8000 }); } catch (e) {}
      if (s.prep) await s.prep(page);
      if (s.scroll) { await page.evaluate(y => window.scrollTo(0, y), s.scroll); await page.waitForTimeout(600); }
      await page.screenshot({ path: path.join(OUT, s.id + '.png') });
      console.log(String(res && res.status()), s.id, '<-', page.url());
    } catch (e) { console.log('FAIL', s.id, e.message.split('\n')[0]); }
  }
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ executablePath: EXE });
  const opts = { viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, locale: 'en-MY', timezoneId: 'Asia/Kuala_Lumpur' };

  const p1 = await (await browser.newContext(opts)).newPage();
  await p1.goto(BO + '/login', { waitUntil: 'domcontentloaded' });
  await p1.fill('#email', 'staff1@example.com'); await p1.fill('#password', 'password');
  await Promise.all([p1.waitForNavigation({ waitUntil: 'domcontentloaded' }).catch(() => {}), p1.click('#btn-login')]);
  await p1.waitForTimeout(1500);
  console.log('backoffice ->', p1.url());
  await shoot(p1, BO, SHOTS.bo);

  const p2 = await (await browser.newContext(opts)).newPage();
  await p2.goto(BE + '/login', { waitUntil: 'domcontentloaded' });
  await p2.fill('input[name="email"]', 'platform1@example.com'); await p2.fill('input[name="password"]', 'password');
  await Promise.all([p2.waitForNavigation({ waitUntil: 'domcontentloaded' }).catch(() => {}), p2.click('button[type="submit"]')]);
  await p2.waitForTimeout(1500);
  console.log('backend ->', p2.url());
  await shoot(p2, BE, SHOTS.be);

  await browser.close();
})();
