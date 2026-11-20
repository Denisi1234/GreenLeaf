import os
import re

files = [
    'lib/ui/accounting/account_form_page.dart',
    'lib/ui/accounting/bank_line_form_page.dart',
    'lib/ui/accounting/import_statement_page.dart',
    'lib/ui/accounting/journal_entry_page.dart',
    'lib/ui/payment/cash_movement_page.dart',
    'lib/ui/payment/close_shift_page.dart',
    'lib/ui/payment/shift_detail_page.dart',
    'lib/ui/accounting/widgets/accounting_common_widgets.dart',
    'lib/ui/accounting/widgets/reconciliation_models.dart',
    'lib/ui/more/widgets/customer_hero_card.dart',
    'lib/ui/more/widgets/customer_history_widgets.dart',
    'lib/ui/more/widgets/expense_cards.dart',
    'lib/ui/more/widgets/expense_filter_widgets.dart',
    'lib/ui/more/widgets/staff_cards.dart',
    'lib/ui/more/widgets/staff_form_widgets.dart',
    'lib/ui/payment/widgets/register_models.dart',
    'lib/ui/reports/widgets/report_empty_state.dart',
]

for f in files:
    if not os.path.exists(f):
        continue
    with open(f, 'r', encoding='utf-8') as fp:
        content = fp.read()
    content = re.sub(r"import\s+['\"][^'\"]*widgets/market_(button|form_field|surface_card)\.dart['\"];\r?\n?", "", content)
    if 'market_shared_widgets.dart' not in content:
        content = "import 'package:track_mauzo/ui/widgets/market_shared_widgets.dart';\n" + content
    with open(f, 'w', encoding='utf-8') as fp:
        fp.write(content)
    print("Fixed:", f)
