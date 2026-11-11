import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _category = 'Operations';
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  static const _categories = <String>[
    'Operations',
    'Inventory',
    'Rent',
    'Utilities',
    'Marketing',
    'Transport',
    'Office',
    'Supplies',
    'Maintenance',
    'Other',
  ];

  static const _paymentMethods = <String>[
    'Cash',
    'Bank Transfer',
    'Mobile Money',
    'Card',
    'Credit',
    'Check',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.ink,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      showMarketNotice(
        context,
        title: 'Check form',
        message: 'Fill in the required expense details before saving.',
        type: MarketNoticeType.warning,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    final expense = Expense(
      title: _titleController.text.trim(),
      amount: amount,
      category: _category,
      paymentMethod: _paymentMethod,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await context.read<PosLocalStore>().addExpense(expense);
    if (!mounted) return;
    setState(() => _isSaving = false);
    showMarketNotice(
      context,
      title: 'Expense saved',
      message: '${expense.title} has been recorded.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, yyyy').format(_selectedDate);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(
              title: 'Add Expense',
              subtitle: 'Record a business expense',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarketSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Expense title'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              textCapitalization: TextCapitalization.sentences,
                              style: AppTypography.bodyMedium,
                              decoration: _inputDecoration(
                                hint: 'e.g. Store rent, electricity bill',
                                icon: Icons.receipt_long_outlined,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Expense title is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _Label('Amount (TSH)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              style: AppTypography.bodyMedium,
                              decoration: _inputDecoration(
                                hint: '0.00',
                                icon: Icons.payments_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                final parsed = double.tryParse(
                                    v.trim().replaceAll(',', ''));
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Label('Category'),
                                      const SizedBox(height: 6),
                                      _Dropdown(
                                        value: _category,
                                        items: _categories,
                                        icon: Icons.category_outlined,
                                        onChanged: (v) =>
                                            setState(() => _category = v),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Label('Payment'),
                                      const SizedBox(height: 6),
                                      _Dropdown(
                                        value: _paymentMethod,
                                        items: _paymentMethods,
                                        icon: Icons.account_balance_wallet_outlined,
                                        onChanged: (v) =>
                                            setState(() => _paymentMethod = v),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _Label('Date'),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined,
                                        size: 20, color: AppColors.textMuted),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(dateLabel,
                                          style: AppTypography.bodyMedium),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textLight),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Label('Notes (optional)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              style: AppTypography.bodyMedium,
                              decoration: _inputDecoration(
                                hint: 'Add a short description',
                                icon: Icons.notes_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Expense',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.bodySmall.copyWith(
            color: AppColors.ink, fontWeight: FontWeight.w600));
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textLight),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: AppTypography.bodySmall)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
