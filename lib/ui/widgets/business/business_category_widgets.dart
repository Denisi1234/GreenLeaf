import 'package:flutter/material.dart';

import '../../business_category_config.dart';
import '../app_design.dart';
import '../common/market_page_header.dart';

class BusinessCategoryBadge extends StatelessWidget {
  const BusinessCategoryBadge({
    super.key,
    required this.category,
    this.label,
  });

  final BusinessCategory category;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.forCategory(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.primaryLightColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Text(
        label ?? category.displayName,
        style: AppTypography.label.copyWith(
          color: config.primaryColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CategorySpecificTile extends StatelessWidget {
  const CategorySpecificTile({
    super.key,
    required this.category,
    required this.child,
  });

  final BusinessCategory category;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.forCategory(category);
    return Container(
      decoration: BoxDecoration(
        color: config.surfaceTintColor,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class CategoryAwareHeader extends StatelessWidget {
  const CategoryAwareHeader({
    super.key,
    required this.category,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBackButton = true,
  });

  final BusinessCategory category;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.forCategory(category);
    return MarketPageHeader(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      actions: trailing == null ? null : [trailing!],
      isGradient: true,
      centerTitle: false,
      titleSize: 22,
      titleWeight: FontWeight.w800,
      gradientColors: [config.primaryColor, config.primaryDeepColor],
    );
  }
}

extension BusinessCategoryWidgetBuilders on BusinessCategory {
  BusinessCategoryBadge badge({String? label}) {
    return BusinessCategoryBadge(category: this, label: label);
  }

  CategorySpecificTile tile({required Widget child}) {
    return CategorySpecificTile(category: this, child: child);
  }

  CategoryAwareHeader header({
    required String title,
    String? subtitle,
    Widget? trailing,
    bool showBackButton = true,
  }) {
    return CategoryAwareHeader(
      category: this,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      showBackButton: showBackButton,
    );
  }
}
