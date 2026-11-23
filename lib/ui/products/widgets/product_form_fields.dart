import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aza_pos/l10n/app_localization.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.1,
      ),
    );
  }
}

class PhotoUploadTile extends StatelessWidget {
  const PhotoUploadTile({
    super.key,
    required this.imagePath,
    required this.onPickTap,
    required this.onRemoveTap,
  });

  final String? imagePath;
  final VoidCallback onPickTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.standard),
              child: Image(
                image: appImageProvider(context, imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: onRemoveTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPickTap,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primaryDeep,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Upload item photo'),
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.tr('PNG, JPG up to 5MB'),
              style: GoogleFonts.manrope(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpiryTrackingCard extends StatelessWidget {
  const ExpiryTrackingCard({
    super.key,
    required this.trackExpiry,
    required this.expiryDate,
    required this.onToggleExpiry,
    required this.onPickExpiryDate,
  });

  final bool trackExpiry;
  final DateTime? expiryDate;
  final ValueChanged<bool> onToggleExpiry;
  final VoidCallback onPickExpiryDate;

  String _displayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Track expiry date'),
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('Receive alerts when this item is about to expire'),
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: trackExpiry,
                onChanged: onToggleExpiry,
              ),
            ],
          ),
          if (trackExpiry) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Expiry date'),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expiryDate == null
                            ? context.tr('No date selected')
                            : _displayDate(expiryDate!),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickExpiryDate,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                  ),
                  label: Text(
                    expiryDate == null ? context.tr('Set date') : context.tr('Change'),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
