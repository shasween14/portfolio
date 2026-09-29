/**
 * Drives the real QParking Local Server (c:/laragon/www/qparking-local/app) and
 * screenshots it.  Writes upwork-covers/qparking-local-src/*.png.
 *
 * Nothing is faked inside the app: it runs its own main process, its own SQLite
 * schema, its own gate state machine. What is faked is the two things that live
 * outside the box — the qparking SaaS and the W4G payment device — see
 * stub-cloud.js. Equipment is created through the same `window.bridge` calls the
 * UI uses, and cars are put through with the app's own Simulate entry/exit.
 *
 * Isolation: --user-data-dir points Electron at a scratch directory, so the
 * operator's real %APPDATA%\qparking-local(-dev) database is never opened.
 *
 * Prereq: vite must already be serving the renderer (npm run dev:vite) and
 * `npm run build:main` must have run. See README.md.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { execFileSync } = require('child_process');
const { startCloud, startDevice } = require('./stub-cloud');

const PW = process.env.PW_CORE
  || 'C:/Users/Asus/AppData/Local/Temp/claude/c--laragon-www-portfolio/3ae85b3e-afcc-47aa-bc98-bae045692b76/scratchpad/node_modules/playwright-core';
const { _electron } = require(PW);

const APP = 'C:/laragon/www/qparking-local/app';
const OUT = 'C:/laragon/www/portfolio/upwork-covers/qparking-local-src';
const USER_DATA = process.env.QPL_USER_DATA
  || 'C:/Users/Asus/AppData/Local/Temp/claude/c--laragon-www-portfolio/e308a73a-05fe-4c57-999d-208d7a578d31/scratchpad/qpl-userdata';

const CLOUD_PORT = 7788;
const DEVICE_PORT = 7901;
const CALLBACK_PORT = 7902;

const t0 = Date.now();
const el = () => `${((Date.now() - t0) / 1000).toFixed(0)}s`;
const log = (...a) => console.log(`  [${el()}]`, ...a);

const HOURS = (h) => new Date(Date.now() - h * 3600_000).toISOString();

/**
 * A synthetic camera frame: flat colour, the plate in a plate-shaped box, and
 * the words TEST FRAME across it. Deliberately not photographic — there is no
 * car and no site here, and a screenshot of this must never read as one. What
 * it does is exercise the real intake: base64 → saveImage → the thumbnail the
 * Parking Activity page renders.
 */
function testFrame(plate, cameraName) {
  const file = path.join(os.tmpdir(), `qpl-frame-${plate}.jpg`);
  execFileSync('magick', [
    '-size', '640x360', 'xc:#1f2933',
    '-fill', '#38434f', '-draw', 'rectangle 0,300 640,360',
    '-fill', '#e7ecf2', '-draw', 'roundrectangle 170,120 470,215 8,8',
    '-fill', '#12181f', '-pointsize', '58', '-gravity', 'north', '-annotate', '+0+138', plate,
    '-fill', '#9fb0c2', '-pointsize', '19', '-gravity', 'northwest', '-annotate', '+24+28', 'LPR TEST FRAME — no vehicle, no site',
    '-fill', '#cbd6e2', '-pointsize', '18', '-gravity', 'southwest', '-annotate', '+24+22', cameraName,
    '-fill', '#cbd6e2', '-pointsize', '18', '-gravity', 'southeast', '-annotate', '+24+22',
    new Date().toISOString().replace('T', ' ').slice(0, 19),
    file,
  ]);
  return fs.readFileSync(file).toString('base64');
}

