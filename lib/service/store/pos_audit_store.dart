part of '../pos_local_store.dart';

/// Append-only tamper-evident audit & activity trail for [PosLocalStore].
mixin PosAuditStore on ChangeNotifier {
  static const int _maxInMemoryLogs = 2000;

  String get _activeStoreId;
  PosLocalDatabase get _database;
  List<AuditLogEntry> get _auditLogs;
  bool get _disposed;
  StaffMemberData? get currentUser;
  StaffRoleData? staffRoleById(String roleId);
  PhpApiClient? get cloudApi;
  AppProfileData get profile;

  List<AuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);

  List<String> get auditActors {
    final actors = <String>{};
    for (final entry in _auditLogs) {
      final name = entry.actorName.trim();
      if (name.isNotEmpty) actors.add(name);
    }
    final list = actors.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List.unmodifiable(list);
  }

  AuditIntegrityReport verifyAuditIntegrity() =>
      AuditIntegrityReport.verifyChain(_auditLogs);

  List<AuditLogEntry> queryAuditLogs({
    String query = '',
    AuditModule? module,
    AuditSeverity? severity,
    String? actorName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final needle = query.trim().toLowerCase();
    final actorFilter = actorName?.trim();
    final start = startDate == null
        ? null
        : DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate == null
        ? null
        : DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    return _auditLogs.where((entry) {
      if (module != null && entry.module != module) return false;
      if (severity != null && entry.severity != severity) return false;
      if (actorFilter != null &&
          actorFilter.isNotEmpty &&
          entry.actorName != actorFilter) {
        return false;
      }
      if (start != null && entry.timestamp.isBefore(start)) return false;
      if (end != null && entry.timestamp.isAfter(end)) return false;
      if (needle.isNotEmpty) {
        final haystack = <String>[
          entry.action,
          entry.actionTitle(false),
          entry.actionTitle(true),
          entry.actorName,
          entry.actorRole,
          entry.entityType,
          entry.entityId,
          entry.entityLabel,
          entry.summary,
          entry.beforeValues.values.join(' '),
          entry.afterValues.values.join(' '),
        ].join(' ').toLowerCase();
        if (!haystack.contains(needle)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<void> _reloadAuditLogs() async {
    if (_disposed) return;
    try {
      final rows = await _database.loadAuditLogs(_activeStoreId);
      if (_disposed) return;
      _auditLogs
        ..clear()
        ..addAll(
          rows.map(
            (row) => AuditLogEntry.fromMap(Map<String, Object?>.from(row)),
          ),
        );
      _auditLogs.sort((a, b) => b.sequence.compareTo(a.sequence));
    } catch (_) {
      // Keep running safely if storage is unavailable during initialization.
    }
  }

  ({String id, String name, String role}) _resolveAuditActor({
    String? actorIdOverride,
    String? actorNameOverride,
    String? actorRoleOverride,
  }) {
    final user = currentUser;
    final resolvedId = (actorIdOverride ?? '').trim().isNotEmpty
        ? actorIdOverride!.trim()
        : (user?.id ?? (cloudApi?.user['id'] as String?) ?? 'owner');

    String resolvedName = (actorNameOverride ?? '').trim();
    if (resolvedName.isEmpty) {
      resolvedName = user?.name.trim() ?? '';
    }
    if (resolvedName.isEmpty) {
      resolvedName = (cloudApi?.user['name'] as String?)?.trim() ?? '';
    }
    if (resolvedName.isEmpty) {
      resolvedName = profile.ownerName.trim();
    }
    if (resolvedName.isEmpty) {
      resolvedName = 'Owner';
    }

    String resolvedRole = (actorRoleOverride ?? '').trim();
    if (resolvedRole.isEmpty && user != null) {
      resolvedRole = staffRoleById(user.roleId)?.title.trim() ?? '';
    }
    if (resolvedRole.isEmpty) {
      resolvedRole = profile.roleTitle.trim().isNotEmpty
          ? profile.roleTitle.trim()
          : 'Owner';
    }

    return (id: resolvedId, name: resolvedName, role: resolvedRole);
  }

  Future<AuditLogEntry> recordAuditEvent({
    required AuditModule module,
    required String action,
    AuditSeverity severity = AuditSeverity.info,
    required String entityType,
    String entityId = '',
    String entityLabel = '',
    required String summary,
    Map<String, String> beforeValues = const <String, String>{},
    Map<String, String> afterValues = const <String, String>{},
    Map<String, String> metadata = const <String, String>{},
    String? actorIdOverride,
    String? actorNameOverride,
    String? actorRoleOverride,
  }) async {
    int prevSeq = 0;
    String prevHash = AuditLogEntry.genesisHash;
    if (_auditLogs.isNotEmpty) {
      prevSeq = _auditLogs.first.sequence;
      prevHash = _auditLogs.first.entryHash.isNotEmpty
          ? _auditLogs.first.entryHash
          : AuditLogEntry.genesisHash;
    } else if (!_disposed) {
      try {
        final latest = await _database.loadLatestAuditLog(_activeStoreId);
        if (latest != null) {
          prevSeq = (latest['sequence'] as num?)?.toInt() ?? 0;
          final rawHash = latest['entry_hash'] as String?;
          if (rawHash != null && rawHash.isNotEmpty) {
            prevHash = rawHash;
          }
        }
      } catch (_) {}
    }

    final actor = _resolveAuditActor(
      actorIdOverride: actorIdOverride,
      actorNameOverride: actorNameOverride,
      actorRoleOverride: actorRoleOverride,
    );
    final now = DateTime.now();
    final seq = prevSeq + 1;
    final id =
        'AUD-$seq-${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 16).toRadixString(16)}';
    final timestampIso = now.toIso8601String();
    final entryHash = AuditLogEntry.computeHash(
      id: id,
      storeId: _activeStoreId,
      sequence: seq,
      timestampIso: timestampIso,
      module: module.storageKey,
      action: action,
      severity: severity.storageKey,
      actorId: actor.id,
      actorName: actor.name,
      actorRole: actor.role,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      summary: summary,
      beforeValues: beforeValues,
      afterValues: afterValues,
      metadata: metadata,
      prevHash: prevHash,
    );

    final entry = AuditLogEntry(
      id: id,
      storeId: _activeStoreId,
      sequence: seq,
      timestamp: now,
      module: module,
      action: action,
      severity: severity,
      actorId: actor.id,
      actorName: actor.name,
      actorRole: actor.role,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      summary: summary,
      beforeValues: Map<String, String>.unmodifiable(beforeValues),
      afterValues: Map<String, String>.unmodifiable(afterValues),
      metadata: Map<String, String>.unmodifiable(metadata),
      prevHash: prevHash,
      entryHash: entryHash,
    );

    if (_disposed) return entry;

    _auditLogs.insert(0, entry);
    if (_auditLogs.length > _maxInMemoryLogs) {
      _auditLogs.removeRange(_maxInMemoryLogs, _auditLogs.length);
    }

    try {
      await _database.insertAuditLog(entry.toMap());
    } catch (_) {
      // Never block POS operations if audit DB insertion cannot run (e.g. mocks).
    }
    if (!_disposed) {
      notifyListeners();
    }
    return entry;
  }
}
