const path = require('path');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qbot-src';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const STORE = 'http://lagoon-park-kuala-terengganu.localhost:8124';

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, locale: 'en-MY', timezoneId: 'Asia/Kuala_Lumpur' });
  const page = await ctx.newPage();

  await page.goto(STORE + '/tickets', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(6500);
  const plus = await page.$$('.product-card button:last-of-type');
  for (const i of [0, 0, 1, 3, 3]) { if (plus[i]) { try { await plus[i].click(); await page.waitForTimeout(900); } catch (e) {} } }
  await page.waitForTimeout(1000);
  for (const c of await page.$$('#add-to-cart-section button, #add-to-cart-section a')) { if (await c.isVisible()) { await c.click(); break; } }
  await page.waitForTimeout(5000);
  await page.screenshot({ path: path.join(OUT, 'ws-cart.png') });
  console.log('cart', page.url());

  await page.goto(STORE + '/checkouts/detail', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3500);
  try { await page.click('text=Continue as Guest', { timeout: 4000 }); await page.waitForTimeout(1800); } catch (e) {}

  const set = async (id, val) => page.evaluate(([i, v]) => {
    const el = document.getElementById(i);
    if (el) { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true })); return true; }
    return false;
  }, [id, val]);
  for (const [id, v] of [['guest-first-name', 'Aisyah'], ['guest-last-name', 'Rahman'], ['guest-telephone', '12-345 6789'], ['guest-email', 'customer@example.com'],
                         ['new-customer-first-name', 'Aisyah'], ['new-customer-last-name', 'Rahman'], ['new-customer-telephone', '12-345 6789'], ['new-customer-email', 'customer@example.com']]) {
    console.log(id, await set(id, v));
  }
  // choose a payment method
  try { await page.click('text=Gkash Credit/Debit Card', { timeout: 4000 }); } catch (e) { console.log('pay click:', e.message.split('\n')[0]); }
  await page.waitForTimeout(1200);

  await page.evaluate(() => window.scrollTo(0, 620));
  await page.waitForTimeout(900);
  await page.screenshot({ path: path.join(OUT, 'ws-checkout.png') });
  console.log('checkout', page.url());
  await browser.close();
})();
