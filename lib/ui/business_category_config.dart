import 'package:flutter/material.dart';
import 'package:track_mauzo/ui/models/capability.dart';

enum BusinessCategory {
  retail,
  pharmacy,
  electronics,
}

extension BusinessCategoryX on BusinessCategory {
  String get storageKey => switch (this) {
        BusinessCategory.retail => 'Retail',
        BusinessCategory.pharmacy => 'Pharmacy',
        BusinessCategory.electronics => 'Electronics',
      };

  String get displayName =>
      this == BusinessCategory.retail ? 'POS' : storageKey;

  String get drawerLabel => switch (this) {
        BusinessCategory.retail => 'Retail',
        BusinessCategory.pharmacy => 'Pharmacy',
        BusinessCategory.electronics => 'Electronics',
      };
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
    return switch (category) {
      BusinessCategory.retail => const BusinessCategoryConfig(
          category: BusinessCategory.retail,
          primaryColor: Color(0xFF68CADD),
          primaryDeepColor: Color(0xFF4FAEC1),
          primaryLightColor: Color(0xFFF0F9FB),
          accentColor: Color(0xFF111111),
          surfaceTintColor: Color(0xFFF7F7F8),
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
        ),
      BusinessCategory.pharmacy => const BusinessCategoryConfig(
          category: BusinessCategory.pharmacy,
          primaryColor: Color(0xFF68CADD),
          primaryDeepColor: Color(0xFF4FAEC1),
          primaryLightColor: Color(0xFFF0F9FB),
          accentColor: Color(0xFF111111),
          surfaceTintColor: Color(0xFFF7F7F8),
          dashboardHeadline: 'Pharmacy control center',
          dashboardHighlights: [
            'Expired soon items',
            'Prescription refills',
            'Margin tracking',
          ],
          salesHint: 'Search medicine names or prescription codes',
          productHint: 'Expiry, dosage, and prescription flags',
          paymentHint: 'Insurance and HMO-aware checkout',
          drawerQuickActions: [
            'Scan Prescription',
            'Check Expiry',
            'Refill Queue'
          ],
          recommendedMetrics: ['Expired soon', 'Refills', 'Margin'],
          capabilities: {
            Capability.usePrescriptionWorkflow,
            Capability.canTrackBatch
          },
        ),
      BusinessCategory.electronics => const BusinessCategoryConfig(
          category: BusinessCategory.electronics,
          primaryColor: Color(0xFF68CADD),
          primaryDeepColor: Color(0xFF4FAEC1),
          primaryLightColor: Color(0xFFF0F9FB),
          accentColor: Color(0xFF111111),
          surfaceTintColor: Color(0xFFF7F7F8),
          dashboardHeadline: 'Electronics command center',
          dashboardHighlights: [
            'High-value sales',
            'Warranty claims',
            'Brand performance',
          ],
          salesHint: 'Search by brand, model, or serial',
          productHint: 'Serial, warranty, and brand tracking',
          paymentHint: 'Warranty registration and service plans',
          drawerQuickActions: [
            'Scan Serial',
            'Register Warranty',
            'Upsell Service'
          ],
          recommendedMetrics: [
            'High-value sales',
            'Warranty claims',
            'Brand mix'
          ],
          capabilities: {Capability.requireSerialTracking},
        ),
    };
  }
}
