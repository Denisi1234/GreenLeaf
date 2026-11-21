import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:track_mauzo/service/php_api_client.dart';
import 'package:track_mauzo/service/pos_hybrid_database.dart';

import 'test_database_schema.dart';

/// A [PosHybridDatabase] backed by a private in-memory SQLite database.
class TestHybridDatabase extends PosHybridDatabase {
  TestHybridDatabase(super.api);

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

/// An in-memory [PhpApiClient] that records calls and can simulate failures.
class FakePhpApiClient extends PhpApiClient {
  FakePhpApiClient() : super('http://test.local');

  final List<FakeRequest> requests = <FakeRequest>[];
  final List<FakeReplace> replaces = <FakeReplace>[];
  final List<String> deleted = <String>[];
  final List<String> rowRequests = <String>[];
  final List<String> uploadedImages = <String>[];

  Map<String, List<Map<String, Object?>>> rowsByResource =
      <String, List<Map<String, Object?>>>{};

  int replaceFailures = 0;
  int replaceFailStatus = 409;
  int requestFailures = 0;
  int requestFailStatus = 422;

  final List<String> _errors = <String>[];

  List<String> get errors => List.unmodifiable(_errors);

  @override
  Future<List<Map<String, Object?>>> rows(String resource) async {
    rowRequests.add(resource);
    return rowsByResource[resource] ?? const <Map<String, Object?>>[];
  }

  @override
  Future<void> replace(
    String resource,
    List<Map<String, Object?>> items, {
    String? idempotencyKey,
  }) async {
    replaces.add(FakeReplace(resource, items));
    if (replaceFailures > 0) {
      replaceFailures--;
      throw ApiException('simulated replace failure', replaceFailStatus);
    }
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? versionResource,
    String? idempotencyKey,
    bool bypassCircuit = false,
  }) async {
    requests.add(FakeRequest(method, path, body));
    if (requestFailures > 0) {
      requestFailures--;
      throw ApiException('simulated request failure', requestFailStatus);
    }
    return <String, dynamic>{'data': <String, dynamic>{}};
  }

  @override
  Future<void> put(
    String resource,
    String id,
    Map<String, Object?> row, {
    String? idempotencyKey,
  }) async {
    requests.add(FakeRequest('PUT', '$resource/$id', row));
    if (requestFailures > 0) {
      requestFailures--;
      throw ApiException('simulated put failure', requestFailStatus);
    }
  }

  @override
  Future<void> delete(
    String resource,
    String id, {
    String? idempotencyKey,
  }) async {
    deleted.add('$resource/$id');
    if (requestFailures > 0) {
      requestFailures--;
      throw ApiException('simulated delete failure', requestFailStatus);
    }
  }

  @override
  Future<String?> uploadImage(String? path) async {
    if (path == null || path.isEmpty) return path;
    uploadedImages.add(path);
    return 'http://test.local/uploads/$path';
  }

  void recordError(String error) => _errors.add(error);
}

class FakeRequest {
  const FakeRequest(this.method, this.path, this.body);

  final String method;
  final String path;
  final Map<String, Object?>? body;

  Map<String, Object?> get payload => body ?? const <String, Object?>{};

  @override
  String toString() => '$method $path';
}

class FakeReplace {
  const FakeReplace(this.resource, this.items);

  final String resource;
  final List<Map<String, Object?>> items;
}
