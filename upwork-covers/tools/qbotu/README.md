# QBotu screenshot pipeline

Reproduces `upwork-covers/qbotu/*.png` — annotated captures of the Docker stack in
`c:/laragon/www/project_qbotu_a3` running against **`qbotu_shots`**, a sanitized clone of the
working `qbotu` database. The working database is never served.

## 1. Bring the stack up

Two host ports collide with what else runs on this machine, so override them:

```sh
cd c:/laragon/www/project_qbotu_a3
MYSQL_HOST_PORT=3312 FACE_API_PORT=8010 docker compose up -d
```

(`3306` is Laragon's MySQL, `8000` is the qparking backend.) Twelve services come up:
Caddy proxy (`:8080`), the Vite dev server (`:5173`/`:5174`), the Laravel API, a queue worker,
the scheduler, Reverb, MySQL, Redis, MinIO + init, a FastAPI face-recognition service and a
backup container. Images are already built locally; volumes hold the database.

## 2. Sanitized database

```sh
docker compose exec -T mysql sh -lc 'mysql -uroot -proot -e "drop database if exists qbotu_shots; create database qbotu_shots character set utf8mb4 collate utf8mb4_unicode_ci;" && mysqldump -uroot -proot --single-transaction --no-tablespaces qbotu | mysql -uroot -proot qbotu_shots'
docker compose exec -T mysql mysql -uroot -proot -e "grant all privileges on qbotu_shots.* to 'qbotu'@'%'; flush privileges;"
docker compose exec -T mysql mysql -uroot -proot qbotu_shots < qbotu-anonymize.sql
docker compose exec -T mysql mysql -uroot -proot qbotu_shots < qbotu-anonymize-2.sql
```

The grant matters: the `qbotu` user is only created for the `qbotu` database, so without it the
API container sits in its "waiting for mysql" loop forever.

`qbotu-anonymize.sql` renames the merchants (the working data holds one real client plus test
companies named after real fast-food brands), regenerates outlets, staff, HQ users, cardholders,
order customers and the activity logs, and drops tokens, sessions and face encodings.
`qbotu-anonymize-2.sql` is the follow-up for tables whose primary key is a UUID string, where
`id % n` fails and `CRC32(id) % n` is needed.

Then, by hand:

- Passwords: generate one with the app's own hasher (`docker compose exec backend php artisan
  tinker --execute='echo Hash::make("password");'`) and set it on `hq_users` and `merchant_users`.
  Logins become `superadmin@example.com` (HQ) and `superadmin-<id>@example.com` (merchant), both `password`.
- Modules: the demo merchant only had `qhub` switched on, so the POS answers "feature not
  included in your current plan". Copy the full set:
  `insert into company_module_activations (id, company_id, module_key, is_active, activated_at, created_at, updated_at) select uuid(), '<company id>', m.module_key, 1, now(), now(), now() from (select distinct module_key from company_module_activations) m where m.module_key not in (select module_key from company_module_activations where company_id='<company id>');`
- Dates: `update shop_orders set created_at = created_at + interval N day, ...` so the newest day
  lands on today, and set the last two days mostly to `status='completed', payment_status='paid',
  is_paid=1` — the dashboard counts only paid orders, so otherwise every tile reads RM0.00.

## 3. Point the API at the clone — the trap

`docker compose` passes `DB_DATABASE` into the container, **but `php artisan serve` does not hand
its environment to the PHP child process that answers requests**. The child re-reads
`backend/.env` and connects to `qbotu`, while `artisan tinker` in the same container correctly
reports `qbotu_shots`. The symptom is a login that works in tinker and 401s over HTTP.

So: back up `backend/.env`, set `DB_DATABASE=qbotu_shots` in it, `docker compose restart backend
worker scheduler reverb`, and **restore the file afterwards**.

## 4. Capture

Always drive the apps through the **Caddy origin** `http://localhost:8080` — on the Vite origin
(`:5174`) the SPA's relative `/api` calls 404. The exception is the kiosk/tablet entries
(`kiosk.html`, `tablet.html`), which only exist on the Vite origin; copying them into
`frontend/public/` to serve them through Caddy breaks them (Vite can no longer inject its
react-refresh preamble, and `public/` shadows the transformed entry).

```sh
node qbotu-capture2.js     # HQ console: login -> dashboard, companies, subscriptions, payments
node qbotu-hub-orders2.js  # merchant hub: login -> expand SALES -> orders
node qbotu-kiosk3.js       # kiosk: merchant code -> manager login -> outlet -> device binding
node render-qbotu.js       # sheets from qbotu-annotated.html -> upwork-covers/qbotu/
```

Deep links do not survive a reload: a hard `goto` of `/…/qhub/orders` lands on a spinner because
the context re-hydrates from an in-memory token. Log in, then click through the nav — the SALES
group has to be expanded before the Orders link exists in the DOM.

## 5. Known blockers

- **POS (`pos.html`)** renders an empty body on the Vite origin and "Merchant Not Found" through
  Caddy. Not captured.
- **Tablet** activates as far as outlet selection, then reports "no active tablet devices for this
  outlet" — `tablet_devices` is empty in the working data. A row would have to be seeded.
- **Kiosk** gets as far as the device-binding confirmation; "Activate Kiosk" does not complete
  (the existing binding belongs to another device fingerprint).

## 6. Tear down

`docker compose down`, restore `backend/.env`, and remove any `frontend/public/*.html` copies.
