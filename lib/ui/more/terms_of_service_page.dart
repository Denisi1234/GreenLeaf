import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const MarketPageHeader(
              title: 'Terms of Service',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                children: const [
                  _Section(
                    title: '1. Acceptance of Terms',
                    content:
                        'By accessing and using the app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
                  ),
                  _Section(
                    title: '2. Description of Service',
                    content:
                        'The app provides a point-of-sale (POS) software solution designed to help businesses manage sales, inventory, and payments.',
                  ),
                  _Section(
                    title: '3. User Responsibilities',
                    content:
                        'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You agree to provide accurate and complete information.',
                  ),
                  _Section(
                    title: '4. Fees and Payments',
                    content:
                        'Use of certain features may require payment of fees. You agree to pay all applicable fees as described in our pricing plans.',
                  ),
                  _Section(
                    title: '5. Prohibited Conduct',
                    content:
                        'You agree not to use the service for any illegal purposes or in a way that interferes with the proper functioning of the software.',
                  ),
                  _Section(
                    title: '6. Limitation of Liability',
                    content:
                        'The app shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use our service.',
                  ),
                  _Section(
                    title: '7. Changes to Terms',
                    content:
                        'We reserve the right to modify these terms at any time. Your continued use of the service after such changes constitutes acceptance of the new terms.',
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Last updated: May 2026',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
