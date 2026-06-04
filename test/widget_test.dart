import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:possystem/app.dart';
import 'package:possystem/service/pos_local_store.dart';

void main() {
  testWidgets('shows the product dashboard', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = PosLocalStore();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsWidgets);
  });
}
