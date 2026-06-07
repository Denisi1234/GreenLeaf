import 'product_item.dart';

class SavedCart {
  const SavedCart({
    required this.id,
    required this.items,
    required this.savedAt,
  });

  final String id;
  final List<OrderLineItem> items;
  final String savedAt;
}
