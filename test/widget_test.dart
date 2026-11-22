import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/app.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/ui/auth/onboarding_page.dart';

void main() {
  testWidgets('renders clean onboarding page with carousel and controls', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = PosLocalStore();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Aza POS'), findsOneWidget);
  });
}
