import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../service/daily_sales_report_service.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../settings_layout.dart';

/// Daily SMS reports, backups, and maintenance pane.
/// Cloud sync runs silently and automatically in the background.
class DataSyncSettingsPane extends StatefulWidget {
  const DataSyncSettingsPane({super.key});

  @override
  State<DataSyncSettingsPane> createState() => _DataSyncSettingsPaneState();
}

class _DataSyncSettingsPaneState extends State<DataSyncSettingsPane> {
  bool _busy = false;
  final TextEditingController _phoneController = TextEditingController();
  bool _phoneInitialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendDailySms(PosLocalStore store) async {
    final overridePhone = _phoneController.text.trim();
    setState(() => _busy = true);
    final DailySmsResult result;
    try {
      result = await store.sendDailySmsNow(
        overridePhone: overridePhone.isNotEmpty ? overridePhone : null,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSettingsResult(context, error.toString(), error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    // If not delivered by the backend SMS gateway, open the native SMS app
    // pre-filled with the recipient and today's sales summary.
    if (!result.deliveredByServer &&
        result.targetPhone != null &&
        result.smsText != null) {
      final smsUri = Uri(
        scheme: 'sms',
        path: result.targetPhone!,
        queryParameters: <String, String>{'body': result.smsText!},
      );
      var launched = false;
      try {
        launched = await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }
      if (!launched) {
        await SharePlus.instance.share(
          ShareParams(
            text: result.smsText!,
            subject: 'Ripoti ya Mauzo ya Leo',
          ),
        );
      }
    }

    if (!mounted) return;
    showSettingsResult(context, result.message, error: !result.success);
  }

  Future<void> _run(
    Future<void> Function() action,
    String okMessage,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showSettingsResult(context, okMessage);
    } catch (error) {
      if (mounted) showSettingsResult(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup(PosLocalStore store) async {
    final lang = store.languageCode;
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'app': 'Aza POS',
        'exported_at': DateTime.now().toIso8601String(),
        'profile': {
          'store_name': store.profile.storeName,
          'owner_name': store.profile.ownerName,
          'role_title': store.profile.roleTitle,
          'phone': store.profile.contactNumber,
          'email': store.profile.emailAddress,
          'address': store.profile.physicalAddress,
          'tax_id': store.profile.taxId,
        },
        'receipt_settings': {
          'header': store.receiptSettings.header,
          'footer': store.receiptSettings.footer,
        },
        'customers': store.customers
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'phone': c.phone,
                  'email': c.email,
                  'address': c.address,
                  'debit_balance': c.debitBalance,
                  'created_at': c.createdAt.toIso8601String(),
                })
            .toList(),
        'debit_ledger': store.debitEntries
            .map((e) => {
                  'id': e.id,
                  'customer': e.customerName,
                  'type': e.type.value,
                  'amount': e.amount,
                  'note': e.note,
                  'created_at': e.createdAt.toIso8601String(),
                })
            .toList(),
        'sales': store.orders
            .map((o) => {
                  'id': o.id,
                  'date_time': o.dateTime,
                  'total': o.total,
                  'payment_method': o.paymentMethod,
                  'customer': o.customerName,
                })
            .toList(),
        'inventory': store.inventory
            .map((i) => {
                  'code': i.code,
                  'name': i.name,
                  'stock': i.stockCount,
                  'price': i.sellingPrice,
                })
            .toList(),
        'expenses': store.expenses
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'amount': e.amount,
                  'category': e.category,
                  'date': e.date,
                })
            .toList(),
        'staff': store.staffMembers
            .map((s) => {'id': s.id, 'name': s.name, 'phone': s.phone})
            .toList(),
      };

      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      );
      final directory = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${directory.path}/azapos_backup_$stamp.json');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/json')]),
      );
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(lang, 'Backup exported', 'Nakala imehamishwa'),
      );
    } catch (error) {
      if (!mounted) return;
      showSettingsResult(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);

    if (!_phoneInitialized) {
      _phoneController.text =
          DailySalesReportService.resolveRecipientPhone(store);
      _phoneInitialized = true;
    }

    final previewMessage =
        DailySalesReportService.buildDailyReportMessage(store: store);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.sms_outlined,
          title: t('Daily SMS report', 'Ripoti ya SMS ya kila siku'),
          description: t(
            'Send an end-of-day sales summary to the owner by SMS.',
            'Tuma muhtasari wa mauzo wa jioni kwa mmiliki kwa SMS.',
          ),
          trailing: SettingsStatusPill(
            label: store.storePreferences.autoDailySmsReport
                ? t('On', 'Imewashwa')
                : t('Off', 'Imezimwa'),
            positive: store.storePreferences.autoDailySmsReport,
          ),
          children: [
            SettingsSwitchTile(
              title: t('Send automatically', 'Tuma kiotomatiki'),
              subtitle: t(
                'Runs every evening in East Africa Time (UTC+3).',
                'Hufanya kazi kila jioni kwa saa za Afrika Mashariki (UTC+3).',
              ),
              value: store.storePreferences.autoDailySmsReport,
              onChanged: _busy
                  ? null
                  : (value) async {
                      setState(() => _busy = true);
                      try {
                        await store.setStorePreferences(
                          store.storePreferences.copyWith(
                            autoDailySmsReport: value,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SettingsField(
              label: t('Owner phone number', 'Namba ya simu ya mmiliki'),
              hint: t(
                'e.g. 0712345678 or +255712345678',
                'mf. 0712345678 au +255712345678',
              ),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0712345678',
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsField(
              label: t('Delivery time', 'Muda wa kutuma'),
              hint: t('24-hour clock, e.g. 21:00', 'Saa 24, mf. 21:00'),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'sms-${store.storePreferences.dailySmsTime}-$lang',
                ),
                initialValue: store.storePreferences.dailySmsTime,
                items: [
                  for (final time in const [
                    '18:00',
                    '19:00',
                    '20:00',
                    '21:00',
                    '22:00',
                  ])
                    DropdownMenuItem(value: time, child: Text(time)),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        store.setStorePreferences(
                          store.storePreferences.copyWith(dailySmsTime: value),
                        );
                      },
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(AppRadius.sharp),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Live SMS preview', 'Mfano wa SMS ya leo'),
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    previewMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _sendDailySms(store),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  t('Send daily report via SMS', 'Tuma ripoti kwa SMS'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.backup_outlined,
          title: t('Backup & export', 'Hifadhi nakala na hamisha'),
          description: t(
            'Save a backup copy of your shop data to this device.',
            'Pakua nakala ya akiba ya data ya duka lako.',
          ),
          children: [
            SettingsInfoRow(
              label: t('Includes', 'Inajumuisha'),
              value: t(
                'Profile, sales, stock, customers, credit ledger, expenses, staff',
                'Wasifu, mauzo, hisa, wateja, madeni, matumizi, wafanyakazi',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _exportBackup(store),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  t('Export backup', 'Hamisha nakala'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.build_circle_outlined,
          title: t('Maintenance', 'Matengenezo'),
          description: t(
            'Refresh local records without changing your saved data.',
            'Sasisha kumbukumbu za ndani bila kubadilisha data yako.',
          ),
          children: [
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          store.reloadFromLocal,
                          t(
                            'Local data refreshed',
                            'Data ya ndani imesasishwa',
                          ),
                        ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  t('Reload local data', 'Pakia data upya'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
