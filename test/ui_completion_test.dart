import 'dart:async';

import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/ui/widgets/app_design.dart';
import 'package:aza_pos/ui/widgets/app_theme.dart';
import 'package:aza_pos/ui/widgets/market_shared_widgets.dart';
import 'package:aza_pos/ui/widgets/common/product_thumbnail.dart';
import 'package:aza_pos/ui/home/widgets/cart_quantity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/ui_test_fonts.dart';

class _Store extends PosLocalStore {
  @override
  String get languageCode => 'en';
}

Future<void> _mount(WidgetTester tester, Widget child,
    {bool reduceMotion = false, double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final store = _Store();
  addTearDown(store.dispose);
  await tester.pumpWidget(ChangeNotifierProvider<PosLocalStore>.value(
    value: store,
    child: MaterialApp(
      theme: buildOsposTheme(ThemeData.light().textTheme),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(scale),
        ),
        child: page!,
      ),
      home: Scaffold(body: child),
    ),
  ));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureUiTestFonts);

  testWidgets('whole-unit quantity editing rejects invalid and excess stock',
      (tester) async {
    double? result;
    await _mount(
        tester,
        Builder(
            builder: (context) => TextButton(
                  onPressed: () async => result = await CartQuantityDialog.show(
                      context,
                      productName: 'Tea',
                      quantity: 1,
                      available: 24),
                  child: const Text('Edit'),
                )));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1.5');
    await tester.tap(find.text('Update quantity'));
    await tester.pumpAndSettle();
    expect(
        find.text('Enter a whole quantity greater than zero.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '25');
    await tester.tap(find.text('Update quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Quantity exceeds available stock.'), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(find.byType(TextFormField), '7');
    await tester.tap(find.text('Update quantity'));
    await tester.pumpAndSettle();
    expect(result, 7);
    expect(tester.takeException(), isNull);
  });

  for (final entry in {
    MarketNoticeType.info: AppColors.primary,
    MarketNoticeType.success: AppColors.successDeep,
    MarketNoticeType.warning: AppColors.kpiAmber,
    MarketNoticeType.error: AppColors.dangerDeep,
  }.entries) {
    testWidgets(
        '${entry.key.name} feedback has its own tone and can be dismissed',
        (tester) async {
      late BuildContext pageContext;
      await _mount(tester, Builder(builder: (context) {
        pageContext = context;
        return const Text('Current form');
      }));
      showMarketNotice(pageContext,
          title: 'Notice',
          message: 'Your current form remains available.',
          type: entry.key,
          duration: const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color == entry.value),
          findsWidgets);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Notice'), findsNothing);
      expect(find.text('Current form'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'empty state actions remain usable with large text on small phones',
      (tester) async {
    var primary = 0;
    var secondary = 0;
    await _mount(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MarketEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No matching products',
            message:
                'Clear the search or add your first product to start selling.',
            actionLabel: 'Add your first product',
            secondaryActionLabel: 'Clear search filters',
            onAction: () => primary++,
            onSecondaryAction: () => secondary++,
          ),
        ),
        scale: 1.6);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your first product'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear search filters'));
    await tester.tap(find.text('Clear search filters'));
    await tester.pumpAndSettle();
    expect(primary, 1);
    expect(secondary, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading respects reduced motion and retains progress context',
      (tester) async {
    await _mount(
        tester,
        const MarketLoadingView(
            message: 'Loading inventory',
            subMessage: 'Your saved products will appear here.'),
        reduceMotion: true);
    await tester.pumpAndSettle();
    expect(find.text('Loading inventory'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product placeholders identify items when a photo is missing',
      (tester) async {
    await _mount(
        tester,
        const Row(children: [
          SizedBox(
              width: 80,
              height: 80,
              child: ProductThumbnail(name: 'Mineral Water')),
          SizedBox(
              width: 80,
              height: 80,
              child: ProductThumbnail(name: 'Product 024')),
          SizedBox(width: 80, height: 80, child: ProductThumbnail(name: '  ')),
        ]));
    await tester.pumpAndSettle();
    expect(find.text('MW'), findsOneWidget);
    expect(find.text('P024'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long form labels and errors fit beside actions with large text',
      (tester) async {
    await _mount(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
              child: MarketFormField(
            label: 'Customer contact information',
            hintText: 'Phone number',
            isRequired: true,
            labelAction:
                TextButton(onPressed: () {}, child: const Text('Help')),
            validator: (_) =>
                'Enter a valid customer phone number before saving.',
          )),
        ),
        scale: 1.6);
    tester.state<FormState>(find.byType(Form)).validate();
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid customer phone number before saving.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'large action labels remain usable and saves cannot be duplicated',
      (tester) async {
    final saving = Completer<void>();
    var calls = 0;
    await _mount(
        tester,
        Center(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: MarketButton(
            label: 'Save customer details',
            onTap: () {
              calls++;
              return saving.future;
            },
          ),
        )),
        scale: 1.6);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    expect(calls, 1);
    saving.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
