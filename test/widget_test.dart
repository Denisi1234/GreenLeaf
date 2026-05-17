import 'package:flutter_test/flutter_test.dart';
import 'package:possystem/app.dart';

void main() {
  testWidgets('shows the fresh start message', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Fresh start.'), findsOneWidget);
    expect(find.text('Start building'), findsOneWidget);
  });
}
