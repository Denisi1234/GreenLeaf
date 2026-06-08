import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class SubscriptionPlanPage extends StatelessWidget {
  const SubscriptionPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(
              title: 'Subscription Plan',
              showBorder: true,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MarketSurfaceCard(
                    padding: const EdgeInsets.all(24),
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.border,
                    radius: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 42,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Coming soon',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Subscription details will be available in a future update.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        MarketButton(
                          label: 'Back',
                          onTap: () => Navigator.of(context).pop(),
                          isFullWidth: false,
                          color: AppColors.primary,
                          foregroundColor: Colors.white,
                          borderColor: Colors.transparent,
                          height: 46,
                          radius: AppRadius.standard,
                          paddingHorizontal: 20,
                        ),
                      ],
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
