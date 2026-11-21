import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

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
        color: const Color(0xFF0F172A),
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
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFD6E4F0)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.file(File(imagePath!), fit: BoxFit.cover),
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
      borderRadius: BorderRadius.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0284C7), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Upload item photo'),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.tr('PNG, JPG up to 5MB'),
              style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF94A3B8)),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_busy_rounded,
                size: 20,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Track expiry date'),
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('Receive alerts when this item is about to expire'),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
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
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
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
                          color: const Color(0xFF475569),
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
                          color: const Color(0xFF0F172A),
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
