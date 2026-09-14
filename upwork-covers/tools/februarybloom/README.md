# February Bloom screenshot pipeline

Reproduces `upwork-covers/februarybloom/*.png` — annotated captures of the real
app running against a **sanitized copy** of the database. Nothing here touches the
`februarybloom` database or the project's `.env`.

## 1. Sanitized database

```sh
MB=/c/laragon/bin/mysql/mysql-8.0.30-winx64/bin
$MB/mysql.exe -uroot -e "drop database if exists februarybloom_shots; create database februarybloom_shots character set utf8mb4 collate utf8mb4_unicode_ci;"
$MB/mysqldump.exe -uroot --single-transaction --no-tablespaces februarybloom | $MB/mysql.exe -uroot februarybloom_shots

cd c:/laragon/www/portfolio/upwork-covers/tools/februarybloom
for f in anonymize.sql anonymize-messages.sql shift-dates.sql fill-gaps.sql vary-status.sql; do
  $MB/mysql.exe -uroot -D februarybloom_shots < $f
done
```

- `anonymize.sql` / `anonymize-messages.sql` — every customer name, address, phone,
  e-mail, identity number, gift-card message and delivery instruction is replaced by a
  value derived from the row id. Tokens, 2FA secrets, login logs and queued jobs are dropped.
- `shift-dates.sql` — rolls the dataset forward so "today" lands in the busy window
  (offsets are relative to 2026-09-10; re-derive them if re-run much later).
- `fill-gaps.sql`, `vary-status.sql` — assign riders, fill blank addresses and spread
  order/payment statuses so the board is not one status repeated.

Then, once: `update accounts set login_type=0;` (skips OTP) and
`update users set username='admin', name='Shaswin' where id=1;` — the anonymizer sets
every password to bcrypt of `password`.

## 2. Serve it

`.env.shots` is a copy of `.env` with `APP_ENV=shots`, `APP_DEBUG=false`,
`DB_DATABASE=februarybloom_shots`, `MAIL_MAILER=log`, `QUEUE_CONNECTION=sync`.
It is **deleted after each session** because it carries the real API keys copied out of
`.env` and the project only gitignores `.env` itself.

```sh
cd c:/laragon/www/februarybloom
sed -e 's/^APP_ENV=.*/APP_ENV=shots/' -e 's/^APP_DEBUG=.*/APP_DEBUG=false/' \
    -e 's#^APP_URL=.*#APP_URL=http://127.0.0.1:8123#' \
    -e 's/^DB_DATABASE=.*/DB_DATABASE=februarybloom_shots/' \
    -e 's/^MAIL_MAILER=.*/MAIL_MAILER=log/' -e 's/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/' .env > .env.shots
APP_ENV=shots /c/laragon/bin/php/php-8.2.3/php.exe -d display_errors=0 artisan serve --host=127.0.0.1 --port=8123
```

Laravel picks `.env.shots` up from `APP_ENV`; verify with
`APP_ENV=shots php artisan tinker --execute="echo DB::connection()->getDatabaseName();"`
before capturing anything. Log in at `/admin/login` as `admin` / `password`.

`make-logo.php` writes a plain-text stand-in wordmark to
`public/assets/uploads/company/logo/1.logo.png` (that path is gitignored, so the real
asset is missing on a fresh clone and the sidebar renders a broken image without it).

## 3. Capture and annotate

```sh
node capture2.js        # 1920x1080 screens -> upwork-covers/fb-src-final/
node render-sheets.js   # sheets from februarybloom-annotated.html -> upwork-covers/februarybloom/
```

Pin coordinates live in `../../februarybloom-annotated.html`. A pin must sit on flat
background beside what it points at, never on top of it — check before rendering:

```sh
php check-pins.php ../../fb-src-final/orders.png 445,272 1065,272
```

A spot is clear when nothing dark sits under the disc (`min >= 230`).
