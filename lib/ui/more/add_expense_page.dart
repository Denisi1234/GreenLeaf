import 'package:flutter/material.dart';

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
  final _dateController = TextEditingController(text: 'May 20, 2025');
  final _notesController = TextEditingController();
  String _category = 'Operations';
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  static const _categories = <String>[
    'Operations',
    'Inventory',
    'Utilities',
    'Marketing',
    'Transport',
    'Office',
  ];

  static const _paymentMethods = <String>[
    'Cash',
    'Bank Transfer',
    'Mobile Money',
    'Card',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      showMarketNotice(
        context,
        title: 'Check The Form',
        message: 'Fill in the expense details before saving',
        type: MarketNoticeType.warning,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    showMarketNotice(
      context,
      title: 'Expense Saved',
      message: '${_titleController.text.trim()} has been recorded',
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(title: 'Add Expense'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E7EF)),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Color(0xFFE8F0FF),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: Color(0xFF2B5FCE),
                                size: 40,
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Record daily expenses as they happen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 13.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ExpenseField(
                        label: 'Expense Title',
                        hint: 'Enter expense title',
                        controller: _titleController,
                        icon: Icons.short_text_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Expense title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ExpenseField(
                              label: 'Amount',
                              hint: '0.00',
                              controller: _amountController,
                              icon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DropdownField(
                              label: 'Category',
                              icon: Icons.category_outlined,
                              value: _category,
                              items: _categories,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _category = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownField(
                              label: 'Payment Method',
                              icon: Icons.account_balance_wallet_outlined,
                              value: _paymentMethod,
                              items: _paymentMethods,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _paymentMethod = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ExpenseField(
                              label: 'Date',
                              hint: 'Select date',
                              controller: _dateController,
                              icon: Icons.calendar_month_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Date is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ExpenseField(
                        label: 'Notes',
                        hint: 'Add a short note',
                        controller: _notesController,
                        icon: Icons.notes_outlined,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Notes are required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isSaving ? null : _saveExpense,
                        child: AnimatedOpacity(
                          opacity: _isSaving ? 0.8 : 1,
                          duration: const Duration(milliseconds: 160),
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF356BD8),
                                  Color(0xFF2B5FCE),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSaving
                                      ? Icons.hourglass_top_rounded
                                      : Icons.add_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isSaving ? 'Saving...' : 'Save Expense',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseField extends StatelessWidget {
  const _ExpenseField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E273A),
            fontSize: 14.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE2EA)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              color: Color(0xFF1E273A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF7A8393),
                size: 22,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFABB2BF),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E273A),
            fontSize: 14.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE2EA)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF7A8393),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF7A8393),
                size: 22,
              ),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF1E273A),
                        fontSize: 14.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
