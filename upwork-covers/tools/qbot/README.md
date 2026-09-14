# QBot screenshot pipeline

Reproduces `upwork-covers/qbot/*.png` — annotated captures of the real app running
against a **sanitized copy** of the database. Nothing here touches `wonderpark_dev`
(the working database) or the project's `.env`.

## 1. Sanitized database

```sh
MB=/c/laragon/bin/mysql/mysql-8.0.30-winx64/bin
$MB/mysql.exe -uroot -e "drop database if exists qbot_shots; create database qbot_shots character set utf8mb4 collate utf8mb4_unicode_ci;"
$MB/mysqldump.exe -uroot --single-transaction --no-tablespaces wonderpark_dev | $MB/mysql.exe -uroot qbot_shots

cd c:/laragon/www/portfolio/upwork-covers/tools/qbot
for f in qbot-anonymize.sql qbot-anonymize-2.sql qbot-shift-dates.sql qbot-fill-gaps.sql; do
  $MB/mysql.exe -uroot -D qbot_shots < $f
done
```

What the scripts do:

- **qbot-anonymize.sql** — renames every tenant and outlet (the working data belongs to
  one real client), regenerates staff, customer, guest, supplier and assignee identities,
  and empties tokens, sessions, queues and gateway logs. Passwords become bcrypt of
  `password` with the `salt` column blanked, because the login check hashes `salt . plaintext`.
- **qbot-anonymize-2.sql** — the turnstile access log (visitor name, card number, device
  serial) and the customer-written review text in `feedback` / `insight`.
- **qbot-shift-dates.sql** — +287 days, which puts the busiest week on yesterday and today;
  future-dated rows are pulled back. Re-derive the offset if re-run much later.
- **qbot-fill-gaps.sql** — tenant roles were keyboard-mash test data; this gives them
  operator names (Cashier, Kitchen, Supervisor, Marketing, Accounts, Store Manager) and a
  permission set that actually differs per role, and fixes faker's US city names on outlets.

Two things done by hand afterwards, worth repeating: give recent orders a status mix
(they were all "Pending", so the dashboard's default "Paid" filter showed zeros), and set
order-line prices from the catalogue (the rows were RM1.06 test transactions).

## 2. Serve it

Routes are **domain-scoped**: `backend.<SITE_URL>` (platform console, `web` guard over
users), `backoffice.<SITE_URL>` (tenant admin, `backoffice` guard over employees),
plus `backoffice-api`, `pos-api` and a webstore resolved by store slug or custom domain.
So the server has to answer on any host, and `SITE_URL` becomes `localhost`:

```sh
cd c:/laragon/www/qbot
sed -e 's/^APP_ENV=.*/APP_ENV=shots/' -e 's/^APP_DEBUG=.*/APP_DEBUG=false/' \
    -e 's/^DB_DATABASE=.*/DB_DATABASE=qbot_shots/' -e 's/^SITE_URL=.*/SITE_URL=localhost/' \
    -e 's/^MAIL_MAILER=.*/MAIL_MAILER=log/' -e 's/^BROADCAST_DRIVER=.*/BROADCAST_DRIVER=log/' \
    -e 's/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/' .env > .env.shots
APP_ENV=shots /c/laragon/bin/php/php-8.2.3/php.exe -d display_errors=0 artisan serve --host=0.0.0.0 --port=8124
```

Then browse `http://backoffice.localhost:8124` and `http://backend.localhost:8124`
(Chromium resolves any `*.localhost` to 127.0.0.1).

**Keep `SESSION_SECURE_COOKIE=true`.** `config/session.php` hardcodes
`same_site => "none"`, and Chrome drops a SameSite=None cookie that is not marked Secure —
which shows up as a 419 Page Expired on login, not as a cookie error. `localhost` counts
as a trustworthy origin, so a Secure cookie is accepted over plain http there.

`.env.shots` is **deleted after each session**: it is a copy of `.env` and carries the live
Pusher, MailerSend and gateway keys, and the project gitignores only `.env`.

Logins after anonymizing: `staff1@example.com` / `password` (backoffice, tenant 6 admin)
and `platform1@example.com` / `password` (backend).

## 3. The webstore and the kitchen display

The storefront lives on the outlet's own host — `<store slug>.localhost:8124`, e.g.
`http://lagoon-park-kuala-terengganu.localhost:8124` — and the kitchen display is a public
screen on that same host at `/kitchen-queues/kds`. `ws-capture2.js` captures both.

**Never publish the storefront home page.** Its CMS blocks pull the client's real marketing
images straight from their live bucket (`wonderpark-qbot.sgp1.digitaloceanspaces.com/...`),
including their logo and a state crest, which undoes the renaming done in the database.
The functional pages — `/tickets`, cart, checkout, KDS — carry no bucket assets and show the
generic QBot mark where the outlet logo would be, so those are the safe ones.

Two things to prepare before shooting them, both already in `qbot-fill-gaps.sql`'s spirit and
worth repeating if the clone is rebuilt: rename the junk product names (`123`, `tryruyh`,
`test`) to real menu and ticket items, and give `products.price` a value where it is 0, or the
ticket cards read "RM 0.00". For the KDS specifically, the screen lists **every** line of any
order that has at least one food or beverage line, so point those orders' non-food lines at
food products too — otherwise a kitchen card shows "Photo Package".

## 4. Capture and annotate

```sh
node qbot-capture2.js   # backoffice + backend screens -> upwork-covers/qbot-src/
node ws-capture2.js     # storefront catalogue + kitchen display -> upwork-covers/qbot-src/
node ws-checkout.js     # cart + checkout (drives the real flow) -> upwork-covers/qbot-src/
node render-qbot.js     # sheets from qbot-annotated.html -> upwork-covers/qbot/
```

`ws-checkout.js` walks the flow rather than deep-linking, because the cart only exists once
items are added: it bumps quantities on `/tickets`, clicks the **Review Ticket Order** button
that appears in `#add-to-cart-section` (two exist — one is the mobile copy, so click the
*visible* one), lands on `/carts/{base64 id}`, then opens `/checkouts/detail`, chooses
**Continue as Guest**, fills the guest contact fields by id and selects a payment type.
Deep-linking `/carts` without an id just renders an empty cart.

`qbot-capture2.js` drives the UI where a default view is too narrow: it clicks
**This Month** on the dashboard and widens the orders and report filters to 30 days before
shooting. Pin coordinates live in `../../qbot-annotated.html`; check a spot is clear of ink
before moving one:

```sh
php check-pins.php ../../qbot-src/be-accounts.png 540,320 800,426
```

A spot is clear when nothing dark sits under the disc (`min >= 230`).
