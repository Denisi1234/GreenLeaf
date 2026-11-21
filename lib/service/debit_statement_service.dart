import 'dart:typed_data';
import 'debit_entry_model.dart';
import 'report_pdf/report_pdf_layout.dart';
import '../ui/reports/pos_report_data.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../ui/models/customer_data.dart';
import 'pos_local_store.dart';

/// Professional utility suite for Debit & Credit management:
/// - Debt aging calculation (Current, 1-15d, 16-30d, 30+d overdue)
/// - SMS and WhatsApp automated debt reminder messaging
/// - Beautiful branded Customer Statement PDF generation & sharing
class DebitStatementService {
  DebitStatementService._();

  static String _formatMoney(double value) {
    return 'TSh ${NumberFormat('#,##0.00').format(value)}';
  }

  /// Calculates aging days from the oldest unpaid debit charge.
  static int getAgingDays(CustomerData customer, PosLocalStore store) {
    if (customer.debitBalance <= 0) return 0;
    final charges = store
        .debitEntriesFor(customer.id)
        .where((entry) => !entry.isPayment)
        .toList();
    if (charges.isEmpty) return 0;
    final oldest = charges.last.createdAt;
    return DateTime.now().difference(oldest).inDays;
  }

  /// Categorizes customer debt aging.
  static DebtAgingCategory getAgingCategory(
      CustomerData customer, PosLocalStore store) {
    if (customer.debitBalance <= 0) return DebtAgingCategory.settled;
    final days = getAgingDays(customer, store);
    if (days > 30) return DebtAgingCategory.critical;
    if (days > 15) return DebtAgingCategory.overdue;
    if (days > 7) return DebtAgingCategory.attention;
    return DebtAgingCategory.current;
  }

  /// Generates a professional reminder message text in English or Swahili.
  static String buildReminderMessage({
    required CustomerData customer,
    required PosLocalStore store,
    required bool isSwahili,
  }) {
    final storeName = store.activeStoreName.isNotEmpty
        ? store.activeStoreName
        : 'TrackMauzo Store';
    final amount = _formatMoney(customer.debitBalance);

    if (isSwahili) {
      return 'Hujambo ${customer.name}, tunakukumbusha salio lako la deni lililobaki katika $storeName ni $amount. Tafadhali fanya malipo mapema. Asante kwa ushirikiano wako.';
    } else {
      return 'Hello ${customer.name}, this is a gentle reminder that your outstanding balance at $storeName is $amount. Kindly arrange for payment at your earliest convenience. Thank you!';
    }
  }

  /// Sends reminder via WhatsApp.
  static Future<bool> sendWhatsAppReminder({
    required CustomerData customer,
    required PosLocalStore store,
    required bool isSwahili,
  }) async {
    final phone = customer.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) return false;
    final message = Uri.encodeComponent(
      buildReminderMessage(
          customer: customer, store: store, isSwahili: isSwahili),
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Sends reminder via SMS.
  static Future<bool> sendSmsReminder({
    required CustomerData customer,
    required PosLocalStore store,
    required bool isSwahili,
  }) async {
    final phone = customer.phone.replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) return false;
    final message = Uri.encodeComponent(
      buildReminderMessage(
          customer: customer, store: store, isSwahili: isSwahili),
    );
    // Standard SMS uri scheme
    final uri = Uri.parse('sms:$phone?body=$message');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Generates and shares a Customer Debit Statement as PDF.
  static Future<void> generateAndSharePdf({
    required CustomerData customer,
    required PosLocalStore store,
    required AppStrings strings,
  }) async {
    final context =
        ReportPdfContext.fromStore(store, languageCode: strings.languageCode);
    final bytes = await buildPdf(
        customer: customer,
        entries: store.debitEntriesFor(customer.id),
        context: context);
    await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Statement_${customer.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}_${DateFormat('yyyyMMdd').format(context.generatedAt)}.pdf');
  }

  static Future<Uint8List> buildPdf({
    required CustomerData customer,
    required List<DebitEntry> entries,
    required ReportPdfContext context,
  }) {
    final totalCharged = entries
        .where((e) => !e.isPayment)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalPaid = entries
        .where((e) => e.isPayment)
        .fold<double>(0, (sum, e) => sum + e.amount);
    String money(double value) =>
        '${context.currency} ${NumberFormat('#,##0.00', context.languageCode).format(value)}';
    return ReportPdfLayout.tableDocument(
      title: context.label('Statement of account'),
      context: context,
      subtitle: customer.name,
      details: [
        MapEntry(context.label('Customer'), customer.name),
        if (customer.phone.isNotEmpty)
          MapEntry(context.label('Phone'), customer.phone),
        if (customer.email.isNotEmpty)
          MapEntry(context.label('Email'), customer.email),
        if (customer.address.isNotEmpty)
          MapEntry(context.label('Address'), customer.address),
        MapEntry(
            context.label('Status'),
            context
                .label(customer.debitBalance > 0 ? 'Outstanding' : 'Settled')),
      ],
      table: ReportTable([
        ReportColumn(context.label('Date')),
        ReportColumn(context.label('Type')),
        ReportColumn(context.label('Reference / Note')),
        ReportColumn(context.label('Charge (+)'), money: true),
        ReportColumn(context.label('Payment (-)'), money: true),
      ], [
        for (final entry in entries)
          [
            DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt),
            context.label(entry.isPayment ? 'Payment' : 'Credit sale'),
            [
              if (entry.orderId?.isNotEmpty == true) '#${entry.orderId}',
              if (entry.note.isNotEmpty) entry.note
            ].join(' | '),
            entry.isPayment ? null : entry.amount,
            entry.isPayment ? entry.amount : null,
          ]
      ],
          note: context.strings.isSwahili
              ? 'Asante kwa kufanya biashara nasi.'
              : 'Thank you for your business.'),
      summary: [
        MapEntry(context.label('Total charges'), money(totalCharged)),
        MapEntry(context.label('Total paid'), money(totalPaid)),
        MapEntry(
            context.label('Outstanding balance'), money(customer.debitBalance)),
      ],
    );
  }
}

enum DebtAgingCategory {
  settled,
  current, // 0 - 7 days
  attention, // 8 - 15 days
  overdue, // 16 - 30 days
  critical, // > 30 days
}
