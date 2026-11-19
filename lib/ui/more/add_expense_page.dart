import '../widgets/workspace_widgets.dart';
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
import '../widgets/app_image.dart';
import '../widgets/market_shared_widgets.dart';

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
  void initState() {
    super.initState();
    final existing = widget.expense;
    _titleController.text = existing?.title ?? '';
    _amountController.text = existing == null
        ? ''
        : existing.amount == existing.amount.roundToDouble()
            ? existing.amount.toStringAsFixed(0)
            : existing.amount.toString();
    _taxController.text = (existing == null || existing.taxAmount <= 0)
        ? ''
        : existing.taxAmount.toStringAsFixed(0);
    _vendorController.text = existing?.vendor ?? '';
    _notesController.text = existing?.notes ?? '';
    _selectedDate = existing?.date ?? DateTime.now();
    if (existing != null) {
      if (_categories.contains(existing.category)) {
        _category = existing.category;
      }
      if (_paymentMethods.contains(existing.paymentMethod)) {
        _paymentMethod = existing.paymentMethod;
      }
      _status = existing.status;
      _receiptPath = existing.receiptPath;
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

  /// Copies the picked image into the app documents directory so the record
  /// keeps working even if the original gallery file is removed.
  Future<String?> _persistReceipt(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${dir.path}/expense_receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      final target =
          '${receiptsDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(file.path).copy(target);
      return target;
    } catch (_) {
      return null;
    }
  }

  void _removeReceipt() {
    setState(() => _receiptPath = null);
  }

  Future<void> _saveExpense() async {
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
    try {
      if (base == null) {
        await store.addExpense(expense);
      } else {
        await store.updateExpense(expense);
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
      final strings = AppStrings.of(store.languageCode);
      showMarketNotice(
        context,
        title: _dual(strings, 'Expense saved', 'Matumizi yamehifadhiwa'),
        message: _dual(strings, '${expense.title} has been recorded.',
            '${expense.title} yamerekodiwa.'),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMarketNotice(
        context,
        title: _dual(AppStrings.of(store.languageCode), 'Save failed',
            'Imeshindwa kuhifadhi'),
        message: error.toString(),
        type: MarketNoticeType.warning,
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
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketSurfaceCard(
                            radius: AppRadius.standard,
                            borderColor: AppColors.border,
                            showShadow: false,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label(_dual(strings, 'Expense title',
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
                                _Label(_dual(
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
                                _Label(_dual(strings, 'Tax / VAT (optional)',
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
                                _Label(_dual(
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
                                          _Label(_dual(strings, 'Category',
                                              'Kategoria')),
                                          const SizedBox(height: 6),
                                          _Dropdown(
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
                                          _Label(_dual(
                                              strings, 'Payment', 'Malipo')),
                                          const SizedBox(height: 6),
                                          _Dropdown(
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
                                _Label(_dual(strings, 'Date', 'Tarehe')),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.zero,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.zero,
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            size: 20,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(dateLabel,
                                              style: AppTypography.bodyMedium),
                                        ),
                                        const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.textLight),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _Label(_dual(strings, 'Approval status',
                                    'Hali ya idhini')),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ExpenseStatus.values.map((status) {
                                    final selected = status == _status;
                                    return _ChoicePill(
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
                          _ReceiptCard(
                            path: _receiptPath,
                            strings: strings,
                            onPick: _pickReceipt,
                            onRemove: _removeReceipt,
                          ),
                          const SizedBox(height: 12),
                          MarketSurfaceCard(
                            radius: AppRadius.standard,
                            borderColor: AppColors.border,
                            showShadow: false,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label(_dual(strings, 'Notes (optional)',
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
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
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
                                _isSaving
                                    ? _dual(
                                        strings, 'Saving...', 'Inahifadhi...')
                                    : widget.isEditing
                                        ? _dual(strings, 'Save Changes',
                                            'Hifadhi Mabadiliko')
                                        : _dual(strings, 'Save Expense',
                                            'Hifadhi Matumizi'),
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
          )),
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
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.path,
    required this.strings,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final AppStrings strings;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasReceipt = path != null && path!.isNotEmpty;
    return MarketSurfaceCard(
      radius: 10,
      borderColor: const Color(0xFFD6E4F0),
      showShadow: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dual(strings, 'Receipt attachment', 'Kiambatisho cha risiti'),
              style: AppTypography.cardHeader),
          const SizedBox(height: 4),
          Text(
            _dual(strings, 'Optional photo of the paper receipt',
                'Picha ya hiari ya risiti ya karatasi'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (hasReceipt)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image(
                    image: appImageProvider(context, path!),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceSecondary,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dual(strings, 'Receipt attached', 'Risiti imeambatishwa'),
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(_dual(strings, 'Remove', 'Ondoa')),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label:
                    Text(_dual(strings, 'Attach receipt', 'Ambatisha risiti')),
              ),
            ),
        ],
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
        style: AppTypography.bodySmall
            .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600));
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    required this.strings,
  });
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
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

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? AppColors.primaryDeep : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
