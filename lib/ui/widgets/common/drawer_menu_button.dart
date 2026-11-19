import 'package:flutter/material.dart';

import '../app_design.dart';

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({
    super.key,
    this.iconColor = AppColors.ink,
    this.backgroundColor = Colors.transparent,
    this.borderColor = Colors.transparent,
    this.shadowColor = Colors.transparent,
  });

  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => InkWell(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        onTap: () => Scaffold.of(context).openDrawer(),
        child: SizedBox(
          width: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DrawerMenuLine(width: 30, color: iconColor),
              const SizedBox(height: 6),
              _DrawerMenuLine(width: 20, color: iconColor),
              const SizedBox(height: 6),
              _DrawerMenuLine(width: 30, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuLine extends StatelessWidget {
  const _DrawerMenuLine({
    required this.width,
    required this.color,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
