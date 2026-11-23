import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'widgets/rate_app_dialog.dart';

/// Clean, native Android/iOS Help & Support screen supporting all app themes.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _supportPhoneDisplay = '+255 624 105 850';
  static const _supportPhoneDial = '0624105850';
  static const _supportWhatsApp = '255624105850';
  static const _supportEmail = 'help@azmur.co.tz';
  static const _appVersion = '1.0.0 (1)';

  String _platformLabel() {
    try {
      final os = Platform.operatingSystem;
      final ver = Platform.operatingSystemVersion.split(' ').first;
      return '${os[0].toUpperCase()}${os.substring(1)} $ver';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _diagnosticSummary(PosLocalStore store) {
    final storeName = store.profile.storeName.trim().isNotEmpty
        ? store.profile.storeName.trim()
        : 'Aza POS Store';
    return [
      'Aza POS v$_appVersion (${_platformLabel()})',
      'Store: $storeName',
      'Items: ${store.inventory.length} | Sales: ${store.orders.length}',
    ].join('\n');
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    PosLocalStore store,
    bool isSwahili, {
    bool reportIssue = false,
  }) async {
    final storeName = store.profile.storeName.trim();
    final intro = reportIssue
        ? (isSwahili
            ? 'Habari Aza POS, naripoti tatizo:'
            : 'Hello Aza POS Support, I would like to report an issue:')
        : (isSwahili
            ? 'Habari timu ya msaada ya Aza POS${storeName.isNotEmpty ? ' ($storeName)' : ''}, nahitaji msaada:'
            : 'Hello Aza POS Support${storeName.isNotEmpty ? ' ($storeName)' : ''}, I need help:');
    final text =
        reportIssue ? '$intro\n\n${_diagnosticSummary(store)}' : intro;
    final uri = Uri.https('wa.me', '/$_supportWhatsApp', {'text': text});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showMarketNotice(
        context,
        title: isSwahili ? 'Hitilafu' : 'Error',
        message: isSwahili
            ? 'Imeshindwa kufungua WhatsApp.'
            : 'Could not open WhatsApp.',
        type: MarketNoticeType.error,
      );
    }
  }

  Future<void> _openEmail(
    BuildContext context,
    PosLocalStore store,
    bool isSwahili,
  ) async {
    final storeName = store.profile.storeName.trim();
    final subject = storeName.isNotEmpty
        ? 'Aza POS Support — $storeName'
        : 'Aza POS Support';
    final body = '\n\n---\n${_diagnosticSummary(store)}';
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showMarketNotice(
        context,
        title: isSwahili ? 'Hitilafu' : 'Error',
        message: isSwahili
            ? 'Imeshindwa kufungua barua pepe.'
            : 'Could not open email app.',
        type: MarketNoticeType.error,
      );
    }
  }

  Future<void> _callSupport(BuildContext context, bool isSwahili) async {
    final launched = await launchUrl(
      Uri.parse('tel:$_supportPhoneDial'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      showMarketNotice(
        context,
        title: isSwahili ? 'Hitilafu' : 'Error',
        message: isSwahili
            ? 'Imeshindwa kufungua kipiga simu.'
            : 'Could not open dialer.',
        type: MarketNoticeType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final isSwahili = store.languageCode == 'sw';
    String t(String en, String sw) => isSwahili ? sw : en;

    final topics = <_HelpTopic>[
      _HelpTopic(
        question: t(
          'Selling by weight or measurement (kg, L, m)',
          'Kuuza kwa kipimo (kg, L, m)',
        ),
        answer: t(
          'When adding or editing an item, choose its unit (kg, L, m) and enable fractional selling. Tapping the item on the Sales screen opens a quick calculator for quantity or price.',
          'Unapoongeza au kuhariri bidhaa, chagua kipimo chake (kg, L, m) na uwashe uuzaji wa sehemu. Kugusa bidhaa hiyo kwenye Mauzo hufungua kikokotoo cha kipimo au bei.',
        ),
      ),
      _HelpTopic(
        question: t(
          'Connecting a Bluetooth thermal printer',
          'Kuunganisha printa ya Bluetooth',
        ),
        answer: t(
          'Pair your 58mm or 80mm thermal printer in Android Bluetooth settings first (PIN is usually 0000 or 1234). Then tap Print on any receipt and pick your paired printer.',
          'Unganisha (pair) printa yako ya 58mm au 80mm kwenye Bluetooth ya simu kwanza (PIN mara nyingi ni 0000 au 1234). Kisha gusa Chapisha kwenye risiti na chagua printa yako.',
        ),
      ),
      _HelpTopic(
        question: t(
          'Offline sales & automatic backup',
          'Mauzo bila mtandao na hifadhi ya kiotomatiki',
        ),
        answer: t(
          'Aza POS works fully offline. Every sale and stock update saves locally right away and syncs automatically in the background once internet returns.',
          'Aza POS inafanya kazi bila mtandao. Kila mauzo na mabadiliko ya stoo huhifadhiwa kwenye simu mara moja na kusawazishwa kiotomatiki mtandao ukirudi.',
        ),
      ),
      _HelpTopic(
        question: t(
          'Credit sales & customer repayments',
          'Mauzo ya mkopo na malipo ya madeni',
        ),
        answer: t(
          'Attach a customer during checkout and choose Credit as the payment method. Record repayments anytime under More → Debtors.',
          'Chagua mteja wakati wa malipo na chagua Mkopo. Rekodi malipo ya madeni wakati wowote chini ya Zaidi → Wadaiwa.',
        ),
      ),
      _HelpTopic(
        question: t(
          'Daily SMS sales summary',
          'Ripoti ya SMS ya mauzo ya kila siku',
        ),
        answer: t(
          'Open Settings → Data → Daily SMS report to set the owner phone number, choose an evening time, and enable automatic sending.',
          'Fungua Mipangilio → Data → Ripoti ya SMS ya kila siku kuweka namba ya mmiliki, muda wa jioni, na kuwasha utumaji wa kiotomatiki.',
        ),
      ),
      _HelpTopic(
        question: t(
          'Cash register shifts & closing',
          'Zamu za kasha na kufunga siku',
        ),
        answer: t(
          'Go to More → Advanced tools → Cash register to open a shift with your starting cash, log cash movements, and review variance at closing.',
          'Nenda Zaidi → Vipengele vya juu → Kasha la pesa kufungua zamu, kurekodi miamala ya pesa, na kuona tofauti wakati wa kufunga.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('Help & Support', 'Msaada'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 20,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    children: [
                      _GroupHeader(t('SUPPORT', 'MSAADA'), palette),
                      _NativeCard(
                        palette: palette,
                        children: [
                          _NativeRow(
                            palette: palette,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'WhatsApp',
                            detail: _supportPhoneDisplay,
                            onTap: () =>
                                _openWhatsApp(context, store, isSwahili),
                          ),
                          _IndentedDivider(palette),
                          _NativeRow(
                            palette: palette,
                            icon: Icons.call_outlined,
                            title: t('Call', 'Piga simu'),
                            detail: _supportPhoneDial,
                            onTap: () => _callSupport(context, isSwahili),
                          ),
                          _IndentedDivider(palette),
                          _NativeRow(
                            palette: palette,
                            icon: Icons.email_outlined,
                            title: t('Email', 'Barua pepe'),
                            detail: _supportEmail,
                            onTap: () => _openEmail(context, store, isSwahili),
                          ),
                          _IndentedDivider(palette),
                          _NativeRow(
                            palette: palette,
                            icon: Icons.bug_report_outlined,
                            title: t('Report a problem', 'Ripoti tatizo'),
                            onTap: () => _openWhatsApp(
                              context,
                              store,
                              isSwahili,
                              reportIssue: true,
                            ),
                          ),
                          _IndentedDivider(palette),
                          _NativeRow(
                            palette: palette,
                            icon: Icons.star_outline_rounded,
                            title: t('Rate & review', 'Kadiria programu'),
                            onTap: () => showRateAppDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _GroupHeader(t('HELP TOPICS', 'MWONGOZO'), palette),
                      _NativeCard(
                        palette: palette,
                        children: [
                          for (var i = 0; i < topics.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: palette.divider),
                            _TopicTile(topic: topics[i], palette: palette),
                          ],
                        ],
                      ),

                      const SizedBox(height: 22),

                      Text(
                        t(
                          'Mon – Sat · 08:00 – 20:00 EAT\nAza POS v$_appVersion',
                          'Jumatatu – Jumamosi · 08:00 – 20:00 EAT\nAza POS v$_appVersion',
                        ),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: palette.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label, this.palette);
  final String label;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        label,
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

class _NativeCard extends StatelessWidget {
  const _NativeCard({required this.palette, required this.children});
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

class _IndentedDivider extends StatelessWidget {
  const _IndentedDivider(this.palette);
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 52, color: palette.divider);
  }
}

class _NativeRow extends StatelessWidget {
  const _NativeRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
  });

  final AppThemePalette palette;
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback onTap;

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
              if (detail != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
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

class _HelpTopic {
  const _HelpTopic({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.palette});
  final _HelpTopic topic;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        iconColor: palette.primary,
        collapsedIconColor: palette.textMuted,
        title: Text(
          topic.question,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: palette.ink,
            height: 1.3,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              topic.answer,
              style: AppTypography.bodySmall.copyWith(
                color: palette.textBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
