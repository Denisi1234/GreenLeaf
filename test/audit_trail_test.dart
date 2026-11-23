import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aza_pos/l10n/app_strings.dart';
import 'package:aza_pos/service/expense_model.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/ui/audit/audit_export_service.dart';
import 'package:aza_pos/ui/audit/audit_trail_page.dart';
import 'package:aza_pos/ui/models/product_item.dart';
import 'package:aza_pos/ui/more/advanced_features_page.dart';
import 'package:aza_pos/ui/products/inventory_product_item.dart';
import 'package:aza_pos/ui/widgets/app_design.dart';
import 'package:aza_pos/ui/widgets/app_theme.dart';
import 'package:aza_pos/ui/widgets/common/market_search_field.dart';

import 'support/memory_pos_database.dart';

class _AuditMemoryDatabase extends MemoryPosLocalDatabase {
  bool _auditReady = false;

  @override
  Future<Database> get database async {
    final db = await super.database;
    if (!_auditReady) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id TEXT PRIMARY KEY,
          store_id TEXT NOT NULL,
          sequence INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          module TEXT NOT NULL,
          action TEXT NOT NULL,
          severity TEXT NOT NULL,
          actor_id TEXT NOT NULL DEFAULT '',
          actor_name TEXT NOT NULL DEFAULT '',
          actor_role TEXT NOT NULL DEFAULT '',
          entity_type TEXT NOT NULL DEFAULT '',
          entity_id TEXT NOT NULL DEFAULT '',
          entity_label TEXT NOT NULL DEFAULT '',
          summary TEXT NOT NULL DEFAULT '',
          before_json TEXT NOT NULL DEFAULT '{}',
          after_json TEXT NOT NULL DEFAULT '{}',
          metadata_json TEXT NOT NULL DEFAULT '{}',
          prev_hash TEXT NOT NULL DEFAULT 'GENESIS',
          entry_hash TEXT NOT NULL DEFAULT ''
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_audit_logs_store_seq ON audit_logs (store_id, sequence DESC)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_audit_logs_store_ts ON audit_logs (store_id, timestamp DESC)',
      );
      _auditReady = true;
    }
    return db;
  }
}

class _AuditWidgetStore extends PosLocalStore {
  _AuditWidgetStore({required _AuditMemoryDatabase database})
      : super(database: database);

  @override
  bool get isInitialized => true;

  @override
  bool hasPermission(String permission) => true;
}