/** POST a plate the way the camera firmware does — the real /lpr/event intake. */
function postPlate(port, body, secret) {
  const data = JSON.stringify(body);
  return new Promise((resolve) => {
    const req = http.request(
      { host: '127.0.0.1', port, path: '/lpr/event', method: 'POST',
        headers: { 'content-type': 'application/json', 'content-length': Buffer.byteLength(data), 'x-webhook-secret': secret } },
      (res) => {
        let out = '';
        res.on('data', (c) => { out += c; });
        res.on('end', () => resolve(`${res.statusCode} ${out.slice(0, 160)}`));
      },
    );
    req.on('error', (e) => resolve(`ERR ${e.message}`));
    req.end(data);
  });
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  fs.rmSync(USER_DATA, { recursive: true, force: true });
  fs.mkdirSync(USER_DATA, { recursive: true });

  const cloud = await startCloud(CLOUD_PORT);
  const device = await startDevice(DEVICE_PORT, CALLBACK_PORT);
  log(`stub cloud :${CLOUD_PORT} · stub W4G device :${DEVICE_PORT} → callback :${CALLBACK_PORT}`);

  const env = { ...process.env, NODE_ENV: 'development' };
  delete env.ELECTRON_RUN_AS_NODE;
  const app = await _electron.launch({
    executablePath: require(`${APP}/node_modules/electron`),
    args: ['dist/main/index.js', `--user-data-dir=${USER_DATA}`],
    cwd: APP,
    env,
  });
  await app.firstWindow();

  // Docked DevTools open automatically in an unpackaged build and would eat
  // half the viewport — and playwright hands out that devtools page as readily
  // as the app's own. Close them in the main process, then pick the window
  // actually showing the renderer.
  await app.evaluate(async ({ BrowserWindow }) => {
    const win = BrowserWindow.getAllWindows()[0];
    win.webContents.closeDevTools();
    win.setContentSize(1440, 900);
    win.show();
  });

  let page = null;
  for (let i = 0; i < 40 && !page; i++) {
    page = app.windows().find((w) => w.url().includes('localhost:5173')) ?? null;
    if (!page) await new Promise((r) => setTimeout(r, 500));
  }
  if (!page) throw new Error('renderer window never appeared');
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(1500);
  log('window up:', await page.title());

  const call = (fn, ...args) =>
    page.evaluate(({ fn, args }) => window.bridge[fn](...args), { fn, args });

  // ─── 1. point the box at the stub cloud and the stub device ───────────────
  const settings = await call('getSettings');
  await call('saveSettings', {
    ...settings,
    qparkingBaseUrl: `http://127.0.0.1:${CLOUD_PORT}`,
    qparkingApiKey: 'lsk_demo_3f9c2a7b41d05e86',
    apiPort: 7000,
    lprWebhookPort: 7001,
    exitGracePeriodSeconds: 90,
    tngEnabled: true,
    tngHost: '127.0.0.1',
    tngPort: DEVICE_PORT,
    tngCallbackPort: CALLBACK_PORT,
    tngCallbackPorts: String(CALLBACK_PORT),
    tngTimeoutSeconds: 30,
    devMode: true,
  });
  log('settings saved');

  const sync = await call('syncAllNow');
  log('syncAll:', JSON.stringify(sync).slice(0, 400));

  // ─── 2. equipment, through the same bridge calls the forms use ────────────
  const lcds = [];
  for (const l of [
    { name: 'North Entry panel', host: '192.168.1.71' },
    { name: 'North Exit panel', host: '192.168.1.72' },
    { name: 'Basement Entry panel', host: '192.168.1.73' },
    { name: 'Basement Exit panel', host: '192.168.1.74' },
  ]) lcds.push(await call('saveLcd', { ...l, port: 7070, enabled: true }));

  const terminals = [];
  for (const t of [
    { name: 'North Exit W4G', host: '127.0.0.1' },
    { name: 'Basement Exit W4G', host: '127.0.0.1' },
  ]) terminals.push(await call('saveTerminal', { ...t, port: DEVICE_PORT, timeoutSeconds: 30, enabled: true }));
  log(`equipment: ${lcds.length} LCDs, ${terminals.length} terminals`);

  const lanes = [];
  for (const l of [
    { name: 'North Entry', policyId: 'pol-std', terminalId: null, lcdId: lcds[0].id },
    { name: 'North Exit', policyId: 'pol-std', terminalId: terminals[0].id, lcdId: lcds[1].id },
    { name: 'Basement Entry', policyId: 'pol-std', terminalId: null, lcdId: lcds[2].id },
    { name: 'Basement Exit', policyId: 'pol-std', terminalId: terminals[1].id, lcdId: lcds[3].id },
    { name: 'Loading Bay (pass only)', policyId: 'pol-std', terminalId: null, lcdId: null },
  ]) lanes.push(await call('saveLane', { ...l, enabled: true }));
  log('lanes:', lanes.map((l) => `${l.id}:${l.name}`).join(', '));

  const cams = [];
  for (const c of [
    { name: 'North Entry LPR', laneId: lanes[0].id, direction: 'entry', host: '192.168.1.51', webhookPort: 6001, accessMode: 'open' },
    { name: 'North Exit LPR', laneId: lanes[1].id, direction: 'exit', host: '192.168.1.52', webhookPort: 6001, accessMode: 'open' },
    { name: 'Basement Entry LPR', laneId: lanes[2].id, direction: 'entry', host: '192.168.1.53', webhookPort: 6002, accessMode: 'open' },
    { name: 'Basement Exit LPR', laneId: lanes[3].id, direction: 'exit', host: '192.168.1.54', webhookPort: 6002, accessMode: 'open' },
    { name: 'Loading Bay LPR', laneId: lanes[4].id, direction: 'entry', host: '192.168.1.55', webhookPort: 6003, accessMode: 'pass_only' },
  ]) {
    // Every camera gets SDK credentials, as a real install does: without them
    // the box cannot pulse the barrier relay and says so on every row.
    cams.push(await call('saveCamera', {
      deviceUser: 'admin', devicePassword: 'demo-pass', devicePort: 80,
      webhookSecret: `whk_${Math.random().toString(16).slice(2, 10)}`,
      relayChannel: 0, relayPulseMs: 1000, enabled: true, ...c,
    }));
  }
  log('cameras:', cams.map((c) => `${c.id}:${c.name}`).join(', '));

  const L = { nEntry: lanes[0].id, nExit: lanes[1].id, bEntry: lanes[2].id, bExit: lanes[3].id, bay: lanes[4].id };

  // ─── 3. put cars through, using the app's own entry/exit path ─────────────
  const closed = [
    // plate,        entry lane,  exit lane,  entered h ago, left h ago
    ['JHK4410', L.nEntry, L.nExit, 7, 5.5],
    ['WVB8812', L.bEntry, L.bExit, 9, 8.15],
    ['WNM2201', L.nEntry, L.nExit, 32, 26],
    ['BKL3390', L.bEntry, L.bExit, 26, 24.5],
    ['WPQ7745', L.nEntry, L.nExit, 28, 27],
    ['KLM9982', L.bEntry, L.bExit, 50, 49.25],
    ['WXY4821', L.nEntry, L.nExit, 30, 29],      // resident pass → free exit
    ['JPQ1188', L.bEntry, L.bExit, 31, 29.5],    // staff pass → free exit
  ];
  for (const [plate, inLane, outLane, inH, outH] of closed) {
    await call('simulateEntry', inLane, plate, HOURS(inH));
    const r = await call('simulateExit', outLane, plate, HOURS(outH));
    log(`closed ${plate}: ${JSON.stringify(r).slice(0, 180)}`);
    // The W4G result arrives ~1.2s after the request; a second exit on the same
    // lane before that lands is refused with "payment already in progress",
    // which is the box behaving correctly and not what we want to photograph.
    await page.waitForTimeout(2600);
  }

  const openNow = [
    ['BMT7342', L.nEntry, 3.1],   // corporate pool pass
    ['WMA5567', L.bEntry, 4.65],
    ['WXY4821', L.nEntry, 2.25],  // resident pass, back again
    ['JHK4410', L.bEntry, 1.35],
  ];
  for (const [plate, lane, h] of openNow) {
    await call('simulateEntry', lane, plate, HOURS(h));
    await page.waitForTimeout(200);
  }

  // The last arrivals come in over the wire instead — a real POST to /lpr/event
  // on the camera's own webhook port, carrying a frame, so the intake, the
  // secret check, the image store and the capture thumbnails all run for real.
  const arrivals = [
    ['PKM6610', cams[2]],   // visitor pass, Basement Entry
    ['PGT2298', cams[0]],   // casual, North Entry
    ['WTC5512', cams[0]],
  ];
  for (const [plate, cam] of arrivals) {
    const res = await postPlate(cam.webhookPort, {
      cameraId: cam.id, plate, confidence: 0.93, direction: 'entry',
      image: testFrame(plate, cam.name), timestamp: new Date().toISOString(),
    }, cam.webhookSecret);
    log(`webhook ${plate} → ${cam.name}:${cam.webhookPort} · ${res}`);
    await page.waitForTimeout(600);
  }
  log('open sessions seeded');

  // Refusals — the two the audit trail is there for.
  const banned = await call('simulateEntry', L.nEntry, 'WPL2233', HOURS(0.2));
  log('blacklisted plate:', JSON.stringify(banned).slice(0, 200));
  const noPass = await call('simulateEntry', L.bay, 'TRK7788', HOURS(0.15));
  log('pass-only refusal:', JSON.stringify(noPass).slice(0, 200));
  const withPass = await call('simulateEntry', L.bay, 'BNS5521', HOURS(0.1));
  log('pass-only admit:', JSON.stringify(withPass).slice(0, 200));

  // Push what just happened up, then pull the combined trail back down.
  log('activity push:', JSON.stringify(await call('pushActivityLogsToCloudNow')).slice(0, 200));
  log('resync:', JSON.stringify(await call('syncAllNow')).slice(0, 300));

  // ─── 4. screenshots ───────────────────────────────────────────────────────

  // Dev mode was only on for the sidebar simulator; the DEV chip and the
  // parking-flow live-log drawer are not what the operator's screen looks like.
  await call('saveSettings', { ...(await call('getSettings')), devMode: false });
  await page.reload();
  await page.waitForTimeout(2500);

  /** Alerts self-dismiss after 12s; close them rather than wait it out. */
  const clearToasts = async () => {
    for (let i = 0; i < 12; i++) {
      const open = await page.locator('[role="alert"] button').count();
      if (!open) return;
      await page.locator('[role="alert"] button').first().click({ timeout: 2000 }).catch(() => null);
      await page.waitForTimeout(150);
    }
  };

  const shot = async (name) => {
    await clearToasts();
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(1400);
    // Device probes against LAN addresses that aren't there keep the page busy
    // for a while, so give the shot room and freeze the spinners.
    await page.screenshot({ path: path.join(OUT, `${name}.png`), timeout: 120_000, animations: 'disabled' });
    log('shot', name);
  };
  const nav = async (label) => {
    await page.getByRole('button', { name: label, exact: true }).first().click();
    await page.waitForTimeout(1200);
  };

  await nav('Dashboard');
  await shot('1-dashboard');

  await nav('Parking Activity');
  // Defaults to the Pending filter (cars still inside); All Status shows the
  // closed stays next to them — fee, duration and how each one was settled.
  await page.locator('select').last().selectOption('all').catch(() => null);
  await page.waitForTimeout(1200);
  await shot('2-parking-activity');

  await nav('LPR cameras');
  await shot('3-cameras');

  await nav('Lanes');
  await shot('4-lanes');

  await nav('Parking Rates');
  // Expanded, the default plan shows the three tariff rules behind the headline
  // numbers and the "test a price" box that runs the real fee engine.
  await page.getByText('Standard Hourly', { exact: true }).first().click().catch(() => null);
  await page.waitForTimeout(1200);
  await shot('5-rates');

  await nav('Transactions');
  await shot('6-transactions');

  await nav('Activity Logs');
  await shot('7-activity-logs');

  // The box deliberately survives its window closing (it is a background gate
  // service with a tray icon), so app.close() would hang — tell it to exit.
  await app.evaluate(({ app: electronApp }) => electronApp.exit(0)).catch(() => null);
  cloud.close();
  device.close();
  log('done');
  process.exit(0);
})().catch((e) => { console.error('CAPTURE FAILED', e); process.exit(1); });
