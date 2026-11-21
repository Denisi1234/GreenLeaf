import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:track_mauzo/service/pos_local_database.dart';

import 'test_database_schema.dart';

/// A [PosLocalDatabase] backed by a private in-memory SQLite database.
///
/// Extension methods in [PosLocalDatabase] (accounting and suppliers) call the
/// `database` getter directly, so overriding the getter is enough to isolate
/// every test without touching the on-device database file.
class MemoryPosLocalDatabase extends PosLocalDatabase {
  Database? _db;

  @override
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
    );
    for (final statement in testDatabaseSchema) {
      await db.execute(statement);
    }
    return db;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
