// Render a cover page's .sheet to a native-resolution PNG named by its data-name.
// args: [html file] [device scale]
//   node render-contra-cover.js                          -> contra-profile-cover.html at 1x
//   node render-contra-cover.js linkedin-banner.html 2   -> LinkedIn banner at 2x
const path = require('path');
const fs = require('fs');
const { chromium } = require('C:/laragon/www/project_qbotu_a3/node_modules/playwright-core');

const SRC = process.argv[2] || 'contra-profile-cover.html';
const SCALE = Number(process.argv[3]) || 1;
const PAGE = 'file:///C:/laragon/www/portfolio/upwork-covers/' + SRC;
const OUT = 'C:/laragon/www/portfolio/upwork-covers';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const page = await browser.newPage({ viewport: { width: 2000, height: 1200 }, deviceScaleFactor: SCALE });
  await page.goto(PAGE, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);

  const fontOk = await page.evaluate(() => document.fonts.check('800 80px "Plus Jakarta Sans"'));
  console.log('webfont loaded:', fontOk);

  const sheet = await page.$('.sheet');
  const name = await sheet.getAttribute('data-name');
  const file = path.join(OUT, name);
  await sheet.screenshot({ path: file });
  const { size } = fs.statSync(file);
  console.log(name, (size / 1024).toFixed(0) + ' KB', 'scale ' + SCALE + 'x');

  await browser.close();
})();
