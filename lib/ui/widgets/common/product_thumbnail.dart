import 'package:flutter/material.dart';

import '../app_design.dart';
import '../app_image.dart';

/// Uses the actual product photo, with an identifiable fallback when unavailable.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.name, this.imagePath});

  final String name;
  final String? imagePath;

  String get _initials {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '–';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    final last = words.last;
    final suffix =
        RegExp(r'^\d{1,3}$').hasMatch(last) ? last : last.characters.first;
    return '$first$suffix'.toUpperCase();
  }

  Widget _placeholder() => ColoredBox(
        color: AppColors.primarySoft,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_initials,
                  style: AppTypography.h2.copyWith(
                      fontSize: 32,
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: imagePath?.trim().isNotEmpty == true
            ? Image(
                image: appImageProvider(context, imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      );
}
