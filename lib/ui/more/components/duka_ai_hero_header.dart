import 'package:flutter/material.dart';

class DukaAiHeroHeader extends StatelessWidget {
  const DukaAiHeroHeader({
    super.key,
    required this.onBackTap,
    required this.onMoreTap,
    required this.onSubtitleTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onMoreTap;
  final VoidCallback onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DUKA AI Advisor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: onSubtitleTap,
                  child: const Row(
                    children: [
                      Text(
                        'Powered by Gemini',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.info_outline_rounded,
                          size: 12, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMoreTap,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}
