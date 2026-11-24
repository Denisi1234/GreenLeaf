# TrackMauzo PHP backend

PHP 8.2 or newer with PDO and either SQLite or MySQL is required. The backend has no Composer dependencies.

## Run locally

From the GreenLeaf project directory, initialize the database and start the server.

```powershell
php backend/bin/migrate.php
php -S 127.0.0.1:8080 -t backend/public backend/public/index.php
```

The default server database is `backend/storage/trackmauzo.sqlite`. It is shared by every authenticated client connecting to this server. Account registration creates an empty shop. Existing device data and demo records are not imported automatically.

Run Flutter in a second terminal.

```powershell
flutter run -d chrome --web-port 53000 --dart-define=TRACKMAUZO_API_URL=http://127.0.0.1:8080/api
```

Create your business account on the sign-in screen. The first account for each shop is its owner. The API address is editable under **Server connection**. Android emulators use `http://10.0.2.2:8080/api` to reach the host. Physical devices need the server machine's reachable address. Use HTTPS for deployments.

For web clients, copy `.env.example` to `.env` and set `ALLOWED_ORIGINS` to the exact frontend origin, including its port. The local default permits `http://localhost:53000` and `http://127.0.0.1:53000`. Add the HTTPS website origin for a hosted frontend.

The Flutter app defaults to the PHP backend. The previous device database can be opened with `--dart-define=TRACKMAUZO_LOCAL=true`. Server sessions last 12 hours. The app keeps access tokens in memory, so restarting it requires another sign-in.

## Deploy with MySQL

Create a MySQL database named `trackmauzo` using the hosting control panel and grant a dedicated database user access to it. Copy `.env.example` to `.env` and set:

```dotenv
DB_DSN=mysql:host=127.0.0.1;port=3306;dbname=trackmauzo;charset=utf8mb4
DB_USER=your_database_user
DB_PASSWORD=your_database_password
ALLOWED_ORIGINS=https://your-frontend.example
ALLOW_REGISTRATION=true
FORCE_HTTPS=true
```

Run `php backend/bin/migrate.php` with those settings. The schema uses InnoDB for transactional writes. Point the web server's document root at `backend/public`, enable Apache rewriting, and configure HTTPS. The database, configuration, source, and tests belong outside the public document root. A server at `https://pos-api.example` exposes its API at `https://pos-api.example/api`.

Set `FORCE_HTTPS=true` in production; the API then refuses plain HTTP requests with `403` and sends `Strict-Transport-Security` on secure responses. If a reverse proxy terminates TLS, also set `TRUST_PROXY=true` so `X-Forwarded-Proto: https` is honoured, and ensure the proxy forwards that header. `HSTS_MAX_AGE` controls the HSTS lifetime in seconds (default `31536000`; set `0` to omit the header). Every API response also carries `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, a restrictive `Content-Security-Policy`, and `Cache-Control: no-store`.

After creating the required owner accounts, `ALLOW_REGISTRATION=false` closes public shop registration. The owner can continue creating staff logins through Staff Management. Staff sign in using their phone number and the password assigned there. Changing their password or disabling their staff record revokes existing access tokens.

SQLite and MySQL store separate data. Changing the DSN selects another database, and does not copy existing records.

## API

All business endpoints require `Authorization: Bearer <token>`. Every record is scoped to the authenticated user's shop. The server ignores client-supplied shop identifiers.

| Method | Path under /api | Purpose |
| --- | --- | --- |
| GET | /health | Database availability |
| POST | /auth/register | Create a shop and owner using phone, name, store_name, password and a verified otp_token |
| POST | /auth/login | Obtain a token using phone and password |
| GET | /auth/me | Current account |
| POST | /auth/logout | Revoke the current token |
| POST | /auth/users | Owner creates a cashier account |
| GET | /products | Shared product catalog and stock |
| GET | /orders | Completed sales with historical item costs |
| POST | /checkout | Record a sale and decrement stock atomically |
| POST | /orders/{id}/void | Reverse a sale, stock movements, and customer credit |
| GET | /reports/summary | Sales count, revenue, and expenses |
| POST | /staff/{id}/account | Save a staff record and create/reset its login |
| POST | /uploads | Upload validated image content as base64 JSON |
| GET | /uploads/{id} | Read a shop's authenticated image |

The following collections support GET, PUT to replace a collection, PUT /{id} to upsert a record, and DELETE /{id}.

- products
- customers
- expenses
- profile
- receipt-settings
- roles
- staff
- cart
- preferences
- recovery-sessions
- learning-rules
- ai-threads
- ai-messages

POST creates an individual record, except products, where the product code is supplied with PUT. Collection replacement uses `{"items": [...]}` and requires an `If-Match` header containing the collection's last-read `version`. A stale replacement returns HTTP 409. Refresh the data before retrying. Cart data is isolated to each signed-in session. Language preferences belong to the user.

Checkout accepts the order and line fields used by the Flutter app. The server validates price, quantity, discount, payment, and stock. Repeating the same order ID with the same body returns the original sale without deducting stock again. Reusing that ID with a different body returns HTTP 409. Amounts used for checkout arithmetic are stored in integer minor units.

Voided sales remain in the database for audit. They are excluded from completed-sales reports. The owner can manage business records. Staff permissions are loaded from their assigned roles on every request, including inventory, staff, reports, discounts, returns, payments, and system settings. Staff cannot grant permissions beyond their own role. A cashier can read the catalog, customers, and receipt details, and use checkout, their cart, and preferences.

Uploaded JPEG, PNG, and WebP images are limited to 2 MB and 24 megapixels and are protected by the shop's authentication. External AI inference still requires the AI provider configuration used by the app. The backend persists AI conversation and OCR recovery records.

## Verification

```powershell
php backend/tests/api_test.php
php backend/tests/feature_test.php
php backend/tests/security_test.php
```

`api_test.php` and `feature_test.php` use an isolated in-memory database and no network access. `api_test.php` covers authentication, shop isolation, stale-write rejection, stock and customer-credit transactions, duplicate-sale retries, rollback, voiding, settings, expenses, and cashier restrictions. `feature_test.php` adds end-to-end coverage for registration and OTP, routing and health, every generic resource (including optimistic concurrency and validation), cart and preference isolation, audit-log immutability, role-escalation guards, the full checkout matrix (cash, card, credit, discounts, idempotency, fractional quantities, voiding, summaries), multi-store branches, uploads, notifications, password reset, SMS throttling, and logout revocation. `security_test.php` unit-tests HTTPS detection (including trusted proxies), forced-HTTPS logic, security headers, and HSTS lifetimes. From the repository root, `make test-backend` runs all three.

For the Flutter integration test, start another PHP server against a disposable database and supply its API URL.

```powershell
$env:DB_DSN='sqlite:C:/path/to/GreenLeaf/backend/storage/http-test.sqlite'
php backend/bin/migrate.php
php -S 127.0.0.1:8081 -t backend/public backend/public/index.php
```

In a second terminal, run `flutter test --no-pub --dart-define=API_TEST_URL=http://127.0.0.1:8081/api test/php_backend_integration_test.dart`. The test creates test accounts and transactions in that database. Without `API_TEST_URL`, this test is skipped.
