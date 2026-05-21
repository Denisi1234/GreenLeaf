import 'package:flutter/material.dart';

import '../widgets/market_shared_widgets.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: Column(
        children: [
          const MarketPageHeader(
            title: 'Privacy Policy',
            isGradient: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                _Section(
                  title: '1. Information We Collect',
                  content:
                      'We collect information you provide directly to us when you create an account, such as your name, email address, business details, and payment information.',
                ),
                _Section(
                  title: '2. How We Use Your Information',
                  content:
                      'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you about your account.',
                ),
                _Section(
                  title: '3. Data Security',
                  content:
                      'We implement industry-standard security measures to protect your personal information from unauthorized access, disclosure, or destruction.',
                ),
                _Section(
                  title: '4. Information Sharing',
                  content:
                      'We do not sell your personal information to third parties. We may share information with service providers who assist us in operating our business.',
                ),
                _Section(
                  title: '5. Your Choices',
                  content:
                      'You can update your account information at any time through the app settings. You may also request deletion of your account and associated data.',
                ),
                _Section(
                  title: '6. Cookies and Tracking',
                  content:
                      'We use cookies and similar technologies to enhance your experience and analyze how our service is being used.',
                ),
                _Section(
                  title: '7. Updates to This Policy',
                  content:
                      'We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy on this page.',
                ),
                SizedBox(height: 40),
                Text(
                  'Last updated: May 2026',
                  style: TextStyle(
                    color: Color(0xFF6F7887),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF18233B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF5F6980),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
