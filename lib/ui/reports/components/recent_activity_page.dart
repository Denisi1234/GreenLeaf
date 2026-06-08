import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../service/pos_local_store.dart';
import 'activity_tile.dart';
import '../reports_page.dart';

class RecentActivityPage extends StatelessWidget {
  const RecentActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: This relies on the _buildActivityItems method in ReportsPage,
    // which may need to be moved to a shared utility/service file.
    final items = ReportsPage.buildActivityItems(
      context.watch<PosLocalStore>().orders,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: const Color(0xFF33363F),
        title: const Text('Latest activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: [
          _RecentActivityCard(items: items),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<ActivityItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE8EBF1)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              ActivityTile(
                item: item,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ActivityDetailPage(item: item),
                    ),
                  );
                },
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9ECF2),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({super.key, required this.item});

  final ActivityItemData item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: const Color(0xFF33363F),
        title: Text(item.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE8EBF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: Color(0xFF7A859C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Time: ${item.time}',
                style: const TextStyle(
                  color: Color(0xFF33363F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.amount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Amount: ${item.amount}',
                  style: const TextStyle(
                    color: Color(0xFF33363F),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
