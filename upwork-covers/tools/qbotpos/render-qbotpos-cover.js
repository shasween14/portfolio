// Render the QBot POS Upwork cover to a native-resolution 1024x768 PNG.
const fs = require('fs');
const PW = process.env.PW_CORE
  || 'C:/Users/Asus/AppData/Local/Temp/claude/c--laragon-www-portfolio/3ae85b3e-afcc-47aa-bc98-bae045692b76/scratchpad/node_modules/playwright-core';
const { chromium } = require(PW);

const PAGE = 'file:///C:/laragon/www/portfolio/upwork-covers/qbotpos-cover.html';
const OUT = 'C:/laragon/www/portfolio/upwork-covers/portfolio-qbotpos-cover.png';
const EXE = process.env.LOCALAPPDATA + '/ms-playwright/chromium-1208/chrome-win64/chrome.exe';

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const page = await browser.newPage({ viewport: { width: 1200, height: 1000 }, deviceScaleFactor: 1 });
  await page.goto(PAGE, { waitUntil: 'networkidle' });
  await page.waitForTimeout(900);
  await page.locator('#cover').screenshot({ path: OUT });
  // Subpixel rounding on the rounded-corner border makes the element shot 1px
  // tall; Upwork covers are 4:3, so pin it back to exactly 1024x768.
  require('child_process').execFileSync('magick', [OUT, '-crop', '1024x768+0+0', '+repage', OUT]);
  console.log(OUT, `${(fs.statSync(OUT).size / 1024).toFixed(0)} KB`);
  await browser.close();
})();
