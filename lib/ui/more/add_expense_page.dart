import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/expense_form_fields.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key, this.expense});

  /// When provided the page edits that record instead of creating a new one.
  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  String _category = 'Operations';
  String _paymentMethod = 'Cash';
  ExpenseStatus _status = ExpenseStatus.submitted;
  String? _receiptPath;
  bool _isSaving = false;

  static const _categories = <String>[
    'Operations',
    'Inventory',
    'Utilities',
    'Salaries',
    'Marketing',
    'Rent',
    'Transport',
    'Maintenance',
    'Other',
  ];

  static const _paymentMethods = <String>[
    'Cash',
    'Mobile Money',
    'Bank Transfer',
    'Card',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(0);
      _taxController.text =
          expense.taxAmount > 0 ? expense.taxAmount.toStringAsFixed(0) : '';
      _vendorController.text = expense.vendor;
      _notesController.text = expense.notes ?? '';
      _selectedDate = expense.date;
      _category = _categories.contains(expense.category)
          ? expense.category
          : 'Operations';
      _paymentMethod = _paymentMethods.contains(expense.paymentMethod)
          ? expense.paymentMethod
          : 'Cash';
      _status = expense.status;
      _receiptPath = expense.receiptPath;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _pickReceipt() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (!mounted || file == null) return;
      final saved = await _persistReceipt(file);
      if (!mounted || saved == null) return;
      setState(() => _receiptPath = saved);
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: _dual(AppStrings.of(context.read<PosLocalStore>().languageCode),
            'Image unavailable', 'Picha haipatikani'),
        message: _dual(
            AppStrings.of(context.read<PosLocalStore>().languageCode),
            'Could not open the gallery on this device.',
            'Imeshindwa kufungua ghala kwenye kifaa hiki.'),
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<String?> _persistReceipt(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${dir.path}/expense_receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      final filename =
          'receipt_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final target = File('${receiptsDir.path}/$filename');
      await file.saveTo(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }

  void _removeReceipt() {
    setState(() => _receiptPath = null);
  }

  Future<void> _saveExpense() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      showMarketNotice(
        context,
        title: _dual(AppStrings.of(context.read<PosLocalStore>().languageCode),
            'Check form', 'Angalia fomu'),
        message: _dual(
            AppStrings.of(context.read<PosLocalStore>().languageCode),
            'Fill in the required expense details before saving.',
            'Jaza maelezo muhimu ya matumizi kabla ya kuhifadhi.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    final tax =
        double.tryParse(_taxController.text.trim().replaceAll(',', '')) ?? 0;

    final base = widget.expense;
    final expense = Expense(
      id: base?.id,
      title: _titleController.text.trim(),
      amount: amount,
      category: _category,
      paymentMethod: _paymentMethod,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      vendor: _vendorController.text.trim(),
      taxAmount: tax,
      receiptPath: _receiptPath,
      status: _status,
      createdAt: base?.createdAt,
    );

    final store = context.read<PosLocalStore>();
    final nav = Navigator.of(context);
    final strings = AppStrings.of(store.languageCode);

    try {
      if (base == null) {
        await store.addExpense(expense);
      } else {
        await store.updateExpense(expense);
      }
      if (!mounted) return;
      showMarketNotice(
        context,
        title: base == null
            ? _dual(strings, 'Expense Recorded', 'Matumizi Yamerekodiwa')
            : _dual(strings, 'Expense Updated', 'Matumizi Yamesasishwa'),
        message: _dual(
            strings,
            '${expense.title} has been recorded successfully.',
            '${expense.title} imerekodiwa kikamilifu.'),
        type: MarketNoticeType.success,
      );
      nav.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMarketNotice(
        context,
        title: _dual(strings, 'Save Failed', 'Imeshindikana Kuhifadhi'),
        message: error.toString(),
        type: MarketNoticeType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);
    final dateLabel = DateFormat('MMM d, yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MarketPageHeader(
                  title: widget.isEditing
                      ? _dual(strings, 'Edit Expense', 'Hariri Matumizi')
                      : _dual(strings, 'Add Expense', 'Ongeza Matumizi'),
                  subtitle: widget.isEditing
                      ? _dual(strings, 'Update this expense record',
                          'Sasisha rekodi hii ya matumizi')
                      : _dual(strings, 'Record a business expense',
                          'Rekodi matumizi ya biashara'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketSurfaceCard(
                            radius: AppRadius.standard,
                            borderColor: AppColors.border,
                            showShadow: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(_dual(strings, 'Expense title',
                                    'Kichwa cha matumizi')),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _titleController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: AppTypography.bodyMedium,
                                  decoration: _inputDecoration(
                                    hint: _dual(
                                        strings,
                                        'e.g. Store rent, electricity bill',
                                        'mf. Kodi ya duka, bili ya umeme'),
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                  validator: (v) => (v == null ||
                                          v.trim().isEmpty)
                                      ? _dual(
                                          strings,
                                          'Expense title is required',
                                          'Kichwa cha matumizi kinahitajika')
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _fieldLabel(_dual(
                                    strings, 'Amount (TSH)', 'Kiasi (TSH)')),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: AppTypography.bodyMedium,
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    icon: Icons.payments_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return _dual(
                                          strings,
                                          'Amount is required',
                                          'Kiasi kinahitajika');
                                    }
                                    final parsed = double.tryParse(
                                        v.trim().replaceAll(',', ''));
                                    if (parsed == null || parsed <= 0) {
                                      return _dual(
                                          strings,
                                          'Enter a valid amount',
                                          'Weka kiasi sahihi');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _fieldLabel(_dual(
                                    strings,
                                    'Tax / VAT (optional)',
                                    'Kodi / VAT (hiari)')),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _taxController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: AppTypography.bodyMedium,
                                  decoration: _inputDecoration(
                                    hint: '0.00',
                                    icon: Icons.percent_rounded,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _fieldLabel(_dual(
                                    strings,
                                    'Vendor / supplier (optional)',
                                    'Muuzaji / msambazaji (hiari)')),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _vendorController,
                                  textCapitalization: TextCapitalization.words,
                                  style: AppTypography.bodyMedium,
                                  decoration: _inputDecoration(
                                    hint: _dual(strings, 'Who was paid',
                                        'Nani alilipwa'),
                                    icon: Icons.storefront_outlined,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _fieldLabel(_dual(strings, 'Category',
                                              'Kategoria')),
                                          const SizedBox(height: 6),
                                          ExpenseFormDropdown(
                                            value: _category,
                                            items: _categories,
                                            icon: Icons.category_outlined,
                                            onChanged: (v) =>
                                                setState(() => _category = v),
                                            strings: strings,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _fieldLabel(_dual(
                                              strings, 'Payment', 'Malipo')),
                                          const SizedBox(height: 6),
                                          ExpenseFormDropdown(
                                            value: _paymentMethod,
                                            items: _paymentMethods,
                                            icon: Icons
                                                .account_balance_wallet_outlined,
                                            onChanged: (v) => setState(
                                                () => _paymentMethod = v),
                                            strings: strings,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _fieldLabel(_dual(strings, 'Date', 'Tarehe')),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: AppCorners.control,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSecondary,
                                      borderRadius: AppCorners.control,
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                            Icons.calendar_month_outlined,
                                            size: 20,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(dateLabel,
                                              style: AppTypography.bodyMedium),
                                        ),
                                        Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.textLight),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _fieldLabel(_dual(strings, 'Approval status',
                                    'Hali ya idhini')),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ExpenseStatus.values.map((status) {
                                    final selected = status == _status;
                                    return ExpenseChoicePill(
                                      label:
                                          status.localized(strings.isSwahili),
                                      selected: selected,
                                      onTap: () =>
                                          setState(() => _status = status),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ExpenseReceiptCard(
                            path: _receiptPath,
                            strings: strings,
                            onPick: _pickReceipt,
                            onRemove: _removeReceipt,
                          ),
                          const SizedBox(height: 12),
                          MarketSurfaceCard(
                            radius: AppRadius.standard,
                            borderColor: AppColors.border,
                            showShadow: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(_dual(strings, 'Notes (optional)',
                                    'Maelezo (hiari)')),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  style: AppTypography.bodyMedium,
                                  decoration: _inputDecoration(
                                    hint: _dual(
                                        strings,
                                        'Add a short description',
                                        'Ongeza maelezo mafupi'),
                                    icon: Icons.notes_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: MarketButton(
                          label: _dual(strings, 'Cancel', 'Ghairi'),
                          color: AppColors.kpiDangerBg,
                          foregroundColor: AppColors.kpiDanger,
                          borderColor: null,
                          radius: AppRadius.input,
                          onTap: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: MarketButton(
                          label: _isSaving
                              ? _dual(strings, 'Saving...', 'Inahifadhi...')
                              : widget.isEditing
                                  ? _dual(strings, 'Save Changes',
                                      'Hifadhi Mabadiliko')
                                  : _dual(strings, 'Save Expense',
                                      'Hifadhi Matumizi'),
                          icon: _isSaving ? null : Icons.check_rounded,
                          variant: MarketButtonVariant.primary,
                          borderColor: null,
                          radius: AppRadius.input,
                          height: 48,
                          onTap: _isSaving ? null : _saveExpense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall
          .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppCorners.control,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppCorners.control,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppCorners.control,
        borderSide: BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppCorners.control,
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppCorners.control,
        borderSide: BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }
}
