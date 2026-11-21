# TrackMauzo

TrackMauzo is a comprehensive business tracking solution designed to help you manage sales, inventory, and reports with ease.

## Features

- **Sales Management**: Track your daily sales and transactions.
- **Inventory Tracking**: Monitor stock levels and receive alerts.
- **Reporting**: Generate detailed reports to gain insights into your business performance.
- **User-Friendly Interface**: Easy to navigate and use for all business types.

## Relationship to Open Source POS (OSPOS)

TrackMauzo is the **mini / B2C edition** of our larger **Open Source Point of Sale** project
(local path: `C:\Users\hp\Desktop\opensourcepos`).

| | OSPOS (`opensourcepos`) | TrackMauzo (this repo) |
|---|---|---|
| Audience | **B2B** – larger businesses, multi-user back office | **B2C** – small shops & individual sellers |
| Platform | PHP / CodeIgniter web app | Flutter mobile & desktop app |
| Scope | Full version | Lightweight "mini" version of the same app |

Both are the **same product family**, so TrackMauzo should keep improving to match OSPOS
as closely as possible — **especially the design pattern** (colors, typography, spacing,
cards, tabs, navigation and touch targets) and core workflows.

### Design source of truth

The UI theme is ported from the OSPROS "UI maturity" styles in
`opensourcepos/public/css/ospos.css` (dashboard, drawer, tabs, module tiles, mobile rules)
and the brand guide in `opensourcepos/branding/STYLE_GUIDE.md`.

- Design tokens: `lib/ui/widgets/app_design.dart` (`AppColors`, `AppTypography`,
  `AppSpacing`, `AppRadius`, `AppShadows`, `AppDecorations`)
- Global Material theme: `lib/ui/widgets/app_theme.dart` (`buildOsposTheme`)

Key TrackMauzo / OSPOS design rules to follow:

- **No stark white (`#FFFFFF`) on any section, card, dialog, or header**:
  - Page background: `AppColors.pageBackground` (`#EAF2F9`)
  - Section / card / dialog surfaces: `AppColors.surface` & `AppColors.sectionSurface` (`#F0F9FB`)
  - Top headers, bottom nav & desktop rail: `AppColors.headerSurface` (`#E0F4F8`)
  - Borders & dividers: `AppColors.border` (`#D6E4F0`)
- Neutral text scale (`#111827` ink → `#1F2937` main → `#6B7280` muted)
- Cyan-Teal primary brand & active actions (`#22B8C4`, deep `#1396A1`, soft `#F0F9FB`, light `#E0F4F8`)
- Semantic KPI pastel surfaces & deep accents (`AppColors.kpi*`):
  - **Rose**: `#FCE7F3` bg / `#BE185D` accent (`kpiRoseBg` / `kpiRose`)
  - **Sky**: `#E0F2FE` bg / `#0369A1` accent (`kpiSkyBg` / `kpiSky`)
  - **Amber**: `#FEF3C7` bg / `#B45309` accent (`kpiAmberBg` / `kpiAmber`)
  - **Danger**: `#FEE2E2` bg / `#B91C1C` accent (`kpiDangerBg` / `kpiDanger`)
  - **Violet**: `#EDE9FE` bg / `#6D28D9` accent (`kpiVioletBg` / `kpiViolet`)
  - **Success**: `#D1FAE5` bg / `#047857` accent (`kpiSuccessBg` / `kpiSuccess`)
  - **Neutral**: `#F1F5F9` bg / `#6B7280` accent (`kpiNeutralBg` / `kpiNeutral`)
- Radii: controls 10px, dialogs 12px, tiles 14px, KPI cards 16px, dashboard cards 18px
- Minimum touch targets 42–44px

When adding new screens, use these tokens instead of hard-coded colors so TrackMauzo stays
visually consistent with OSPOS.

## Architecture & Localization

- **State & Domain Services**: Offline-first SQLite + cloud sync via `PosLocalStore`, exposed through selective domain-scoped services (`AuthService`, `SalesService`, `InventoryService`, `AccountingService`) in `lib/service/services/`.
- **Modular PHP Backend**: `backend/src/Api.php` acts as a thin router delegating to focused services (`AuthService`, `OrderService`, `ResourceRepository`, `SmsService`, `UploadService`, `NotificationService`, and `ApiError`/`ApiValidator`). Verify with `php backend/tests/api_test.php`.
- **Localization (`.arb`)**: Source translations live in `lib/l10n/arb/app_en.arb` and `lib/l10n/arb/app_sw.arb`. Regenerate the per-locale Dart catalogs with:
  ```bash
  dart run tool/generate_l10n.dart
  ```

## Getting Started

To get started with TrackMauzo, follow these steps:

1. **Prerequisites**: Ensure you have Flutter installed on your machine.
2. **Installation**: Clone the repository and run `flutter pub get`.
3. **Run the App**: Execute `flutter run` to start the application on your preferred device.

## License

This project is licensed under the MIT License.
