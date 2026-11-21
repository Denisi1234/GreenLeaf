part of '../service/pos_local_database.dart';

mixin PosSupplierDatabaseMixin {
  Future<Database> get database;

  Future<List<Map<String, Object?>>> loadSuppliers(String storeId) async {
    final db = await database;
    return db.query('suppliers',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
        orderBy: 'name ASC');
  }

  Future<int> insertSupplier(
      Map<String, Object?> supplier, String storeId) async {
    final db = await database;
    return db.insert('suppliers', {...supplier, 'store_id': storeId});
  }

  Future<void> updateSupplier(int id, Map<String, Object?> supplier) async {
    final db = await database;
    final data = Map<String, Object?>.from(supplier)..remove('id');
    await db
        .update('suppliers', data, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Map<String, Object?>>> loadReceivings(String storeId) async {
    final db = await database;
    return db.query('receivings',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
        orderBy: 'date DESC');
  }

  Future<List<Map<String, Object?>>> loadReceivingLines(
      String storeId, int receivingId) async {
    final db = await database;
    return db.query('receiving_lines',
        where: 'store_id = ? AND receiving_id = ?',
        whereArgs: <Object?>[storeId, receivingId]);
  }

  Future<int> insertReceiving(
      Map<String, Object?> receiving, String storeId) async {
    final db = await database;
    return db.insert('receivings', {...receiving, 'store_id': storeId});
  }

  Future<void> insertReceivingLines(
      List<Map<String, Object?>> lines, String storeId) async {
    if (lines.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final line in lines) {
      batch.insert('receiving_lines', {...line, 'store_id': storeId});
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteReceiving(int id) async {
    final db = await database;
    await db.delete('receiving_lines',
        where: 'receiving_id = ?', whereArgs: <Object?>[id]);
    await db.delete('receivings', where: 'id = ?', whereArgs: <Object?>[id]);
  }


}
