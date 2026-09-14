const path = require('path');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qbotu-src';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const V = 'http://localhost:5174';
const shot = async (p, n, w = 8000) => { await p.waitForTimeout(w); await p.screenshot({ path: path.join(OUT, n + '.png') });
  console.log(n, '|', p.url().replace(V, ''), '|', (await p.evaluate(() => document.body.innerText.replace(/\s+/g, ' ').slice(0, 130)))); };

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const p = await (await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, locale: 'en-MY', timezoneId: 'Asia/Kuala_Lumpur' })).newPage();
  await p.goto(V + '/kiosk.html', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await p.waitForTimeout(8000);
  const code = await p.$('input');
  if (code) { await code.fill('amber-bites'); try { await p.click('button:has-text("CONTINUE"), button:has-text("Continue")', { timeout: 6000 }); } catch (e) {} }
  await p.waitForTimeout(7000);
  const inputs = await p.$$('input');
  if (inputs.length >= 3) {
    await inputs[0].fill('amber-bites');
    await inputs[1].fill('superadmin-d08711@example.com');
    await inputs[2].fill('password');
    try { await p.click('button:has-text("LOGIN & ACTIVATE")', { timeout: 6000 }); } catch (e) {}
    await p.waitForTimeout(10000);
  }
  try { await p.click('text=AMBER BITES BANGSAR', { timeout: 8000 }); } catch (e) {}
  await p.waitForTimeout(7000);
  await shot(p, 'kiosk-05-binding', 1000);
  const btns = await p.$$eval('button', bs => bs.map(b => b.textContent.trim().slice(0, 28)).filter(Boolean));
  console.log('binding buttons:', JSON.stringify(btns.slice(0, 8)));
  for (const label of btns) {
    if (/activ|confirm|bind|start/i.test(label)) {
      try { await p.click(`button:has-text("${label}")`, { timeout: 5000 }); console.log('clicked', label); break; } catch (e) {}
    }
  }
  await shot(p, 'kiosk-06-mode', 12000);
  // try to reach the shop menu
  for (const label of ['ORDER', 'Order', 'Start Order', 'DINE IN', 'Dine In', 'TAKE AWAY']) {
    try { await p.click(`button:has-text("${label}"), div[role="button"]:has-text("${label}")`, { timeout: 4000 }); console.log('picked mode', label); break; } catch (e) {}
  }
  await shot(p, 'kiosk-07-menu', 12000);
  await browser.close();
})();
