# QBot POS screenshot pipeline

Reproduces `upwork-covers/qbotpos/*.png` — annotated captures of the Ionic + React POS
terminal (`c:/laragon/www/qbot_pos`) running against the **QBot Laravel `pos-api`** on a
**sanitized copy** of the database. Nothing here touches `wonderpark_dev` or either
project's committed `.env`.

The POS is a client only: it has no database of its own beyond IndexedDB, so the whole
job is pointing it at a safe backend. `routes/pos_api.php` in the QBot app already serves
every endpoint the terminal calls, so this pipeline reuses the `qbot_shots` clone built by
`../qbot/README.md` rather than making a second one.

## 1. Sanitized database

Build `qbot_shots` exactly as `../qbot/README.md` describes, then apply the POS-specific
setup. All of this is on the clone, never on `wonderpark_dev`:

```sh
MB=/c/laragon/bin/mysql/mysql-8.0.30-winx64/bin

# a known POS passcode — the pos-api login bcrypt-checks employees.passcode
HASH=$(/c/laragon/bin/php/php-8.2.3/php.exe -r 'echo password_hash("123456", PASSWORD_BCRYPT);')
$MB/mysql.exe -uroot -D qbot_shots -e "update employees set passcode='$HASH' where employee_id=1;"

# a neutral store logo (see §2) and a coherent status mix for the Orders tiles
$MB/mysql.exe -uroot -D qbot_shots -e "update stores set logo='shots-placeholder-logo.png' where store_id=1;"
$MB/mysql.exe -uroot -D qbot_shots -e "
  update orders o join statuses s on s.status_id=o.status_id
  set o.status_id=(select status_id from statuses where status_name='Complete' limit 1)
  where o.store_id=1 and s.status_name='Paid' and o.order_id % 10 < 7;"
```

The status shuffle matters: the Orders tiles count `Complete`, but the clone only had one
such order against 416 `Paid`, so the tiles read as though the till had never sold
anything. Promoting ~70% of the paid orders makes the summary agree with the list.

Credentials after this: company `tenant6@example.com`, passcode `123456`
(employee 1, "Nurul Kumar").

## 2. Placeholder imagery

`Store::logoImage()` and the catalogue resource only build a URL when `APP_ENV` is
`local`, `production` or `staging`; under any other environment they return `false`, and
the app renders `<img src="false">` — a broken-image icon in the header. In production the
URL points at the client's DigitalOcean bucket, which is exactly the artwork that must not
appear. So: run as `local` and serve **generated placeholders** from disk.

```sh
cd c:/laragon/www/qbot/public/assets/uploads
mkdir -p stores/logos products/variants

magick -size 360x108 xc:none \
  -fill "#0f2f4c" -draw "roundrectangle 0,26 104,82 10,10" \
  -fill white -pointsize 34 -gravity northwest -annotate +22+38 "LP" \
  -fill "#0f2f4c" -pointsize 30 -annotate +122+34 "Lagoon Park" \
  -fill "#7c8aa0" -pointsize 19 -annotate +124+68 "Kuala Terengganu" \
  stores/logos/shots-placeholder-logo.png

magick -size 400x400 xc:"#eef1f5" \
  -fill "#c3ccd8" -draw "roundrectangle 150,140 250,240 12,12" \
  -fill "#aab6c6" -pointsize 22 -gravity south -annotate +0+40 "product image" \
  /tmp/placeholder-product.jpg
```

Then fan `/tmp/placeholder-product.jpg` out to every filename the catalogue references —
read them from `catalogs/{store}` across all 8 pages. Products land in
`products/`, variants in `products/variants/` (two different directories; the variant rows
are easy to miss because they only show up further down the grid).

## 3. Serve it

The routes are domain-scoped, so `SITE_URL` has to become `localhost` and the environment
file has to be `.env.local` — `APP_ENV=local` makes Laravel load `.env.local`, and it is
the same flag `logoImage()` checks.

```sh
cd c:/laragon/www/qbot
sed -e 's/^APP_ENV=.*/APP_ENV=local/' -e 's/^APP_DEBUG=.*/APP_DEBUG=false/' \
    -e 's/^DB_DATABASE=.*/DB_DATABASE=qbot_shots/' -e 's/^SITE_URL=.*/SITE_URL=localhost/' \
    -e 's/^MAIL_MAILER=.*/MAIL_MAILER=log/' -e 's/^BROADCAST_DRIVER=.*/BROADCAST_DRIVER=log/' \
    -e 's/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/' .env > .env.local
APP_ENV=local /c/laragon/bin/php/php-8.2.3/php.exe -d display_errors=0 artisan serve --host=0.0.0.0 --port=8124
```

`.env.local` is **deleted after each session**: it is a copy of `.env` and carries the live
Pusher, MailerSend and gateway keys, and the project gitignores only `.env`.

Then point the terminal at it. `qbot_pos/.env` is gitignored but holds **live GKASH
credentials**, so back it up first and restore it afterwards:

```sh
cd c:/laragon/www/qbot_pos
cp .env /tmp/qbot_pos.env.backup
# VITE_API_PRODUCTION_URL=http://pos-api.localhost:8124/api/pos/
# VITE_GKASH_USERNAME / _PASSWORD -> dummy values
npm run dev     # :5173
```

Only `VITE_API_PRODUCTION_URL` matters — `VITE_API_DEVELOPMENT_URL` is declared but never
read by any context.

## 4. Capture and annotate

```sh
PW_CORE=/path/to/playwright-core node qbotpos-capture.js   # -> upwork-covers/qbotpos-src/
node render-qbotpos.js                                     # -> upwork-covers/qbotpos/
```

`qbotpos-capture.js` walks the real flow — setup email, confirm company, pick store,
tap the passcode, add three items to the cart, open the menu, open Orders — because none
of those screens survive a deep link. Things it has to work around:

- **`php artisan serve` is single-threaded.** The catalogue is 8 pages and the order list
  is 7 pages of 100 with nested details, and React's dev double-mount requests each twice.
  The catalogue takes ~35s to finish and the orders ~20s more. The script waits on the
  rendered text and polls IndexedDB rather than using fixed sleeps.
- **The store list does not re-render after its own fetch.** The request returns 200 and
  writes to IndexedDB, but the mounted page keeps showing "0 stores available"; a reload
  fixes it. The script reloads once after setup for that reason.
- `networkidle` never settles on `/pos/:id` (the clock keeps a timer alive) — use
  `domcontentloaded`.

Pin coordinates live in `../../qbotpos-annotated.html`, in the same 1280×800 space as the
captures. Check a spot is clear before moving one:

```sh
./check-pins.sh ../../qbotpos-src/6-pos-cart.png "680,32 546,150 198,465"
```

A spot is clear when the 30×30 patch under the disc has a luminance spread under ~60.

## 5. Known gaps visible in the captures

- The Orders **Date column is empty**: `Orders.tsx` renders `order.booking_date`, but
  `App\Http\Resources\POS\OrderResources` returns no date field at all. Nothing on the
  client can fix it; the API resource has to send it.
- `Processing` reads 0 because no such status exists in the data.
