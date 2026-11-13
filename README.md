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

Key OSPOS rules to follow:

- Slate text scale (`#0F172A` ink → `#64748B` muted), page background `#F6F6FB`, borders `#E2E8F0`
- Blue primary actions / active navigation (`#1D4ED8` on `#EFF6FF`)
- Teal active tabs & positive trends (`#14B8A6`, `#0F766E` on `#ECFDF5`)
- KPI cards on `#F4F2FB` with tone icons (violet, indigo, teal, lime)
- Radii: controls 10px, dialogs 12px, tiles 14px, KPI cards 16px, dashboard cards 18px
- Minimum touch targets 42–44px

When adding new screens, use these tokens instead of hard-coded colors so TrackMauzo stays
visually consistent with OSPOS.

## Getting Started

To get started with TrackMauzo, follow these steps:

1. **Prerequisites**: Ensure you have Flutter installed on your machine.
2. **Installation**: Clone the repository and run `flutter pub get`.
3. **Run the App**: Execute `flutter run` to start the application on your preferred device.

## License

This project is licensed under the MIT License.
