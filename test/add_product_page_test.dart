import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/ui/products/add_product_page.dart';

void main() {
  testWidgets('AddProductPage renders without crashing', (WidgetTester tester) async {
    final store = PosLocalStore();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: store,
          child: const AddProductPage(nextCode: 'P001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the page rendered and the form is visible
    expect(find.text('New Item Details'), findsOneWidget);
    expect(find.text('Item Name *', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
