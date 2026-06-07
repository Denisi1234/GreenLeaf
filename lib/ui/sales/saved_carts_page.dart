import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';

class SavedCartsPage extends StatelessWidget {
  const SavedCartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(title: 'Saved for Later'),
            Expanded(
              child: ListenableBuilder(
                listenable: context.watch<PosLocalStore>(),
                builder: (context, _) {
                  final savedCarts = context.watch<PosLocalStore>().savedCarts;
                  if (savedCarts.isEmpty) {
                    return const Center(
                      child: Text('No carts saved for later'),
                    );
                  }
                  return ListView.builder(
                    itemCount: savedCarts.length,
                    itemBuilder: (context, index) {
                      final cart = savedCarts[index];
                      return ListTile(
                        title: Text('Cart saved on ${cart.savedAt}'),
                        subtitle: Text('${cart.items.length} items'),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () {
                            context.read<PosLocalStore>().restoreCart(cart.id);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
