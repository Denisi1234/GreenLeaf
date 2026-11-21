import 'package:track_mauzo/l10n/app_localization.dart';

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
             MarketPageHeader(title: context.tr('About TrackMauzo')),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
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
                              color: AppColors.kpiRoseBg,
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
                                color: AppColors.kpiRose,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('TrackMauzo'),
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('Version 2.4.1'),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Smart, modern point of sale system designed to power retail shops, inventory, and sales effortlessly.'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textSecondary,
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
                                context.tr('Open Source Licenses'),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.kpiSky,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('© 2026 TrackMauzo. All rights reserved.'),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textLight,
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
