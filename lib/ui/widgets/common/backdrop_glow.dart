import 'package:flutter/material.dart';

import '../app_design.dart';

class BackdropGlow extends StatelessWidget {
  const BackdropGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(color: AppColors.pageBackground),
    );
  }
}

class ScrollHandle extends StatelessWidget {
  const ScrollHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 3,
        height: 118,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
