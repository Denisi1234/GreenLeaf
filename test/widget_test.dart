import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/app.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/ui/auth/onboarding_page.dart';

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
    expect(find.text('TrackMauzo'), findsOneWidget);
  });
}
