// Render each .sheet in the annotated page to a native-resolution PNG.
const path = require('path');
const fs = require('fs');
const { chromium } = require('C:/Users/Asus/AppData/Local/Temp/claude/c--laragon-www-portfolio/3ae85b3e-afcc-47aa-bc98-bae045692b76/scratchpad/node_modules/playwright-core');

const PAGE = 'file:///C:/laragon/www/portfolio/upwork-covers/qbotpos-annotated.html';
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qbotpos';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ executablePath: EXE });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1200 }, deviceScaleFactor: 1 });
  await page.goto(PAGE, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1200);

  const names = await page.$$eval('.item .fname', els => els.map(e => e.textContent.split(' ')[0]));
  const sheets = await page.$$('.sheet');
  for (let i = 0; i < sheets.length; i++) {
    const file = path.join(OUT, names[i]);
    await sheets[i].screenshot({ path: file });
    const { size } = fs.statSync(file);
    console.log(names[i], (size / 1024).toFixed(0) + ' KB');
  }
  await browser.close();
})();
