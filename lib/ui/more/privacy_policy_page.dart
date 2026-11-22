import 'package:aza_pos/l10n/app_localization.dart';
import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'settings_layout.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                 MarketPageHeader(title: context.tr('Privacy Policy')),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        children:  [
                          SettingsCard(
                            icon: Icons.privacy_tip_outlined,
                            title: context.tr('Aza POS Privacy Notice'),
                            description: context.tr(
                              'Azmur Group Limited • Last updated: November 2026',
                            ),
                            children: [
                              _Section(
                                title: context.tr('1. Information We Collect'),
                                content:
                                    'Azmur Group Limited collects only the information you provide to operate Aza POS, including your name, phone number, business profile, staff roles, inventory, sales transactions, optional customer records, and optional product or receipt photos.',
                              ),
                              _Section(
                                title: context.tr('2. How We Use Your Information'),
                                content:
                                    'We use your information strictly to provide offline-first point-of-sale checkout, inventory and accounting management, SMS verification codes, optional daily sales summaries, and cloud backup across your authorized store devices.',
                              ),
                              _Section(
                                title: context.tr('3. Data Storage & Security'),
                                content:
                                    'Store records are saved locally in private device storage. When cloud backup is enabled, data is protected with HTTPS encryption in transit, secure password encryption, and staff access permissions.',
                              ),
                              _Section(
                                title: context.tr('4. Information Sharing'),
                                content:
                                    'Azmur Group Limited never sells your personal or business data and uses no third-party advertising tools. Data is shared only with authorized infrastructure and SMS delivery providers strictly to operate the service.',
                              ),
                              _Section(
                                title: context.tr('5. Your Rights & Account Deletion'),
                                content:
                                    'You can update store details, export CSV/PDF reports, or clear local data from your device at any time. To request permanent cloud account deletion or ask privacy questions, contact Azmur Group Limited at info@azmur.co.tz.',
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
