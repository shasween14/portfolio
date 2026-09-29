# QParking Local Server screenshot pipeline

Reproduces `upwork-covers/qparking-local/*.png` — annotated captures of the Electron gate
controller at `c:/laragon/www/qparking-local/app` running on a bench.

The app itself is **not modified, stubbed or mocked**: it boots its own main process, applies
its own SQLite schema, runs its own gate state machine, binds its own webhook listeners and
computes its own fees. What is faked is the two things that are not on this machine:

| Faked | Why | Speaks |
|---|---|---|
| qparking SaaS | a cloud tenant with a real site's data | `GET /api/v1/local-server/{site,company/settings,rate-policies,season-passes/v2,vehicles,vehicles/blacklisted,customers,parking-spaces,activity-logs,parking-records/open}`, `POST {activity-logs/sync,parking-records/upsert,transactions/upsert,device-health}` |
| Touch'n'Go W4G terminal | a payment device on the LAN | `POST /w4g/PayRequest` → acks `State:0`, then calls the box back on `POST /w4g/PayResult` |

Both contracts were read off `app/src/main/services/cloud-sync.ts` and `payment-tng.ts`; the
mirror payload shapes match what `tools/gate-sync-check` already pins.

**No client data is involved.** The site, company, customers, vehicles, plates, passes and bays
are invented for the bench, and the local database is a throwaway.

## 1. Isolation

`--user-data-dir` points Electron at a scratch directory, so `app.getPath('userData')` resolves
there and the operator's real `%APPDATA%\qparking-local` / `-dev` database is never opened.
The capture script wipes and recreates that directory on every run, which is also what makes
the output deterministic.

Do not skip this. The app's own boot-time migration copies a packaged install's `.db` into the
dev userData dir on first dev launch, so running it without the override would pull real
install data into the shots.

## 2. Prerequisites

```sh
cd c:/laragon/www/qparking-local/app
npm run build:main     # compiles src/main → dist/main
npm run dev:vite       # leave running: serves the renderer on :5173
```

An unpackaged Electron build always loads the renderer from Vite (`isDev` is derived from
`app.isPackaged`, which cannot be overridden), so the dev server has to be up. Packaging the
app for a cleaner capture needs symlink privileges that `electron-builder`'s winCodeSign step
does not have here — hence the "dev" build badge, which the annotated sheet crops off with the
debug drawer.

`playwright-core` and its chromium build are located by `PW_CORE` / the `ms-playwright` cache;
`magick` (ImageMagick 7) must be on PATH.

## 3. Capture

```sh
cd c:/laragon/www/portfolio/upwork-covers/tools/qparking-local
node qpl-capture.js          # → upwork-covers/qparking-local-src/*.png  (1800x1125)
```

Ports it takes: **7788** stub cloud, **7901** stub W4G device, **7902** the box's PayResult
callback, plus the app's own **7000/7001** and camera webhook ports **6001–6003**. The
callback port must not be left at the W4G default of 80 — Apache already holds it.

What the script does, in order:

1. starts both stubs, launches Electron against the scratch userData dir;
2. closes the auto-opened DevTools in the main process and sizes the window to 1440×900
   (`firstWindow()` otherwise hands back the DevTools page, not the app);
3. writes settings — base URL, API key, W4G host/port/callback — via `window.bridge`;
4. `syncAllNow()`, then creates 4 LCDs, 2 terminals, 5 lanes and 5 cameras through the same
   bridge calls the forms use;
5. puts 8 stays through entry→exit with the app's own simulator, each one charging the stub
   terminal for real. **2.6s between exits**: the PayResult callback lands ~1.2s after the
   request and a second exit on the same lane before that is correctly refused with
   "payment already in progress";
6. adds 4 backdated open stays, then 3 arrivals over the wire — a real `POST /lpr/event` on
   the camera's own webhook port carrying a base64 frame, which is what fills the capture
   thumbnails on the Parking Activity page. The frames are generated test cards (`magick`),
   deliberately not photographic: there is no vehicle and no site in them;
7. drives two refusals worth photographing — a blacklisted plate and a pass-only lane — plus
   one pass-only admission that shows the 1-of-2 pool quota;
8. pushes the audit trail up and re-syncs, so the log shows both local and cloud rows;
9. turns dev mode off, closes the toast stack, and screenshots seven pages.

## 4. Annotate and render

Pin coordinates live in `upwork-covers/qparking-local-annotated.html`, in the sheet's
1280×734 space (the 1800×1125 capture shown at 1280×800 and clipped, which drops the dev
build's debug drawer). Check after moving any of them that no pin covers what it points at.

```sh
node render-qparking-local.js   # → upwork-covers/qparking-local/*.png (1280x1064)

# carousel thumbnails for index.html
cd c:/laragon/www/portfolio/upwork-covers
for n in 1-dashboard 2-parking-activity 3-cameras 4-lanes 5-rates 6-transactions 7-activity-logs; do
  magick "qparking-local-src/$n.png" -crop 1800x1012+0+0 +repage -resize 1280x720 -quality 88 \
    "slides/qparking-local-$n.jpg"
done
```

## What the shots honestly show

- **Cameras, LCD panels: OFFLINE.** There is no hardware on this network. The device-health
  probe reports it rather than showing a green light it cannot justify.
- **`gate.barrier.pulse_failed` / CRITICAL rows in the audit trail.** The barrier is raised by
  pulsing the camera's onboard IO relay over the vendor SDK. With no camera to reach, the box
  logs the failure instead of recording the entry as though the car got in. Those rows are the
  system behaving correctly, and the annotation says so.
- **Payment timestamps are capture time.** The stays are backdated; the charges genuinely
  happened during the run.

## Traps this cost time on

- **`app.close()` hangs.** The box deliberately survives its window closing — it is a
  background gate service with a tray icon — so the script calls `app.exit(0)` in the main
  process instead. A run killed without this leaves `electron.exe` holding ports 6001–6003 and
  7000/7001, and the next run's listeners fail to bind.
- **Cameras need SDK credentials** (`deviceUser` / `devicePassword`), or every row carries a red
  "cannot reach the camera to open the barrier" banner. That is a real configuration warning,
  not a bench artefact.
- **The rate-plan overview mirrors the highest-priority active rule** into its headline columns.
  Rules whose top-priority entry is flat-rate therefore read RM 0.00 there and trip the page's
  "zero rate" warning, even though the fee engine prices the stay correctly from the rules.
  The demo tariffs are shaped so the block-hourly rule ranks top and the flat ones cover only
  the hours it does not.
