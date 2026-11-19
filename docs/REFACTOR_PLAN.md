# Refactor Plan — Large Files To Components

Goal: make large files reviewable, reusable and consistent by extracting
components and services without changing behaviour. Each step must end with
`dart analyze` clean for the touched files and `flutter test` passing.

## Rules

- Move code, do not rewrite behaviour in the same step.
- Extract by responsibility, not by line count.
- Keep public APIs stable; use barrel files while consumers are migrated.
- Feature-specific widgets live under `ui/<feature>/widgets/`.
- Shared primitives live under `ui/widgets/common/`.
- One step = one file family; verify before moving on.

## Completed

### `lib/ui/widgets/market_shared_widgets.dart` (2,346 lines -> barrel)

Split into:

- `widgets/common/`: `backdrop_glow`, `drawer_menu_button`,
  `header_action_button`, `market_button`, `market_form_field`,
  `market_notice`, `market_page_header`, `market_search_field`,
  `market_section_header`, `market_surface_card`, `market_table`
- `widgets/business/business_category_widgets.dart`
- `widgets/product_art/product_art.dart`
- `widgets/navigation/market_app_drawer.dart`
- `market_shared_widgets.dart` kept as export-only barrel.

## Queue (largest first)

| File | Lines | Target split |
| --- | ---: | --- |
| `service/pos_local_store.dart` | 2,725 | Domain controllers/mixins: `auth`, `cart`, `checkout`, `inventory`, `staff`, `stores`, `customers_debts`, `expenses`, `accounting`, `suppliers`, `preferences`. Keep `PosLocalStore` as the facade that mixes them in. |
| `ui/reports/enhanced_report_page.dart` | 1,786 | `reports/widgets/period_selector.dart`, `report_summary_section.dart`, `report_chart_section.dart`, `report_breakdown_section.dart`, `report_export_menu.dart`; page becomes composition. |
| `ui/more/settings_page.dart` | 1,737 | `settings/panes/business_pane.dart`, `receipt_form.dart`, `language_pane.dart`, `data_sync_pane.dart`, `account_pane.dart`, `about_pane.dart`, plus `settings/widgets/`. |
| `ui/more/expenses_tracking_page.dart` | 1,586 | `more/expenses/widgets/`: `range_card`, `payment_filter_row`, `payment_summary_card`, `expense_card`, `tax_banner`, `status_badge`, `category_icon`; page keeps state and composition. |
| `ui/reports/pos_report_data.dart` | 1,520 | Per-report builders: `sales_report_data.dart`, `items_report_data.dart`, `categories_report_data.dart`, `inventory_report_data.dart`, `customers_report_data.dart`, `employees_report_data.dart`, `discounts_report_data.dart`, `payments_report_data.dart`, `expenses_report_data.dart`, `profit_loss_report_data.dart`; shared `report_table.dart` models. |
| `service/pos_local_database.dart` | 1,539 | Tables by domain: orders, products, inventory, staff, customers, debts, expenses, suppliers, accounting, preferences. |
| `ui/suppliers/receiving_page.dart` | 1,331 | `suppliers/receiving/widgets/`: line editor, totals card, supplier picker, receipt summary. |
| `ui/payment/cash_register_page.dart` | 1,408 | `payment/cash_register/widgets/`: shift header, shift summary, cash movement list, movement form. |
| `ui/payment/payment_page.dart` | 1,330 | `payment/widgets/`: method selector, cash keypad, amount breakdown, split payment rows, credit customer picker. |
| `ui/more/staff_management_page.dart` | 1,306 | `more/staff/widgets/`: staff tile, role tile, filter bar, empty state. |
| `ui/more/customers_page.dart` | 1,262 | `more/customers/widgets/`: customer tile, summary header, filter bar. |
| `ui/more/add_edit_staff_page.dart` | 1,229 | Form sections: identity, contact, role, login credentials, schedule. |
| `ui/accounting/accounts_page.dart` | 1,056 | Account list, account form, balance summary widgets. |
| `ui/accounting/bank_reconciliation_page.dart` | 1,050 | Transaction list, match controls, summary widgets. |
| `ui/reports/services/pdf_report_service.dart` | 1,418 | Per-report PDF builders plus shared table/header helpers. |

## Suggested order

1. `settings_page.dart` — clean pane boundaries, high reuse.
2. `expenses_tracking_page.dart` — many independent cards.
3. `payment_page.dart` + `cash_register_page.dart` — shared payment widgets.
4. `pos_local_store.dart` — split after UI is stable, so method names settle.
5. `pos_local_database.dart` and report data/services — mechanical, low risk.

## Definition of done for each file

- Original file under ~400 lines (page shell/composition only).
- No duplicate widget definitions; reused pieces live in one place.
- All imports use the narrowest component file.
- No behaviour changes; tests and analysis pass.
- Update this document with the completed split.

## Known pre-existing issues

The working tree currently has unrelated in-progress edits.

- `lib/ui/products/product_management_page.dart` references missing
  `InventoryProductItem.unit`, `SharePayload`, and required constructor
  arguments (`artType`, `stockState`). These are independent of the widget split.
