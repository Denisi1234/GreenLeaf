import '../../widgets/app_design.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/report_models.dart';
import '../../widgets/market_shared_widgets.dart';

class TopSellingProductsSheet extends StatelessWidget {
  const TopSellingProductsSheet({
    super.key,
    required this.products,
    required this.emptyMessage,
  });

  final List<ProductData> products;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: MarketSurfaceCard(
          borderColor: const Color(0xFFF3F4F6),
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarketSectionHeader(
                  title: 'Top Selling Products',
                  trailing: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            emptyMessage,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF667085),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF3F4F6),
                          ),
                          itemBuilder: (context, index) {
                            return _ProductRow(
                              data: products[index],
                              rank: index + 1,
                              highlightTop: index == 0,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                  ? const Color(0xFFF3F4F6)
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
                      ? AppColors.primaryDeep
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
                    color: const Color(0xFF111111),
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
              color: const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
