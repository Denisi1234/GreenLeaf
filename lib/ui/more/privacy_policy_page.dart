import 'package:track_mauzo/l10n/app_localization.dart';
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
                            title: context.tr('TrackMauzo Privacy Policy'),
                            description: context.tr('Last updated: May 2026'),
                            children: [
                              _Section(
                                title: context.tr('1. Information We Collect'),
                                content:
                                    'We collect information you provide directly to us when you set up your store, such as your name, email address, business details, and sales records.',
                              ),
                              _Section(
                                title: context.tr('2. How We Use Your Information'),
                                content:
                                    'We use the information we collect to provide, maintain, and improve our point-of-sale services, process transactions, and generate business reports.',
                              ),
                              _Section(
                                title: context.tr('3. Data Security'),
                                content:
                                    'We implement industry-standard security measures to protect your business and personal information from unauthorized access, disclosure, or destruction.',
                              ),
                              _Section(
                                title: context.tr('4. Information Sharing'),
                                content:
                                    'We do not sell your personal or business information to third parties. Data stays on your device unless you turn on online backup.',
                              ),
                              _Section(
                                title: context.tr('5. Your Choices'),
                                content:
                                    'You can update your store information at any time through Settings. You may also sign out or remove local data from your device.',
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
