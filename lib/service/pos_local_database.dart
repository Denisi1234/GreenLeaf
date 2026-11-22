import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'pos_order_models.dart';
import 'receipt_settings.dart';
import 'register_shift_model.dart';
import 'secure_token_storage.dart';
import 'tax_settings.dart';
import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';
import '../utils/quantity_formatter.dart';

part '../database/pos_accounting_database.dart';
part '../database/pos_supplier_database.dart';
part '../database/pos_database_schema.dart';
part '../database/pos_database_migrations.dart';
part '../database/pos_sales_database.dart';
part '../database/pos_operations_database.dart';

class PosLocalDatabase
    with
        PosSalesDatabaseMixin,
        PosOperationsDatabaseMixin,
        PosSupplierDatabaseMixin,
        PosAccountingDatabaseMixin {
  PosLocalDatabase();

  static final PosLocalDatabase instance = PosLocalDatabase();

  Database? _database;

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'pos_local_storage.db');
    _database = await openDatabase(
      path,
      version: 32,
      onCreate: _createPosDatabaseTables,
      onUpgrade: _upgradePosDatabase,
      onOpen: _onOpenPosDatabase,
    );
    return _database!;
  }
}
