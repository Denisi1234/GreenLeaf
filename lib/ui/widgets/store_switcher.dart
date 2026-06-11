import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import 'package:track_mauzo/service/pos_local_store.dart';

class StoreSwitcher extends StatelessWidget {
  const StoreSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PosLocalStore>(
      builder: (context, store, child) {
        final strings = AppStrings.of(store.languageCode);
        return FutureBuilder<List<Map<String, Object?>>>(
          future: store.loadAllStores(),
          builder: (context, snapshot) {
            final stores = snapshot.data ?? [];
            final activeStore = stores.firstWhere(
              (s) => s['id'] == store.activeStoreId,
              orElse: () => {'name': strings.unknownStore},
            );

            return ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined),
              title: Text(strings.activeStore),
              subtitle: Text(activeStore['name'] as String),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _showStoreSelectionDialog(context, store, stores),
            );
          },
        );
      },
    );
  }

  void _showStoreSelectionDialog(
    BuildContext context,
    PosLocalStore store,
    List<Map<String, Object?>> stores,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final strings = AppStrings.of(store.languageCode);
        return AlertDialog(
          title: Text(strings.selectActiveStore),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: stores.length,
                    separatorBuilder: (context, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final s = stores[index];
                      final isSelected = s['id'] == store.activeStoreId;
                      return ListTile(
                        title: Text(s['name'] as String),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                        onTap: () {
                          store.setActiveStore(s['id'] as String);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  title: Text(
                    strings.addNewStore,
                    style: const TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCreateStoreDialog(context, store);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateStoreDialog(BuildContext context, PosLocalStore store) {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        final strings = AppStrings.of(store.languageCode);
        return AlertDialog(
          title: Text(strings.createNewStore),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: strings.storeName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  // In a real app, this would call a method to save to the database
                  // store.createNewStore(nameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text(strings.create),
            ),
          ],
        );
      },
    );
  }
}
