part of '../service/pos_local_database.dart';

mixin PosAccountingDatabaseMixin {
  Future<Database> get database;

  Future<List<Map<String, Object?>>> loadAccounts(String storeId) async {
    final db = await database;
    return db.query('accounts',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
        orderBy: 'code ASC');
  }

  Future<int> insertAccount(
      Map<String, Object?> account, String storeId) async {
    final db = await database;
    return db.insert('accounts', {...account, 'store_id': storeId});
  }

  Future<void> updateAccount(int id, Map<String, Object?> account) async {
    final db = await database;
    final data = Map<String, Object?>.from(account)..remove('id');
    await db
        .update('accounts', data, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Map<String, Object?>>> loadJournalEntries(String storeId) async {
    final db = await database;
    return db.query('journal_entries',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
        orderBy: 'date DESC');
  }

  Future<List<Map<String, Object?>>> loadJournalLines(
      String storeId, int entryId) async {
    final db = await database;
    return db.query('journal_lines',
        where: 'store_id = ? AND entry_id = ?',
        whereArgs: <Object?>[storeId, entryId]);
  }

  Future<int> insertJournalEntry(
      Map<String, Object?> entry, String storeId) async {
    final db = await database;
    return db.insert('journal_entries', {...entry, 'store_id': storeId});
  }

  Future<void> insertJournalLines(
      List<Map<String, Object?>> lines, String storeId) async {
    if (lines.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final line in lines) {
      batch.insert('journal_lines', {...line, 'store_id': storeId});
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteJournalEntry(int id) async {
    final db = await database;
    await db.delete('journal_lines',
        where: 'entry_id = ?', whereArgs: <Object?>[id]);
    await db
        .delete('journal_entries', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Map<String, Object?>>> loadFixedAssets(String storeId) async {
    final db = await database;
    return db.query('fixed_assets',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
        orderBy: 'purchase_date DESC');
  }

  Future<int> insertFixedAsset(
      Map<String, Object?> asset, String storeId) async {
    final db = await database;
    return db.insert('fixed_assets', {...asset, 'store_id': storeId});
  }

  Future<void> updateFixedAsset(int id, Map<String, Object?> asset) async {
    final db = await database;
    final data = Map<String, Object?>.from(asset)..remove('id');
    await db.update('fixed_assets', data,
        where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteFixedAsset(int id) async {
    final db = await database;
    await db.delete('fixed_assets', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Map<String, Object?>>> loadBankTransactions(
      String storeId) async {
    final db = await database;
    return db.query('bank_transactions',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
        orderBy: 'date DESC');
  }

  Future<int> insertBankTransaction(
      Map<String, Object?> entry, String storeId) async {
    final db = await database;
    return db.insert('bank_transactions', {...entry, 'store_id': storeId});
  }

  Future<void> updateBankTransaction(int id, Map<String, Object?> entry) async {
    final db = await database;
    await db.update('bank_transactions', entry,
        where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteBankTransaction(int id) async {
    final db = await database;
    await db
        .delete('bank_transactions', where: 'id = ?', whereArgs: <Object?>[id]);
  }


}
