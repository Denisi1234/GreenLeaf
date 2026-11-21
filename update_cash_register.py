with open('lib/ui/payment/cash_register_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add imports
old_import = "import 'widgets/register_row_tiles.dart';"
new_imports = "import 'widgets/register_row_tiles.dart';\nimport 'widgets/cash_register_closed_view.dart';\nimport 'widgets/cash_register_open_view.dart';"
text = text.replace(old_import, new_imports)

# Replace _buildClosedState and _buildOpenState and helper functions down to _openShift
target_closed_start = '  Widget _buildClosedState(PosLocalStore store) {'
target_open_shift = '  Future<void> _openShift(PosLocalStore store) async {'

start_idx = text.find(target_closed_start)
end_idx = text.find(target_open_shift)

if start_idx == -1 or end_idx == -1:
    print('Failed to find state methods block!')
    exit(1)

replacement_methods = '''  Widget _buildClosedState(PosLocalStore store) {
    return CashRegisterClosedView(
      store: store,
      registerController: _registerController,
      floatController: _floatController,
      isSwahili: _isSwahili,
      onOpenShift: _openShift,
      onOpenShiftDetail: _openShiftDetail,
    );
  }

  Widget _buildOpenState(PosLocalStore store, RegisterShift shift) {
    return CashRegisterOpenView(
      store: store,
      shift: shift,
      isSwahili: _isSwahili,
      onOpenMovementPage: _openMovementPage,
      onOpenClosePage: _openClosePage,
      onDeleteMovement: _deleteMovement,
    );
  }

'''

text = text[:start_idx] + replacement_methods + text[end_idx:]

with open('lib/ui/payment/cash_register_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print(f'New cash_register_page.dart lines: {len(text.splitlines())}')
