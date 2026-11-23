import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';

/// Clean, native Android/iOS Terms of Service screen supporting all app themes.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: context.tr('Terms of Service'),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Aza POS Terms of Service'),
                              style: AppTypography.h3.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Azmur Group Limited · Last updated: November 2026',
                              style: AppTypography.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(height: 1, color: palette.divider),
                            const SizedBox(height: 18),
                            _Section(
                              palette: palette,
                              title: context.tr('1. Acceptance of Terms'),
                              content:
                                  'By accessing and using Aza POS, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
                            ),
                            _Section(
                              palette: palette,
                              title: context.tr('2. Description of Service'),
                              content:
                                  'Aza POS provides a point-of-sale (POS) software solution operated by Azmur Group Limited to help retail shops manage sales, inventory, customers, and reports.',
                            ),
                            _Section(
                              palette: palette,
                              title: context.tr('3. User Responsibilities'),
                              content:
                                  'You are responsible for maintaining the confidentiality of your account credentials and for the accuracy of the business and tax records entered into the app.',
                            ),
                            _Section(
                              palette: palette,
                              title: context.tr('4. Prohibited Conduct'),
                              content:
                                  'You agree not to use the service for any unlawful purpose or in a way that interferes with the proper functioning of the software.',
                            ),
                            _Section(
                              palette: palette,
                              title: context.tr('5. Limitation of Liability'),
                              content:
                                  'Aza POS is provided "as is" and Azmur Group Limited shall not be liable for any indirect, incidental, or consequential damages resulting from the use of our service.',
                              isLast: true,
                            ),
                          ],
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

class _Section extends StatelessWidget {
  const _Section({
    required this.palette,
    required this.title,
    required this.content,
    this.isLast = false,
  });

  final AppThemePalette palette;
  final String title;
  final String content;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMain.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: palette.textBody,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
