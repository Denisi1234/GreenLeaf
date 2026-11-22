import 'package:flutter/material.dart';

import '../app_design.dart';

class MarketSectionHeader extends StatelessWidget {
  const MarketSectionHeader({
    super.key,
    required this.title,
    required this.trailing,
    this.titleColor,
    this.titleSize,
    this.titleWeight,
  });

  final String title;
  final Widget trailing;
  final Color? titleColor;
  final double? titleSize;
  final FontWeight? titleWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionHeader.copyWith(
              color: titleColor ?? AppColors.ink,
              fontSize: titleSize,
              fontWeight: titleWeight,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    );
  }
}
