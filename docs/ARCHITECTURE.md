# GreenLeaf / TrackMauzo Architecture

TrackMauzo is a Flutter point-of-sale app with an offline-first local store and an
optional PHP/MySQL cloud backend.

## Layered structure

```
lib/
  main.dart, app.dart        App bootstrap, theme, providers, routing root
  ui/                        Screens and visual components
  service/                   Business logic, storage, sync, API clients
  l10n/                      English/Kiswahili strings
  utils/                     Small shared helpers
backend/                     PHP API + schema + tests
```

### UI layer (`lib/ui`)

| Folder | Responsibility |
| --- | --- |
| `auth/` | Onboarding, login, registration, password reset |
| `home/` | Sales/checkout surface and suspended sales |
| `payment/` | Payment capture, cash register, debtor payments |
| `products/` | Product catalogue and inventory editing |
| `suppliers/` | Suppliers and stock receiving |
| `more/` | Customers, debtors, staff, expenses, stores, settings |
| `accounting/` | Accounts, journal, bank reconciliation, fixed assets |
| `reports/` | Dashboard, report catalog/data, exports |
| `receipt/` | Receipt preview, success screen, PDF generation |
| `notifications/` | In-app notification list |
| `shell/` | App shell and navigation chrome |
| `widgets/` | Reusable visual components (see below) |

### State layer (`lib/service/pos_local_store.dart`)

`PosLocalStore` is a `ChangeNotifier` provided at app root. Screens read it with
`context.watch<PosLocalStore>()` (rebuild) or `context.read<PosLocalStore>()`
(actions). It owns the in-memory domain state (orders, products, inventory,
customers, debts, expenses, accounting, staff, stores, preferences) and exposes
intent-style methods (`addToCart`, `completeCashSale`, `voidOrder`,
`recordDebtPayment`, `saveReceiving`, ...).

Persistence goes through `PosHybridDatabase`, which chooses local SQLite
(`PosLocalDatabase`) and/or cloud storage (`PosCloudDatabase` + `PhpApiClient`).

### Service layer (`lib/service`)

| File | Responsibility |
| --- | --- |
| `pos_local_store.dart` | App state, auth, cart, sales, inventory, staff, stores |
| `pos_order_models.dart` | Order, cart line, completed order models |
| `pos_local_database.dart` | Local SQLite schema and CRUD |
| `pos_cloud_database.dart` | Cloud-backed persistence |
| `pos_hybrid_database.dart` | Local/cloud selection and sync |
| `php_api_client.dart` | HTTP client for the PHP backend |
| `accounting_engine.dart` | Double-entry posting and reports |
| `store_models.dart`, `customer`/`expense`/`supplier` models | Domain models |
| `receipt_settings.dart`, `tax_settings.dart`, `store_preferences.dart` | Config value objects |
| `daily_sales_report_service.dart` | Daily SMS summary |
| `app_notification_service.dart` | Local notification scheduling |
| `register_shift_model.dart` | Shift and cash movement models |

## Shared component library (`lib/ui/widgets`)

Implementation is split by responsibility. `market_shared_widgets.dart` is a
**barrel only**; it re-exports everything so existing imports keep working.

```
widgets/
  market_shared_widgets.dart          barrel (export only)
  app_design.dart                     colors, spacing, radius, typography
  app_image.dart                      local/remote image provider
  app_theme.dart                      ThemeData
  common/                             primitives used across features
    backdrop_glow.dart
    drawer_menu_button.dart
    header_action_button.dart
    market_button.dart
    market_form_field.dart
    market_notice.dart                showMarketNotice + MarketNoticeType
    market_page_header.dart
    market_search_field.dart
    market_section_header.dart
    market_surface_card.dart
    market_table.dart
  business/                           business-category-aware widgets
    business_category_widgets.dart
  product_art/                        drawn product illustrations
    product_art.dart
  navigation/                         app chrome
    market_app_drawer.dart
```

### Component rules

1. Prefer importing the specific component file in new code, e.g.
   `import '../widgets/common/market_button.dart';`.
2. Keep the barrel import only in legacy files; do not add new barrel imports.
3. `common/` components must not import feature screens.
4. Feature-specific widgets live next to their feature
   (`ui/<feature>/widgets/`), not in `common/`.
5. Colors, spacing, radii and text styles come from `app_design.dart`; do not
   hardcode new design tokens in widgets.
6. UI components never call the backend directly. They call `PosLocalStore`.
7. A widget that performs async work must guard `mounted` before using context.

## Data flow

```
Screen -> PosLocalStore method -> PosHybridDatabase -> local/cloud
                              -> notifyListeners() -> screens rebuild
```

- Cloud sessions are represented by a non-null `cloudApi`; local-only sessions
  set `isLoggedIn` directly.
- OTP, password reset, staff account changes and SMS must go through the PHP
  backend. Never generate or accept verification codes on the device.
- SMS/NextSMS credentials live only in `backend/.env`; never ship them in the app.

## Backend

`backend/src/Api.php` is the HTTP router and domain API. Public routes:
`auth/register`, `auth/login`, `auth/otp/send`, `auth/otp/verify`,
`auth/reset-password`, plus health. Everything else requires a bearer token.
SMS is proxied through authenticated `sms/send` with the `View Reports`
permission and IP throttling.

Config is read from `backend/.env` via `backend/config.php`. Required production
values: `DB_DSN`, `DB_USER`, `DB_PASSWORD`, `ALLOWED_ORIGINS`,
`NEXTSMS_USERNAME`, `NEXTSMS_PASSWORD`.

## Conventions

- Language: UI strings come from `AppStrings.of(languageCode)`; support both
  English and Kiswahili.
- Money: use existing currency formatting helpers, never raw stringify doubles.
- Dates: store ISO-8601; daily SMS calculations use East Africa Time (UTC+3).
- Permissions: check via `cloudApi.can(permission)` and mirror the permission
  names used by the backend (`View Reports`, `Manage Staff`, ...).
- Tests: `flutter test`; static analysis: `dart analyze <paths>`.
