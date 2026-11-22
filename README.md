# TrackMauzo

TrackMauzo is a comprehensive business tracking and Point of Sale (POS) solution designed to help small shops and individual sellers manage sales, inventory, customers, accounting, and reports with ease.

## Features

- **Sales Management**: Fast counter checkout with whole and fractional/measured units, barcode scanning, split payments, held sales, and thermal/PDF receipts.
- **Inventory Tracking**: Monitor stock levels, bulk packs, expiry dates, CSV import/export, and low-stock alerts.
- **Customers & Credit Ledger**: Manage customer profiles, credit sales, debt aging, statements, and repayments.
- **Expenses, Suppliers & Accounting**: Track business expenses, suppliers, goods receiving, cash register shifts, chart of accounts, fixed assets, and bank reconciliation.
- **Reporting**: Generate 60+ detailed, summary, graphical, accounting, and multi-store reports with PDF/CSV export and daily SMS summaries.
- **Offline-First & Bilingual**: Full offline SQLite persistence with optional PHP/MySQL cloud sync, supporting English (`en`) and Kiswahili (`sw`).

## Design System

All screens and components follow the TrackMauzo low-glare design system defined in:

- Design tokens: `lib/ui/widgets/app_design.dart` (`AppColors`, `AppTypography`,
  `AppSpacing`, `AppRadius`, `AppShadows`, `AppDecorations`)
- Global Material theme: `lib/ui/widgets/app_theme.dart`

Key TrackMauzo design rules to follow:

- **No stark white (`#FFFFFF`) on any internal section, card, dialog, or header**:
  - Page background: `AppColors.pageBackground` (`#D6E6F0`)
  - Section / card / dialog surfaces: `AppColors.surface` & `AppColors.sectionSurface` (`#E0EEF5`)
  - Top headers, bottom nav & desktop rail: `AppColors.headerSurface` (`#CBE6F0`)
  - Nested secondary surfaces: `AppColors.surfaceSecondary` (`#D3E4EE`)
  - Borders & dividers: `AppColors.border` (`#B0CBDB`)
- Neutral text scale (`#111827` ink → `#1F2937` main → `#6B7280` muted)
- Cyan-Teal primary brand & active actions (`#22B8C4`, deep `#1396A1`, soft `#E0EEF5`, light `#CBE6F0`)
- Semantic KPI pastel surfaces & deep accents (`AppColors.kpi*`):
  - **Rose**: `#FCE7F3` bg / `#BE185D` accent (`kpiRoseBg` / `kpiRose`)
  - **Sky**: `#E0F2FE` bg / `#0369A1` accent (`kpiSkyBg` / `kpiSky`)
  - **Amber**: `#FEF3C7` bg / `#B45309` accent (`kpiAmberBg` / `kpiAmber`)
  - **Danger**: `#FEE2E2` bg / `#B91C1C` accent (`kpiDangerBg` / `kpiDanger`)
  - **Violet**: `#EDE9FE` bg / `#6D28D9` accent (`kpiVioletBg` / `kpiViolet`)
  - **Success**: `#D1FAE5` bg / `#047857` accent (`kpiSuccessBg` / `kpiSuccess`)
  - **Neutral**: `#D3E4EE` bg / `#6B7280` accent (`kpiNeutralBg` / `kpiNeutral`)
- Radii: sharp `0px` inputs/search fields, pill (`99px`) buttons & toasts, `10px` cards/KPI tiles, `12px` dialogs, `18px` bottom sheets
- Typography: `Manrope` across the entire application
- Minimum touch targets 42–44px

When adding new screens, use these tokens instead of hard-coded colors so TrackMauzo stays
visually consistent across mobile and desktop.

## Architecture & Localization

- **State & Domain Services**: Offline-first SQLite + cloud sync via `PosLocalStore`, exposed through selective domain-scoped services (`AuthService`, `SalesService`, `InventoryService`, `AccountingService`) in `lib/service/services/`.
- **Modular PHP Backend**: `backend/src/Api.php` acts as a thin router delegating to focused services (`AuthService`, `OrderService`, `ResourceRepository`, `SmsService`, `UploadService`, `NotificationService`, and `ApiError`/`ApiValidator`). Verify with `php backend/tests/api_test.php`.
- **Documentation**: See `docs/ARCHITECTURE.md` and `docs/SRS.md`.
- **Localization (`.arb`)**: Source translations live in `lib/l10n/arb/app_en.arb` and `lib/l10n/arb/app_sw.arb`. Regenerate the per-locale Dart catalogs with:
  ```
  dart run tool/generate_l10n.dart
  ```

## Getting Started

To get started with TrackMauzo, follow these steps:

1. **Prerequisites**: Ensure you have Flutter installed on your machine.
2. **Installation**: Clone the repository and run `flutter pub get`.
3. **Run the App**: Execute `flutter run` to start the application on your preferred device.

## License

This project is licensed under the MIT License.
