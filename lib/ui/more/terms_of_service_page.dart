import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE7EAF0)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1E273A),
                        size: 26,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Terms of Service',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E273A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  _Section(
                    title: '1. Acceptance of Terms',
                    content:
                        'By accessing and using PayPoint POS, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
                  ),
                  _Section(
                    title: '2. Description of Service',
                    content:
                        'PayPoint provides a point-of-sale (POS) software solution designed to help businesses manage sales, inventory, and payments.',
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
                        'PayPoint shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use our service.',
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
              color: Color(0xFF1B2A4A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF3D4B67),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
