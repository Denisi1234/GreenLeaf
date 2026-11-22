import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

/// Opens an interactive star-rating and feedback dialog that lets users rate
/// Aza POS on Google Play or send written feedback directly via WhatsApp/Email.
Future<void> showRateAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _RateAppDialog(),
  );
}

class _RateAppDialog extends StatefulWidget {
  const _RateAppDialog();

  @override
  State<_RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<_RateAppDialog> {
  static const _packageId = 'com.azapos.app';
  static const _supportWhatsApp = '255624105850';
  static const _supportEmail = 'help@azmur.co.tz';

  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _ratingLabel(bool isSwahili) {
    switch (_rating) {
      case 1:
        return isSwahili ? 'Hafifu sana' : 'Poor';
      case 2:
        return isSwahili ? 'Wastani' : 'Fair';
      case 3:
        return isSwahili ? 'Nzuri' : 'Good';
      case 4:
        return isSwahili ? 'Nzuri sana' : 'Very good';
      default:
        return isSwahili ? 'Bora kabisa!' : 'Excellent!';
    }
  }

  String _composeFeedbackText(String storeName, bool isSwahili) {
    final stars = '★' * _rating + '☆' * (5 - _rating);
    final comment = _commentController.text.trim();
    final buffer = StringBuffer()
      ..writeln('Aza POS Review (v1.0.0)')
      ..writeln('Rating: $_rating/5 ($stars)');
    if (storeName.trim().isNotEmpty) {
      buffer.writeln('Store: ${storeName.trim()}');
    }
    if (comment.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(isSwahili ? 'Maoni:' : 'Comment:')
        ..writeln(comment);
    }
    return buffer.toString().trim();
  }

  Future<void> _openPlayStore(bool isSwahili) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final marketUri = Uri.parse('market://details?id=$_packageId');
      final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$_packageId',
      );
      var launched = false;
      if (await canLaunchUrl(marketUri)) {
        launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched) {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showMarketNotice(
        context,
        title: launched
            ? (isSwahili ? 'Asante!' : 'Thank you!')
            : (isSwahili ? 'Hitilafu' : 'Error'),
        message: launched
            ? (isSwahili
                ? 'Asante kwa kukadiria Aza POS!'
                : 'Thank you for rating Aza POS!')
            : (isSwahili
                ? 'Imeshindwa kufungua Google Play.'
                : 'Could not open Google Play.'),
        type: launched ? MarketNoticeType.success : MarketNoticeType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendViaWhatsApp(String storeName, bool isSwahili) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final message = _composeFeedbackText(storeName, isSwahili);
      final uri = Uri.https('wa.me', '/$_supportWhatsApp', {'text': message});
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showMarketNotice(
        context,
        title: launched
            ? (isSwahili ? 'Asante!' : 'Thank you!')
            : (isSwahili ? 'Hitilafu' : 'Error'),
        message: launched
            ? (isSwahili
                ? 'Asante kwa maoni yako!'
                : 'Thank you for your feedback!')
            : (isSwahili
                ? 'Imeshindwa kufungua WhatsApp.'
                : 'Could not open WhatsApp.'),
        type: launched ? MarketNoticeType.success : MarketNoticeType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendViaEmail(String storeName, bool isSwahili) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final subject = 'Aza POS Review - $_rating/5 Stars';
      final body = _composeFeedbackText(storeName, isSwahili);
      final uri = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        query:
            'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showMarketNotice(
        context,
        title: launched
            ? (isSwahili ? 'Asante!' : 'Thank you!')
            : (isSwahili ? 'Hitilafu' : 'Error'),
        message: launched
            ? (isSwahili
                ? 'Asante kwa maoni yako!'
                : 'Thank you for your feedback!')
            : (isSwahili
                ? 'Imeshindwa kufungua programu ya barua pepe.'
                : 'Could not open email app.'),
        type: launched ? MarketNoticeType.success : MarketNoticeType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<PosLocalStore>();
    final isSwahili = store.languageCode == 'sw';
    final storeName = store.profile.storeName;
    final highRating = _rating >= 4;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isSwahili ? 'Kadiria Aza POS' : 'Rate Aza POS',
                      style: AppTypography.sectionHeader.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isSwahili
                    ? 'Tuambie uzoefu wako ili tuendelee kuboresha Aza POS.'
                    : 'Share your experience so we can keep improving Aza POS.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              // Interactive 5-star bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  final selected = star <= _rating;
                  return IconButton(
                    key: ValueKey('rate-star-$star'),
                    onPressed: () => setState(() => _rating = star),
                    iconSize: 32,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    icon: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          selected ? AppColors.kpiAmber : AppColors.textLight,
                    ),
                  );
                }),
              ),
              Text(
                _ratingLabel(isSwahili),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: isSwahili
                      ? 'Andika maoni au pendekezo lako (hiari)...'
                      : 'Write your comment or suggestion (optional)...',
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  contentPadding: const EdgeInsets.all(12),
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
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (highRating) ...[
                FilledButton.icon(
                  onPressed:
                      _submitting ? null : () => _openPlayStore(isSwahili),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  icon: const Icon(Icons.shop_rounded, size: 18),
                  label: Text(
                    isSwahili
                        ? 'Kadiria kwenye Google Play'
                        : 'Rate on Google Play',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _sendViaWhatsApp(storeName, isSwahili),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _sendViaEmail(storeName, isSwahili),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: Text(isSwahili ? 'Barua pepe' : 'Email'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _sendViaWhatsApp(storeName, isSwahili),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isSwahili
                        ? 'Tuma maoni kupitia WhatsApp'
                        : 'Send feedback via WhatsApp',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _sendViaEmail(storeName, isSwahili),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: Text(isSwahili ? 'Barua pepe' : 'Email'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _openPlayStore(isSwahili),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.shop_rounded, size: 16),
                        label: const Text('Play Store'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
