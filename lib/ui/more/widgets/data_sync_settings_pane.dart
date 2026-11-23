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
import '../../widgets/app_theme_palette.dart';
import '../settings_layout.dart';

/// Clean, native Android/iOS Data settings pane (Daily SMS report & backups).
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
                  'date': e.date.toIso8601String(),
                })
            .toList(),
        'staff': store.staffMembers
            .map((s) => {'id': s.id, 'name': s.name, 'phone': s.phone})
            .toList(),
      };

      final encoder = JsonEncoder.withIndent(
        '  ',
        (obj) => obj is DateTime ? obj.toIso8601String() : obj.toString(),
      );
      final bytes = Uint8List.fromList(utf8.encode(encoder.convert(payload)));
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
    final palette = AppThemePalette.of(context);
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);

    if (!_phoneInitialized) {
      _phoneController.text =
          DailySalesReportService.resolveRecipientPhone(store);
      _phoneInitialized = true;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      children: [
        _SectionLabel(t('DAILY SMS REPORT', 'RIPOTI YA SMS YA KILA SIKU'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            SwitchListTile.adaptive(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                t('Send automatically', 'Tuma kiotomatiki'),
                style: AppTypography.bodyMain.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
              ),
              subtitle: Text(
                t('Every evening (EAT)', 'Kila jioni (EAT)'),
                style: AppTypography.caption.copyWith(color: palette.textMuted),
              ),
              value: store.storePreferences.autoDailySmsReport,
              activeTrackColor: palette.primary,
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
            Divider(height: 1, indent: 16, color: palette.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('Owner phone number', 'Namba ya simu ya mmiliki'),
                    style: AppTypography.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: palette.ink, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '0712345678',
                      hintStyle: TextStyle(color: palette.textMuted),
                      filled: true,
                      fillColor: palette.pageBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: palette.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t('Delivery time', 'Muda wa kutuma'),
                    style: AppTypography.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'sms-${store.storePreferences.dailySmsTime}-$lang',
                    ),
                    initialValue: store.storePreferences.dailySmsTime,
                    dropdownColor: palette.surface,
                    style: TextStyle(color: palette.ink, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.pageBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: palette.border),
                      ),
                    ),
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
                              store.storePreferences
                                  .copyWith(dailySmsTime: value),
                            );
                          },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _sendDailySms(store),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
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
            ),
          ],
        ),

        const SizedBox(height: 22),

        _SectionLabel(t('BACKUP & MAINTENANCE', 'NAKALA NA MATENGENEZO'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            _NativeActionRow(
              palette: palette,
              icon: Icons.ios_share_rounded,
              title: t('Export backup', 'Hamisha nakala'),
              busy: _busy,
              onTap: _busy ? null : () => _exportBackup(store),
            ),
            Divider(height: 1, indent: 52, color: palette.divider),
            _NativeActionRow(
              palette: palette,
              icon: Icons.refresh_rounded,
              title: t('Reload local data', 'Pakia data upya'),
              busy: _busy,
              onTap: _busy
                  ? null
                  : () => _run(
                        store.reloadFromLocal,
                        t(
                          'Local data refreshed',
                          'Data ya ndani imesasishwa',
                        ),
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _NativeGroupCard extends StatelessWidget {
  const _NativeGroupCard({required this.palette, required this.children});
  final AppThemePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}

class _NativeActionRow extends StatelessWidget {
  const _NativeActionRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
    this.busy = false,
  });

  final AppThemePalette palette;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 22, color: palette.textMuted),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: palette.ink,
                  ),
                ),
              ),
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.primary,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