AuditLogEntry _buildChainedEntry({
  required int sequence,
  required String prevHash,
  String? id,
  String storeId = 'store-default',
  DateTime? timestamp,
  AuditModule module = AuditModule.sales,
  String action = 'sale.completed',
  AuditSeverity severity = AuditSeverity.info,
  String actorName = 'Neema',
  String actorRole = 'Cashier',
  String entityType = 'Order',
  String entityId = 'ORD-100',
  String entityLabel = 'Receipt ORD-100',
  String summary = 'Completed cash sale ORD-100',
  Map<String, String> beforeValues = const <String, String>{},
  Map<String, String> afterValues = const <String, String>{},
  Map<String, String> metadata = const <String, String>{},
}) {
  final ts = timestamp ?? DateTime(2026, 11, 22, 10, sequence);
  final entryId = id ?? 'AUD-$sequence';
  final hash = AuditLogEntry.computeHash(
    id: entryId,
    storeId: storeId,
    sequence: sequence,
    timestampIso: ts.toIso8601String(),
    module: module.storageKey,
    action: action,
    severity: severity.storageKey,
    actorId: 'staff-1',
    actorName: actorName,
    actorRole: actorRole,
    entityType: entityType,
    entityId: entityId,
    entityLabel: entityLabel,
    summary: summary,
    beforeValues: beforeValues,
    afterValues: afterValues,
    metadata: metadata,
    prevHash: prevHash,
  );
  return AuditLogEntry(
    id: entryId,
    storeId: storeId,
    sequence: sequence,
    timestamp: ts,
    module: module,
    action: action,
    severity: severity,
    actorId: 'staff-1',
    actorName: actorName,
    actorRole: actorRole,
    entityType: entityType,
    entityId: entityId,
    entityLabel: entityLabel,
    summary: summary,
    beforeValues: beforeValues,
    afterValues: afterValues,
    metadata: metadata,
    prevHash: prevHash,
    entryHash: hash,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    await initializeDateFormatting('en');
    await initializeDateFormatting('sw');
  });

  group('AuditLogEntry hash chain & verification', () {
    test('verifies intact sequential SHA-256 chain and detects tampering or gaps',
        () {
      final e1 = _buildChainedEntry(
        sequence: 1,
        prevHash: AuditLogEntry.genesisHash,
        summary: 'Opened shift Till 1',
        module: AuditModule.register,
        action: 'register.shift_opened',
      );
      final e2 = _buildChainedEntry(
        sequence: 2,
        prevHash: e1.entryHash,
        summary: 'Updated tax rate from 0% to 18%',
        module: AuditModule.settings,
        action: 'settings.tax_updated',
        severity: AuditSeverity.critical,
        beforeValues: const {'Rate': '0%'},
        afterValues: const {'Rate': '18%'},
      );
      final e3 = _buildChainedEntry(
        sequence: 3,
        prevHash: e2.entryHash,
        summary: 'Removed product Sugar 1kg',
        module: AuditModule.inventory,
        action: 'inventory.deleted',
        severity: AuditSeverity.critical,
      );

      final intact = AuditIntegrityReport.verifyChain([e3, e1, e2]);
      expect(intact.isValid, isTrue);
      expect(intact.totalChecked, 3);
      expect(intact.brokenEntryIds, isEmpty);
      expect(intact.lastSequence, 3);
      expect(intact.headHash, e3.entryHash);

      // Mutate summary without updating entryHash -> tampered entry + next broken link.
      final tamperedMap = Map<String, Object?>.from(e2.toMap())
        ..['summary'] = 'Tampered amount';
      final tamperedE2 = AuditLogEntry.fromMap(tamperedMap);
      final tamperedReport =
          AuditIntegrityReport.verifyChain([e1, tamperedE2, e3]);
      expect(tamperedReport.isValid, isFalse);
      expect(tamperedReport.brokenEntryIds, contains('AUD-2'));

      // Sequence gap (sequence 2 deleted) flags broken chain on entry 3.
      final gappedReport = AuditIntegrityReport.verifyChain([e1, e3]);
      expect(gappedReport.isValid, isFalse);
      expect(gappedReport.brokenEntryIds, contains('AUD-3'));
    });

    test('round-trips map serialization and localizes action titles EN/SW',
        () {
      final original = _buildChainedEntry(
        sequence: 1,
        prevHash: AuditLogEntry.genesisHash,
        action: 'sale.voided',
        beforeValues: const {'Total': '5000'},
        afterValues: const {'Status': 'Voided'},
      );
      final restored = AuditLogEntry.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.entryHash, original.entryHash);
      expect(restored.isSelfHashValid, isTrue);
      expect(restored.beforeValues, {'Total': '5000'});
      expect(restored.afterValues, {'Status': 'Voided'});
      expect(original.actionTitle(false), isNot(original.action));
      expect(original.actionTitle(true), isNot(original.actionTitle(false)));
    });
  });

  group('PosAuditStore integration & querying', () {
    late _AuditMemoryDatabase database;
    late PosLocalStore store;

    setUp(() {
      database = _AuditMemoryDatabase();
      store = PosLocalStore(database: database);
    });

    tearDown(() async {
      store.dispose();
      await database.close();
    });

    test(
        'records inventory CRUD diffs & expense events and persists hash chain in SQLite',
        () async {
      const product = InventoryProductItem(
        code: 'SKU-100',
        name: 'Kilombero Rice 5kg',
        category: 'Food',
        purchasePrice: 12000,
        sellingPrice: 15000,
        stockCount: 20,
        stockState: InventoryStockState.inStock,
        artType: ProductArtType.aquafina,
        unit: 'Bag',
      );

      await store.addProduct(product);
      await store.updateProduct(
        product.copyWith(sellingPrice: 16500, stockCount: 25),
      );
      await store.removeProduct('SKU-100');

      await store.addExpense(
        Expense(
          title: 'Shop Electricity Token',
          amount: 25000,
          category: 'Utilities',
          paymentMethod: 'Cash',
          date: DateTime(2026, 11, 22),
        ),
      );
      final expenseId = store.expenses.first.id!;
      await store.deleteExpense(expenseId);

      // Flush pending unawaited audit writes cleanly.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final logs = store.auditLogs;
      expect(logs, hasLength(5));
      expect(logs.first.sequence, 5);
      expect(logs.last.sequence, 1);

      final integrity = store.verifyAuditIntegrity();
      expect(integrity.isValid, isTrue);
      expect(integrity.totalChecked, 5);
      expect(integrity.brokenEntryIds, isEmpty);

      final updateEvent =
          logs.firstWhere((entry) => entry.action == 'inventory.updated');
      expect(updateEvent.severity, AuditSeverity.warning);
      expect(updateEvent.beforeValues['Selling Price'], '15000.00');
      expect(updateEvent.afterValues['Selling Price'], '16500.00');
      expect(updateEvent.beforeValues['Stock'], '20 Bag');
      expect(updateEvent.afterValues['Stock'], '25 Bag');

      final deleteProductEvent =
          logs.firstWhere((entry) => entry.action == 'inventory.deleted');
      expect(deleteProductEvent.severity, AuditSeverity.critical);

      final persistedRows = await database.loadAuditLogs('store-default');
      expect(persistedRows, hasLength(5));

      // Query filters: module, severity, actor, search, date range
      expect(
        store.queryAuditLogs(module: AuditModule.expenses),
        hasLength(2),
      );
      expect(
        store.queryAuditLogs(severity: AuditSeverity.warning),
        hasLength(1),
      );
      expect(
        store.queryAuditLogs(query: 'Electricity'),
        hasLength(2),
      );

      await store.recordAuditEvent(
        module: AuditModule.settings,
        action: 'settings.tax_updated',
        severity: AuditSeverity.warning,
        entityType: 'Tax',
        summary: 'Enabled VAT 18%',
        actorIdOverride: 'staff-amina',
        actorNameOverride: 'Amina',
        actorRoleOverride: 'Manager',
      );

      expect(
        store.queryAuditLogs(actorName: 'Amina'),
        hasLength(1),
      );
      final today = DateTime.now();
      expect(
        store.queryAuditLogs(
          startDate: today,
          endDate: today,
        ),
        hasLength(6),
      );
      expect(
        store.queryAuditLogs(
          startDate: today.subtract(const Duration(days: 10)),
          endDate: today.subtract(const Duration(days: 5)),
        ),
        isEmpty,
      );
    });

    test('ignores audit completion safely when store is disposed in flight',
        () async {
      final tempStore = PosLocalStore(database: database);
      final pending = tempStore.recordAuditEvent(
        module: AuditModule.settings,
        action: 'settings.tax_updated',
        entityType: 'Tax',
        summary: 'Disposed before completion',
      );
      tempStore.dispose();
      await pending;
      // Also safe if recordAuditEvent is invoked after dispose.
      await tempStore.recordAuditEvent(
        module: AuditModule.settings,
        action: 'settings.tax_updated',
        entityType: 'Tax',
        summary: 'Invoked after dispose',
      );
    });
  });

  group('AuditExportService', () {
    test('builds non-empty localized CSV and valid %PDF document bytes',
        () async {
      final entry1 = _buildChainedEntry(
        sequence: 1,
        prevHash: AuditLogEntry.genesisHash,
        module: AuditModule.inventory,
        action: 'inventory.updated',
        severity: AuditSeverity.warning,
        entityLabel: 'Sugar 1kg',
        summary: 'Updated price',
        beforeValues: const {'Selling Price': '2800.00'},
        afterValues: const {'Selling Price': '3000.00'},
      );
      final entry2 = _buildChainedEntry(
        sequence: 2,
        prevHash: entry1.entryHash,
        module: AuditModule.sales,
        action: 'sale.voided',
        severity: AuditSeverity.critical,
        entityLabel: 'ORD-77',
        summary: 'Voided duplicate receipt ORD-77',
      );
      final entries = [entry2, entry1];
      final integrity = AuditIntegrityReport.verifyChain(entries);

      final csvEn = AuditExportService.buildCsv(
        entries: entries,
        isSwahili: false,
      );
      expect(csvEn, contains('Sequence,Timestamp,User'));
      expect(csvEn, contains('Sugar 1kg'));
      expect(csvEn, contains('Selling Price: 2800.00 -> 3000.00'));
      expect(csvEn, contains(entry1.entryHash));

      final csvSw = AuditExportService.buildCsv(
        entries: entries,
        isSwahili: true,
      );
      expect(csvSw, contains('Mfuatano,Tarehe na Muda,Mtumiaji'));

      final pdfBytes = await AuditExportService.buildPdf(
        entries: entries,
        integrity: integrity,
        strings: AppStrings.of('en'),
        filterSummary: 'All recorded events',
      );
      expect(pdfBytes.length, greaterThan(200));
      expect(utf8.decode(pdfBytes.sublist(0, 4), allowMalformed: true), '%PDF');
    });
  });

  group('AuditTrailPage & AdvancedFeaturesPage UI', () {
    late _AuditMemoryDatabase database;
    late _AuditWidgetStore store;

    setUp(() {
      database = _AuditMemoryDatabase();
      store = _AuditWidgetStore(database: database);
    });

    tearDown(() async {
      store.dispose();
      await database.close();
    });

    Future<void> seedStoreEvents() async {
      await store.recordAuditEvent(
        module: AuditModule.inventory,
        action: 'inventory.added',
        severity: AuditSeverity.info,
        entityType: 'Product',
        entityId: 'SKU-1',
        entityLabel: 'Arabica Beans',
        summary: 'Added Arabica Beans at 18000 TSh',
        actorIdOverride: 'u1',
        actorNameOverride: 'Baraka',
        actorRoleOverride: 'Owner',
      );
      await store.recordAuditEvent(
        module: AuditModule.sales,
        action: 'sale.voided',
        severity: AuditSeverity.critical,
        entityType: 'Order',
        entityId: 'ORD-909',
        entityLabel: 'Receipt ORD-909',
        summary: 'Voided duplicate sale ORD-909',
        beforeValues: const {'Status': 'Completed', 'Total': '12500.00'},
        afterValues: const {'Status': 'Voided', 'Reason': 'Cashier error'},
        actorIdOverride: 'u2',
        actorNameOverride: 'Amina',
        actorRoleOverride: 'Manager',
      );
    }

    Widget wrapApp(Widget child) {
      return ChangeNotifierProvider<PosLocalStore>.value(
        value: store,
        child: MaterialApp(
          theme: buildOsposTheme(
            ThemeData.dark().textTheme,
            themeId: 'whatsapp_dark',
          ),
          home: child,
        ),
      );
    }

    testWidgets('navigates from AdvancedFeaturesPage to AuditTrailPage',
        (tester) async {
      await seedStoreEvents();
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapApp(const AdvancedFeaturesPage()));
      await tester.pumpAndSettle();

      final tile = find.text('Audit & trail');
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SECURITY & AUDIT'), findsOneWidget);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(AuditTrailPage), findsOneWidget);
      expect(find.text('Voided duplicate sale ORD-909'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders at 320px and 1280px with sharp inputs, filters, detail diff sheet, and integrity dialog',
        (tester) async {
      await seedStoreEvents();

      // Narrow 320px phone check — zero RenderFlex overflow.
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(wrapApp(const AuditTrailPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Desktop 1280px layout + sharp 0px inputs + interactions.
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify sharp 0px corner radius on MarketSearchField and actor dropdown.
      final searchField = tester.widget<MarketSearchField>(
        find.byType(MarketSearchField),
      );
      expect(searchField.radius, AppRadius.input);
      expect(AppRadius.input, 0.0);

      final dropdown = tester.widget<DropdownButtonFormField<String?>>(
        find.byType(DropdownButtonFormField<String?>),
      );
      final enabledBorder =
          dropdown.decoration.enabledBorder! as OutlineInputBorder;
      expect(enabledBorder.borderRadius, BorderRadius.zero);

      // Filter by severity: Critical.
      await tester.tap(find.text('Critical'));
      await tester.pumpAndSettle();
      expect(find.text('Voided duplicate sale ORD-909'), findsOneWidget);
      expect(find.text('Added Arabica Beans at 18000 TSh'), findsNothing);

      // Open event detail sheet and verify diff & SHA-256 integrity proof.
      await tester.tap(find.text('Voided duplicate sale ORD-909'));
      await tester.pumpAndSettle();
      expect(find.text('BEFORE & AFTER CHANGES'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('SHA-256 record integrity verified'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('TAMPER-PROOF SIGNATURE'), findsOneWidget);
      expect(find.text('SHA-256 record integrity verified'), findsOneWidget);

      // Dismiss bottom sheet cleanly.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Clear filters and verify search query filtering.
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Added Arabica Beans at 18000 TSh'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Arabica');
      await tester.pumpAndSettle();
      expect(find.text('Added Arabica Beans at 18000 TSh'), findsOneWidget);
      expect(find.text('Voided duplicate sale ORD-909'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Open cryptographic chain verification dialog.
      await tester.tap(find.byTooltip('Verify chain integrity'));
      await tester.pumpAndSettle();
      expect(find.text('Audit Chain Verified'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
