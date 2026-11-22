import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

/// Modal dialog shown after creating or updating staff credentials
/// that lets the owner immediately send the login credentials to the staff member via SMS / WhatsApp / Share.
class StaffCredentialsShareDialog extends StatelessWidget {
  const StaffCredentialsShareDialog({
    super.key,
    required this.staffName,
    required this.username,
    required this.password,
    required this.phone,
    required this.roleTitle,
    required this.storeName,
    required this.isSwahili,
  });

  final String staffName;
  final String username;
  final String password;
  final String phone;
  final String roleTitle;
  final String storeName;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  String _formatMessage() {
    if (isSwahili) {
      return '''Hujambo $staffName,
Akaunti yako ya mfanyakazi katika $storeName ($roleTitle) imeundwa.
Tumia taarifa zifuatazo kuingia kwenye mfumo wa POS:

👤 Jina la mtumiaji: $username
🔑 Nenosiri: $password

Tafadhali weka nenosiri hili kwa usalama.''';
    } else {
      return '''Hello $staffName,
Your staff account at $storeName ($roleTitle) has been created.
Use the following credentials to sign in to the POS:

👤 Username: $username
🔑 Password: $password

Please keep your login credentials secure.''';
    }
  }

  Future<void> _sendViaSms(BuildContext context) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final message = _formatMessage();
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to share
        await SharePlus.instance.share(
          ShareParams(
            text: message,
            subject:
                isSwahili ? 'Taarifa za Kuingia POS' : 'POS Login Credentials',
          ),
        );
      }
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject:
              isSwahili ? 'Taarifa za Kuingia POS' : 'POS Login Credentials',
        ),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final message = _formatMessage();
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: isSwahili ? 'Taarifa za Kuingia POS' : 'POS Login Credentials',
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _formatMessage()));
    showMarketNotice(
      context,
      title: _t('Credentials copied', 'Taarifa zimenakiliwa'),
      message: _t(
        'Staff login details copied to clipboard.',
        'Taarifa za kuingia za mfanyakazi zimenakiliwa.',
      ),
      type: MarketNoticeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppCorners.control,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              color: AppColors.kpiSuccessBg,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.kpiSuccess,
                      borderRadius: AppCorners.control,
                    ),
                    child: const Icon(Icons.sms_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Staff credentials created',
                              'Taarifa za mfanyakazi zimeundwa'),
                          style: AppTypography.h3.copyWith(
                            color: AppColors.kpiSuccess,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _t(
                            'Send login details via SMS or WhatsApp',
                            'Mtumie taarifa za kuingia kupitia SMS au WhatsApp',
                          ),
                          style: AppTypography.helperText.copyWith(
                            color: AppColors.kpiSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.kpiSuccess),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Credentials Summary', 'Muhtasari wa Taarifa'),
                    style: AppTypography.label.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppCorners.control,
                    ),
                    child: Column(
                      children: [
                        _buildCredentialRow(
                            _t('Staff name', 'Jina'), staffName),
                        Divider(height: 16, color: AppColors.divider),
                        _buildCredentialRow(_t('Role', 'Nafasi'), roleTitle),
                        Divider(height: 16, color: AppColors.divider),
                        _buildCredentialRow(
                            _t('Username', 'Jina la kuingia'), username,
                            isBold: true),
                        if (password.isNotEmpty) ...[
                          Divider(height: 16, color: AppColors.divider),
                          _buildCredentialRow(
                              _t('Password', 'Nenosiri'), password,
                              isBold: true, isHighlight: true),
                        ],
                        if (phone.isNotEmpty) ...[
                          Divider(height: 16, color: AppColors.divider),
                          _buildCredentialRow(
                              _t('Phone (SMS target)', 'Simu ya kutuma SMS'),
                              phone),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: MarketButton(
                          label: _t('Send SMS', 'Tuma SMS'),
                          icon: Icons.send_rounded,
                          radius: AppRadius.input,
                          onTap: () => _sendViaSms(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MarketButton(
                          label: _t('Share details', 'Sambaza'),
                          icon: Icons.share_rounded,
                          color: AppColors.kpiSkyBg,
                          foregroundColor: AppColors.kpiSky,
                          borderColor: null,
                          radius: AppRadius.input,
                          onTap: () => _share(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kpiVioletBg,
                        foregroundColor: AppColors.kpiViolet,
                        side: BorderSide.none,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppCorners.control),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _copy(context),
                      icon: Icon(Icons.copy_rounded,
                          size: 16, color: AppColors.kpiViolet),
                      label: Text(
                        _t('Copy message to clipboard', 'Nakili ujumbe'),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.kpiViolet,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value,
      {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primaryDeep : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
