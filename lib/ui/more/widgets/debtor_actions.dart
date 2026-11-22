import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/debit_statement_service.dart';
import '../../../service/pos_local_store.dart';
import '../../models/customer_data.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

class DebtorActions {
  static Future<void> sendReminder(
    BuildContext context, {
    required CustomerData customer,
    required PosLocalStore store,
    required AppStrings strings,
    required String Function(double) formatMoney,
  }) async {
    if (customer.phone.trim().isEmpty) {
      showMarketNotice(
        context,
        title: _dual(strings, 'No phone number', 'Hakuna namba ya simu'),
        message: _dual(
            strings,
            'Please update customer phone before sending a reminder.',
            'Tafadhali weka namba ya simu ya mteja kwanza.'),
        type: MarketNoticeType.warning,
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppCorners.control),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppCorners.control,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dual(strings, 'Send Payment Reminder',
                        'Tuma Kikumbusho cha Deni'),
                    style: AppTypography.cardHeader,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customer.name} · ${formatMoney(customer.debitBalance)}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.chat_bubble_rounded,
                  color: Color(0xFF25D366), size: 22),
              title: Text(
                  _dual(strings, 'Send via WhatsApp', 'Tuma kupitia WhatsApp')),
              subtitle: Text(
                _dual(strings, 'Opens WhatsApp with customized message',
                    'Hufungua WhatsApp na ujumbe wa deni'),
                style: AppTypography.helperText
                    .copyWith(color: AppColors.textLight),
              ),
              onTap: () => Navigator.of(ctx).pop('whatsapp'),
            ),
            ListTile(
              leading: Icon(Icons.message_rounded,
                  color: AppColors.primary, size: 22),
              title: Text(_dual(strings, 'Send via SMS', 'Tuma kupitia SMS')),
              subtitle: Text(
                _dual(strings, 'Opens standard SMS messaging app',
                    'Hufungua app ya ujumbe wa simu'),
                style: AppTypography.helperText
                    .copyWith(color: AppColors.textLight),
              ),
              onTap: () => Navigator.of(ctx).pop('sms'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.dangerDeep, size: 22),
              title: Text(_dual(
                  strings, 'Share Statement PDF', 'Shiriki Taarifa (PDF)')),
              subtitle: Text(
                _dual(strings, 'Generate official PDF account statement',
                    'Tengeneza ripoti rasmi ya deni'),
                style: AppTypography.helperText
                    .copyWith(color: AppColors.textLight),
              ),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    if (action == 'whatsapp') {
      final ok = await DebitStatementService.sendWhatsAppReminder(
        customer: customer,
        store: store,
        isSwahili: strings.isSwahili,
      );
      if (!ok && context.mounted) {
        showMarketNotice(
          context,
          title: _dual(
              strings, 'Cannot open WhatsApp', 'Imeshindwa kufungua WhatsApp'),
          message: _dual(
              strings,
              'WhatsApp is not installed or available on this device.',
              'WhatsApp haipatikani kwenye simu au kifaa hiki.'),
          type: MarketNoticeType.warning,
        );
      }
    } else if (action == 'sms') {
      final ok = await DebitStatementService.sendSmsReminder(
        customer: customer,
        store: store,
        isSwahili: strings.isSwahili,
      );
      if (!ok && context.mounted) {
        showMarketNotice(
          context,
          title: _dual(strings, 'Cannot open SMS', 'Imeshindwa kufungua SMS'),
          message: _dual(strings, 'SMS application could not be opened.',
              'App ya ujumbe haikuweza kufunguka.'),
          type: MarketNoticeType.warning,
        );
      }
    } else if (action == 'pdf') {
      await DebitStatementService.generateAndSharePdf(
        customer: customer,
        store: store,
        strings: strings,
      );
    }
  }

  static Future<void> confirmClearAllDebits(
    BuildContext context, {
    required PosLocalStore store,
    required AppStrings strings,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppCorners.control),
        title: Text(
          _dual(strings, 'Clear All Debts?', 'Futa Madeni Yote?'),
          style: AppTypography.cardHeader,
        ),
        content: Text(
          _dual(
            strings,
            'Are you sure you want to clear all old debtor records and reset balances on this device? This cannot be undone.',
            'Je, una uhakika unataka kufuta kumbukumbu zote za madeni ya zamani na kuweka salio kuwa sifuri kwenye kifaa hiki? Hatua hii haiwezi kurudishwa.',
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_dual(strings, 'Cancel', 'Ghairi')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerDeep,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: AppCorners.control),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_dual(strings, 'Clear All', 'Futa Yote')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await store.clearAllDebits();
      if (context.mounted) {
        showMarketNotice(
          context,
          title: _dual(strings, 'Debts cleared', 'Madeni yamefutwa'),
          message: _dual(
            strings,
            'All debtor balances and old credit history on this device have been cleared.',
            'Kumbukumbu zote za madeni ya zamani kwenye kifaa hiki zimefutwa.',
          ),
          type: MarketNoticeType.success,
        );
      }
    }
  }
}
