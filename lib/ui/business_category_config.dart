import 'package:flutter/material.dart';
import 'package:aza_pos/ui/models/capability.dart';
import 'widgets/app_design.dart';

enum BusinessCategory {
  retail,
}

extension BusinessCategoryX on BusinessCategory {
  String get storageKey => 'Retail';

  String get displayName => 'POS';

  String get drawerLabel => 'Retail';
}

class BusinessCategoryConfig {
  const BusinessCategoryConfig({
    required this.category,
    required this.primaryColor,
    required this.primaryDeepColor,
    required this.primaryLightColor,
    required this.accentColor,
    required this.surfaceTintColor,
    required this.dashboardHeadline,
    required this.dashboardHighlights,
    required this.salesHint,
    required this.productHint,
    required this.paymentHint,
    required this.drawerQuickActions,
    required this.recommendedMetrics,
    required this.capabilities,
  });

  final BusinessCategory category;
  final Color primaryColor;
  final Color primaryDeepColor;
  final Color primaryLightColor;
  final Color accentColor;
  final Color surfaceTintColor;
  final String dashboardHeadline;
  final List<String> dashboardHighlights;
  final String salesHint;
  final String productHint;
  final String paymentHint;
  final List<String> drawerQuickActions;
  final List<String> recommendedMetrics;
  final Set<Capability> capabilities;

  String get label => category.displayName;

  static BusinessCategoryConfig forCategory(BusinessCategory category) {
    return BusinessCategoryConfig(
      category: BusinessCategory.retail,
      primaryColor: AppColors.primary,
      primaryDeepColor: AppColors.primaryDeep,
      primaryLightColor: AppColors.primaryLight,
      accentColor: AppColors.ink,
      surfaceTintColor: AppColors.surfaceSecondary,
      dashboardHeadline: 'Retail floor control',
      dashboardHighlights: [
        'Fast-moving items',
        'Basket size trends',
        'Markdown pressure',
      ],
      salesHint: 'Search by SKU, barcode, or product name',
      productHint: 'Track barcode, shelf location, and fast-moving stock',
      paymentHint: 'Support loyalty points and split tenders',
      drawerQuickActions: [
        'Start Scan',
        'Process Return',
        'Apply Discount',
      ],
      recommendedMetrics: [
        'Basket size',
        'Fast movers',
        'Markdowns',
      ],
      capabilities: {
        Capability.hasLoyaltyPoints,
        Capability.canManageReturns,
        Capability.supportsSizeColorMatrix,
      },
    );
  }
}
