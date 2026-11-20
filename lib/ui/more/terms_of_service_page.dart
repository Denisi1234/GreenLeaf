import 'package:track_mauzo/l10n/app_localization.dart';
import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'settings_layout.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                 MarketPageHeader(title: context.tr('Terms of Service')),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        children:  [
                          SettingsCard(
                            icon: Icons.description_outlined,
                            title: context.tr('TrackMauzo Terms of Service'),
                            description: context.tr('Last updated: May 2026'),
                            children: [
                              _Section(
                                title: context.tr('1. Acceptance of Terms'),
                                content:
                                    'By accessing and using TrackMauzo, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
                              ),
                              _Section(
                                title: context.tr('2. Description of Service'),
                                content:
                                    'TrackMauzo provides a point-of-sale (POS) software solution designed to help small businesses manage sales, inventory, customers, and reports.',
                              ),
                              _Section(
                                title: context.tr('3. User Responsibilities'),
                                content:
                                    'You are responsible for maintaining the confidentiality of your account credentials and for the accuracy of the business and tax records entered into the app.',
                              ),
                              _Section(
                                title: context.tr('4. Prohibited Conduct'),
                                content:
                                    'You agree not to use the service for any unlawful purpose or in a way that interferes with the proper functioning of the software.',
                              ),
                              _Section(
                                title: context.tr('5. Limitation of Liability'),
                                content:
                                    'TrackMauzo is provided "as is" and shall not be liable for any indirect, incidental, or consequential damages resulting from the use of our service.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMain.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
