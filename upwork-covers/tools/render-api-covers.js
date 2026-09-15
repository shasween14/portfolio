// Render each .sheet in api-covers.html to a 1280x960 PNG.
const path = require('path');
const fs = require('fs');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');

const PAGE = 'file:///C:/laragon/www/portfolio/upwork-covers/api-covers.html';
const OUT = 'C:/laragon/www/portfolio/upwork-covers';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1100 }, deviceScaleFactor: 1 });
  await page.goto(PAGE, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);

  const fontOk = await page.evaluate(() => document.fonts.check('700 62px "Plus Jakarta Sans"'));
  console.log('webfont loaded:', fontOk);

  const sheets = await page.$$('.sheet');
  for (const sheet of sheets) {
    const name = await sheet.getAttribute('data-name');
    const file = path.join(OUT, name);
    await sheet.screenshot({ path: file });
    const { size } = fs.statSync(file);
    console.log(name, (size / 1024).toFixed(0) + ' KB');
  }
  await browser.close();
})();
