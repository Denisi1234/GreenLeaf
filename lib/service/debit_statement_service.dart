import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../ui/models/customer_data.dart';
import 'debit_entry_model.dart';
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
  static DebtAgingCategory getAgingCategory(CustomerData customer, PosLocalStore store) {
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
      buildReminderMessage(customer: customer, store: store, isSwahili: isSwahili),
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
      buildReminderMessage(customer: customer, store: store, isSwahili: isSwahili),
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
    final doc = pw.Document();
    final entries = store.debitEntriesFor(customer.id);
    final storeName = store.activeStoreName.isNotEmpty
        ? store.activeStoreName
        : 'TrackMauzo Store';
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(now);

    final totalCharged = entries
        .where((e) => !e.isPayment)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalPaid = entries
        .where((e) => e.isPayment)
        .fold<double>(0, (sum, e) => sum + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    storeName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    strings.isSwahili ? 'TAARIFA YA DENI NA MALIPO' : 'STATEMENT OF ACCOUNT',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '${strings.isSwahili ? 'Tarehe' : 'Date'}: $formattedDate',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${strings.isSwahili ? 'Hali' : 'Status'}: ${customer.debitBalance > 0 ? (strings.isSwahili ? 'LINA DENI' : 'OUTSTANDING') : (strings.isSwahili ? 'LIMEKAMLIKA' : 'SETTLED')}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: customer.debitBalance > 0 ? PdfColors.red800 : PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300, height: 24),

          // Customer info box & Summary
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        strings.isSwahili ? 'TAARIFA ZA MTEJA' : 'BILL TO',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        customer.name,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      if (customer.phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('${strings.isSwahili ? 'Simu' : 'Phone'}: ${customer.phone}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (customer.email.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (customer.address.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('${strings.isSwahili ? 'Mahali' : 'Address'}: ${customer.address}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    color: customer.debitBalance > 0 ? PdfColors.red50 : PdfColors.green50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        strings.isSwahili ? 'MUHTASARI WA DENI' : 'ACCOUNT SUMMARY',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 6),
                      _pdfRow(strings.isSwahili ? 'Jumla ya Madeni' : 'Total Charges', _formatMoney(totalCharged)),
                      _pdfRow(strings.isSwahili ? 'Jumla ya Malipo' : 'Total Paid', _formatMoney(totalPaid)),
                      pw.Divider(thickness: 0.5, color: PdfColors.grey300, height: 10),
                      _pdfRow(
                        strings.isSwahili ? 'Deni Lililobaki' : 'Balance Due',
                        _formatMoney(customer.debitBalance),
                        bold: true,
                        color: customer.debitBalance > 0 ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Transactions Table
          pw.Text(
            strings.isSwahili ? 'Historia ya Shughuli' : 'Transaction History',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 8),

          if (entries.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Center(
                child: pw.Text(
                  strings.isSwahili ? 'Hakuna rekodi za mkopo au malipo.' : 'No transactions recorded.',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: [
                strings.isSwahili ? 'Tarehe' : 'Date',
                strings.isSwahili ? 'Aina' : 'Type',
                strings.isSwahili ? 'Maelezo / Namba' : 'Reference / Note',
                strings.isSwahili ? 'Deni (+)' : 'Charge (+)',
                strings.isSwahili ? 'Malipo (-)' : 'Payment (-)',
              ],
              data: entries.map((entry) {
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);
                final typeStr = entry.isPayment
                    ? (strings.isSwahili ? 'Malipo' : 'Payment')
                    : (strings.isSwahili ? 'Mauzo ya Mkopo' : 'Credit Sale');
                final noteStr = [
                  if (entry.orderId != null && entry.orderId!.isNotEmpty) '#${entry.orderId}',
                  if (entry.note.isNotEmpty) entry.note,
                ].join(' · ');

                return [
                  dateStr,
                  typeStr,
                  noteStr.isEmpty ? '-' : noteStr,
                  !entry.isPayment ? _formatMoney(entry.amount) : '-',
                  entry.isPayment ? _formatMoney(entry.amount) : '-',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 30),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              strings.isSwahili
                  ? 'Asante kwa kufanya biashara nasi. Hii ni taarifa rasmi inayotolewa na mfumo wa TrackMauzo.'
                  : 'Thank you for your business. Generated by TrackMauzo POS & Accounting.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Statement_${customer.name.replaceAll(RegExp(r'\s+'), '_')}_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

enum DebtAgingCategory {
  settled,
  current,   // 0 - 7 days
  attention, // 8 - 15 days
  overdue,   // 16 - 30 days
  critical,  // > 30 days
}
