import 'package:flutter/material.dart';
import '../../widgets/app_design.dart';

class QuickActionData {
  const QuickActionData({
    required this.id,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.background,
    this.foreground,
    this.iconBackground,
  });

  final String id;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Gradient? background;
  final Color? foreground;
  final Color? iconBackground;
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.action,
    required this.onTap,
    this.hero = false,
  });

  final QuickActionData action;
  final VoidCallback onTap;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final iconBackground = action.iconBackground ?? Colors.white;
    final labelColor = action.foreground ?? AppColors.reportsInk;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(hero ? 20 : 12),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: hero ? 118 : 108),
          padding: EdgeInsets.symmetric(
            horizontal: hero ? 14 : 10,
            vertical: hero ? 14 : 12,
          ),
          decoration: BoxDecoration(
            gradient: action.background,
            color: action.background == null ? Colors.white : null,
            borderRadius: BorderRadius.circular(hero ? 20 : 12),
            border: action.background == null
                ? Border.all(color: AppColors.reportsBorder)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: hero ? 42 : 40,
                height: hero ? 42 : 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(hero ? 10 : 8),
                ),
                child: Icon(action.icon,
                    color: action.iconColor, size: hero ? 22 : 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero ? 'Run Checkout' : action.label,
                    style: TextStyle(
                      color: hero ? const Color(0xFFBFD4FF) : labelColor,
                      fontSize: hero ? 10 : 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: hero ? 0.2 : -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.foreground ?? AppColors.reportsInk,
                      fontSize: hero ? 15 : 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
