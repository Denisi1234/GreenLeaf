import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(title: 'About TrackMauzo'),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE7F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/app_logo_transparent.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.point_of_sale_rounded,
                                size: 36,
                                color: Color(0xFFBE185D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'TrackMauzo',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 2.4.1',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Smart, modern point of sale system designed to power retail shops, inventory, and sales effortlessly.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              height: 1.5,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppColors.borderLight),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: 'TrackMauzo',
                              applicationVersion: '2.4.1',
                              applicationLegalese: '© 2026 TrackMauzo. All rights reserved.',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Open Source Licenses',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '© 2026 TrackMauzo. All rights reserved.',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
