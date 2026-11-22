import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'widgets/rate_app_dialog.dart';

/// Production-grade Help & Support center with direct merchant support
/// channels, real expandable POS guides, and one-tap diagnostic reporting.
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

  String _buildDiagnosticSummary(PosLocalStore store) {
    final storeName = store.profile.storeName.trim().isNotEmpty
        ? store.profile.storeName.trim()
        : 'Aza POS Store';
    final syncMode = store.cloudApi != null ? 'Cloud + Local' : 'Local Only';
    return [
      'Aza POS Support Diagnostics',
      'App Version: $_appVersion',
      'Platform: ${_platformLabel()}',
      'Store: $storeName',
      'Sync: $syncMode',
      'Items: ${store.inventory.length} | Sales: ${store.orders.length} | Customers: ${store.customers.length}',
    ].join('\n');
  }

  Future<void> _openWhatsAppSupport(
    BuildContext context,
    PosLocalStore store,
    bool isSwahili, {
    bool includeDiagnostics = false,
  }) async {
    final storeName = store.profile.storeName.trim();
    final intro = isSwahili
        ? 'Habari timu ya msaada ya Aza POS${storeName.isNotEmpty ? ' ($storeName)' : ''}, nahitaji msaada:'
        : 'Hello Aza POS Support${storeName.isNotEmpty ? ' ($storeName)' : ''}, I need assistance:';
    final text = includeDiagnostics
        ? '$intro\n\n${_buildDiagnosticSummary(store)}'
        : intro;
    final uri = Uri.https('wa.me', '/$_supportWhatsApp', {'text': text});
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
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

  Future<void> _openEmailSupport(
    BuildContext context,
    PosLocalStore store,
    bool isSwahili,
  ) async {
    final storeName = store.profile.storeName.trim();
    final subject = storeName.isNotEmpty
        ? 'Aza POS Support — $storeName'
        : 'Aza POS Support Request';
    final body =
        '${isSwahili ? 'Eleza tatizo au swali lako hapa:' : 'Describe your issue or question here:'}\n\n\n---\n${_buildDiagnosticSummary(store)}';
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
    if (!launched && context.mounted) {
      showMarketNotice(
        context,
        title: isSwahili ? 'Hitilafu' : 'Error',
        message: isSwahili
            ? 'Imeshindwa kufungua programu ya barua pepe.'
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
            : 'Could not open phone dialer.',
        type: MarketNoticeType.error,
      );
    }
  }

  Future<void> _copyDiagnostics(
    BuildContext context,
    PosLocalStore store,
    bool isSwahili,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: _buildDiagnosticSummary(store)),
    );
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: isSwahili ? 'Imenakiliwa' : 'Copied',
      message: isSwahili
          ? 'Taarifa za uchunguzi zimenakiliwa.'
          : 'Diagnostic details copied to clipboard.',
      type: MarketNoticeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final isSwahili = store.languageCode == 'sw';
    String t(String en, String sw) => isSwahili ? sw : en;

    final guides = <_FaqItem>[
      _FaqItem(
        question: t(
          'How do I sell items by weight or measurement (kg, L, m)?',
          'Ninawezaje kuuza bidhaa kwa kipimo (kg, L, m)?',
        ),
        answer: t(
          'When adding or editing an item in the Items tab, choose its unit (e.g. kg, L, m) and enable fractional selling. On the Sales screen, tapping that item opens a quick measurement calculator where you can enter either quantity or customer budget.',
          'Unapoongeza au kuhariri bidhaa kwenye ukurasa wa Bidhaa, chagua kipimo chake (mf. kg, L, m) na uwashe uuzaji wa sehemu. Kwenye ukurasa wa Mauzo, kugusa bidhaa hiyo hufungua kikokotoo cha haraka cha kipimo au kiasi cha fedha.',
        ),
      ),
      _FaqItem(
        question: t(
          'How do I connect a Bluetooth thermal receipt printer?',
          'Ninawezaje kuunganisha printa ya risiti ya Bluetooth?',
        ),
        answer: t(
          'First pair your 58mm or 80mm thermal printer in your Android Bluetooth settings (usually PIN 0000 or 1234). Then open any completed sale or Settings → Receipts, tap Print, grant Bluetooth permission when prompted, and select your paired printer.',
          'Kwanza unganisha (pair) printa yako ya 58mm au 80mm kwenye mipangilio ya Bluetooth ya simu (PIN mara nyingi ni 0000 au 1234). Kisha fungua mauzo au Mipangilio → Risiti, gusa Chapisha, ruhusu Bluetooth, na chagua printa yako.',
        ),
      ),
      _FaqItem(
        question: t(
          'What happens if my internet goes offline while selling?',
          'Nini hutokea mtandao ukikatika wakati ninauza?',
        ),
        answer: t(
          'Aza POS works 100% offline. Every sale, stock change, and customer payment is saved immediately to your phone’s local database and automatically synced in the background as soon as internet returns.',
          'Aza POS inafanya kazi bila mtandao kwa asilimia 100. Kila mauzo, mabadiliko ya stoo, na malipo ya wateja huhifadhiwa mara moja kwenye simu na kusawazishwa kiotomatiki mtandao ukirudi.',
        ),
      ),
      _FaqItem(
        question: t(
          'How do I record credit sales and customer repayments?',
          'Ninawezaje kurekodi mauzo ya mkopo na malipo ya madeni?',
        ),
        answer: t(
          'During checkout on the Sales screen, attach the customer and choose Credit as the payment method. To record partial or full repayments later, go to More → Debtors and select the customer.',
          'Wakati wa malipo kwenye Mauzo, chagua mteja na chagua Mkopo kama njia ya malipo. Kurekodi malipo ya deni baadaye, nenda Zaidi → Wadaiwa na chagua mteja husika.',
        ),
      ),
      _FaqItem(
        question: t(
          'How do I set up the automatic Daily SMS Sales Report?',
          'Ninawezaje kuwasha Ripoti ya SMS ya Mauzo ya kila siku?',
        ),
        answer: t(
          'Go to Settings → Data → Daily SMS report, enter the owner’s phone number, choose your preferred evening delivery time (EAT), and switch on Send automatically. You can also tap Send daily report via SMS anytime.',
          'Nenda Mipangilio → Data → Ripoti ya SMS ya kila siku, weka namba ya simu ya mmiliki, chagua muda wa jioni (EAT), kisha washa Tuma kiotomatiki. Unaweza pia kutuma ripoti mara moja wakati wowote.',
        ),
      ),
      _FaqItem(
        question: t(
          'How do I manage cash register shifts and daily closing?',
          'Ninawezaje kusimamia zamu za kasha na kufunga siku?',
        ),
        answer: t(
          'Open More → Advanced tools → Cash register to start a shift with your opening float, record cash-in or cash-out movements during the day, and close the shift to see expected vs. counted cash variance.',
          'Fungua Zaidi → Vipengele vya juu → Kasha la pesa kuanza zamu na salio la kuanzia, rekodi pesa inayoingia au kutoka, na funga zamu mwisho wa siku kuona tofauti ya hesabu.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('Help & Support', 'Msaada na Huduma'),
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
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    children: [
                      // 1. Direct Contact Channels
                      _SectionLabel(t('CONTACT SUPPORT', 'WASILIANA NA MSAADA')),
                      _GroupedCard(
                        children: [
                          _ActionRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: t('WhatsApp Support', 'Msaada wa WhatsApp'),
                            trailingText: _supportPhoneDisplay,
                            onTap: () => _openWhatsAppSupport(
                              context,
                              store,
                              isSwahili,
                            ),
                          ),
                          Divider(
                            height: 1,
                            indent: 52,
                            color: AppColors.divider,
                          ),
                          _ActionRow(
                            icon: Icons.call_outlined,
                            title: t('Call Support Desk', 'Piga Simu Msaada'),
                            trailingText: _supportPhoneDial,
                            onTap: () => _callSupport(context, isSwahili),
                          ),
                          Divider(
                            height: 1,
                            indent: 52,
                            color: AppColors.divider,
                          ),
                          _ActionRow(
                            icon: Icons.email_outlined,
                            title: t('Email Support', 'Tuma Barua Pepe'),
                            trailingText: _supportEmail,
                            onTap: () => _openEmailSupport(
                              context,
                              store,
                              isSwahili,
                            ),
                          ),
                          Divider(
                            height: 1,
                            indent: 52,
                            color: AppColors.divider,
                          ),
                          _ActionRow(
                            icon: Icons.star_outline_rounded,
                            title: t(
                              'Rate & Review Aza POS',
                              'Kadiria Aza POS',
                            ),
                            onTap: () => showRateAppDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. Real Merchant Knowledge Base / Troubleshooting
                      _SectionLabel(
                        t('COMMON QUESTIONS & GUIDES', 'MASWALI NA MWONGOZO'),
                      ),
                      _GroupedCard(
                        children: [
                          for (var i = 0; i < guides.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: AppColors.divider,
                              ),
                            _FaqTile(item: guides[i]),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. Report an Issue with Real Diagnostics
                      _SectionLabel(
                        t('TROUBLESHOOTING & DIAGNOSTICS', 'UCHUNGUZI NA TATIZO'),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t(
                                'Need technical help?',
                                'Unahitaji msaada wa kiufundi?',
                              ),
                              style: AppTypography.bodyMain.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t(
                                'Send a problem report with your app version and store diagnostics so our team can resolve it faster.',
                                'Tuma ripoti ya tatizo pamoja na taarifa za programu ili timu yetu ikusaidie haraka zaidi.',
                              ),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _copyDiagnostics(
                                        context,
                                        store,
                                        isSwahili,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.ink,
                                        backgroundColor: AppColors.surface,
                                        side: BorderSide(
                                          color: AppColors.border,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.copy_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        t('Copy info', 'Nakili taarifa'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: FilledButton.icon(
                                      onPressed: () => _openWhatsAppSupport(
                                        context,
                                        store,
                                        isSwahili,
                                        includeDiagnostics: true,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.bug_report_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        t('Report issue', 'Ripoti tatizo'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quiet support hours footer
                      Text(
                        t(
                          'Support hours: Monday – Saturday, 08:00 – 20:00 EAT (UTC+3)\nAza POS v$_appVersion',
                          'Saa za msaada: Jumatatu – Jumamosi, 08:00 – 20:00 EAT (UTC+3)\nAza POS v$_appVersion',
                        ),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

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
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textMain),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});
  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.primaryDeep,
        collapsedIconColor: AppColors.textLight,
        title: Text(
          item.question,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            height: 1.3,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
