import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/report_models.dart';

class TopSellingProductsList extends StatelessWidget {
  const TopSellingProductsList({
    super.key,
    required this.products,
    required this.emptyMessage,
    this.onViewAll,
  });

  final List<ProductData> products;
  final String emptyMessage;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            emptyMessage,
            style: GoogleFonts.manrope(
              color: const Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < products.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE6EBF2),
            ),
          _ProductRow(
            data: products[i],
            rank: i + 1,
            highlightTop: i == 0,
          ),
        ],
        if (onViewAll != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onViewAll,
            icon: const Icon(Icons.chevron_right_rounded, size: 16),
            label: Text(
              'View All',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E67E8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.data,
    required this.rank,
    required this.highlightTop,
  });

  final ProductData data;
  final int rank;
  final bool highlightTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: highlightTop
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: highlightTop
                      ? const Color(0xFFB45309)
                      : const Color(0xFF667085),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.colors.first.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.icon,
              color: data.colors.first,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.orders,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.amount,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}