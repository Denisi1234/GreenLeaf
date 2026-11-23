import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

enum AuditModule {
  sales('sales', 'Sales', 'Mauzo', Icons.point_of_sale_outlined),
  inventory('inventory', 'Inventory', 'Stoo', Icons.inventory_2_outlined),
  register(
      'register', 'Cash register', 'Kasha la pesa', Icons.payments_outlined),
  expenses('expenses', 'Expenses', 'Matumizi', Icons.receipt_outlined),
  customers(
    'customers',
    'Customers & debt',
    'Wateja na madeni',
    Icons.people_outline_rounded,
  ),
  staff('staff', 'Staff & access', 'Wafanyakazi na ruhusa', Icons.badge_outlined),
  accounting(
    'accounting',
    'Accounting',
    'Uhasibu',
    Icons.account_balance_outlined,
  ),
  settings(
    'settings',
    'Settings & security',
    'Mipangilio na usalama',
    Icons.settings_outlined,
  );

  const AuditModule(this.storageKey, this.labelEn, this.labelSw, this.icon);

  final String storageKey;
  final String labelEn;
  final String labelSw;
  final IconData icon;

  String label(bool isSwahili) => isSwahili ? labelSw : labelEn;

  static AuditModule fromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final module in AuditModule.values) {
      if (module.storageKey == normalized) return module;
    }
    return AuditModule.settings;
  }
}

enum AuditSeverity {
  info('info', 'Normal', 'Kawaida'),
  warning('warning', 'Warning', 'Tahadhari'),
  critical('critical', 'Critical', 'Muhimu');

  const AuditSeverity(this.storageKey, this.labelEn, this.labelSw);

  final String storageKey;
  final String labelEn;
  final String labelSw;

  String label(bool isSwahili) => isSwahili ? labelSw : labelEn;

  static AuditSeverity fromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final level in AuditSeverity.values) {
      if (level.storageKey == normalized) return level;
    }
    return AuditSeverity.info;
  }
}

/// Immutable, hash-chained audit trail record stored in SQLite.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.storeId,
    required this.sequence,
    required this.timestamp,
    required this.module,
    required this.action,
    required this.severity,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.summary,
    required this.beforeValues,
    required this.afterValues,
    required this.metadata,
    required this.prevHash,
    required this.entryHash,
  });

  static const String genesisHash = 'GENESIS';

  final String id;
  final String storeId;
  final int sequence;
  final DateTime timestamp;
  final AuditModule module;
  final String action;
  final AuditSeverity severity;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String entityType;
  final String entityId;
  final String entityLabel;
  final String summary;
  final Map<String, String> beforeValues;
  final Map<String, String> afterValues;
  final Map<String, String> metadata;
  final String prevHash;
  final String entryHash;

  bool get isSelfHashValid =>
      entryHash.isNotEmpty &&
      computeHash(
            id: id,
            storeId: storeId,
            sequence: sequence,
            timestampIso: timestamp.toIso8601String(),
            module: module.storageKey,
            action: action,
            severity: severity.storageKey,
            actorId: actorId,
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
          ) ==
          entryHash;

  bool get hasDiff => beforeValues.isNotEmpty || afterValues.isNotEmpty;

  List<String> get changedKeys {
    final ordered = <String>[];
    for (final key in beforeValues.keys) {
      if (!ordered.contains(key)) ordered.add(key);
    }
    for (final key in afterValues.keys) {
      if (!ordered.contains(key)) ordered.add(key);
    }
    return ordered;
  }

  String actionTitle(bool isSwahili) {
    final en = _actionLabelsEn[action];
    final sw = _actionLabelsSw[action];
    if (isSwahili && sw != null) return sw;
    if (en != null) return en;
    return action
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .trim();
  }

  static String computeHash({
    required String id,
    required String storeId,
    required int sequence,
    required String timestampIso,
    required String module,
    required String action,
    required String severity,
    required String actorId,
    required String actorName,
    required String actorRole,
    required String entityType,
    required String entityId,
    required String entityLabel,
    required String summary,
    required Map<String, String> beforeValues,
    required Map<String, String> afterValues,
    required Map<String, String> metadata,
    required String prevHash,
  }) {
    final canonical = <String, Object?>{
      'id': id,
      'store_id': storeId,
      'sequence': sequence,
      'timestamp': timestampIso,
      'module': module,
      'action': action,
      'severity': severity,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_role': actorRole,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_label': entityLabel,
      'summary': summary,
      'before': _sortedMap(beforeValues),
      'after': _sortedMap(afterValues),
      'metadata': _sortedMap(metadata),
      'prev_hash': prevHash,
    };
    final digest = sha256.convert(utf8.encode(jsonEncode(canonical)));
    return digest.toString();
  }

  static Map<String, String> _sortedMap(Map<String, String> input) {
    if (input.isEmpty) return const <String, String>{};
    final keys = input.keys.toList()..sort();
    return <String, String>{
      for (final key in keys) key: input[key]!,
    };
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'store_id': storeId,
      'sequence': sequence,
      'timestamp': timestamp.toIso8601String(),
      'module': module.storageKey,
      'action': action,
      'severity': severity.storageKey,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_role': actorRole,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_label': entityLabel,
      'summary': summary,
      'before_json': jsonEncode(_sortedMap(beforeValues)),
      'after_json': jsonEncode(_sortedMap(afterValues)),
      'metadata_json': jsonEncode(_sortedMap(metadata)),
      'prev_hash': prevHash,
      'entry_hash': entryHash,
    };
  }

  factory AuditLogEntry.fromMap(Map<String, Object?> map) {
    final tsRaw = map['timestamp'] as String? ?? '';
    return AuditLogEntry(
      id: map['id'] as String? ?? '',
      storeId: map['store_id'] as String? ?? 'store-default',
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(tsRaw) ?? DateTime.now(),
      module: AuditModule.fromKey(map['module'] as String? ?? ''),
      action: map['action'] as String? ?? '',
      severity: AuditSeverity.fromKey(map['severity'] as String? ?? 'info'),
      actorId: map['actor_id'] as String? ?? '',
      actorName: map['actor_name'] as String? ?? 'Owner',
      actorRole: map['actor_role'] as String? ?? 'Owner',
      entityType: map['entity_type'] as String? ?? '',
      entityId: map['entity_id'] as String? ?? '',
      entityLabel: map['entity_label'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      beforeValues: _decodeStringMap(map['before_json'] as String?),
      afterValues: _decodeStringMap(map['after_json'] as String?),
      metadata: _decodeStringMap(map['metadata_json'] as String?),
      prevHash: map['prev_hash'] as String? ?? genesisHash,
      entryHash: map['entry_hash'] as String? ?? '',
    );
  }

  static Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, String>{};
      return <String, String>{
        for (final entry in decoded.entries)
          entry.key.toString(): entry.value?.toString() ?? '',
      };
    } catch (_) {
      return const <String, String>{};
    }
  }

  static const Map<String, String> _actionLabelsEn = {
    'sale.completed': 'Sale completed',
    'sale.voided': 'Sale voided',
    'sale.reopened': 'Sale reopened for edit',
    'inventory.added': 'Product added',
    'inventory.updated': 'Product updated',
    'inventory.deleted': 'Product deleted',
    'inventory.stock_adjusted': 'Stock adjusted',
    'receiving.recorded': 'Goods received',
    'receiving.deleted': 'Receiving deleted',
    'register.shift_opened': 'Register shift opened',
    'register.shift_closed': 'Register shift closed',
    'register.shift_reopened': 'Register shift reopened',
    'register.cash_movement_added': 'Cash drawer movement',
    'register.cash_movement_deleted': 'Cash movement deleted',
    'expense.added': 'Expense recorded',
    'expense.updated': 'Expense updated',
    'expense.deleted': 'Expense deleted',
    'debit.payment_recorded': 'Debt payment recorded',
    'customer.deleted': 'Customer deleted',
    'debit.entry_deleted': 'Debit entry deleted',
    'debit.cleared_all': 'All debit ledgers cleared',
    'staff.added': 'Staff member added',
    'staff.updated': 'Staff profile updated',
    'staff.permissions_updated': 'Role permissions updated',
    'staff.status_changed': 'Staff status changed',
    'staff.deleted': 'Staff member removed',
    'staff.role_deleted': 'Staff role deleted',
    'auth.login_success': 'User signed in',
    'auth.login_failed': 'Failed sign-in attempt',
    'auth.password_changed': 'Password changed',
    'auth.logout': 'User signed out',
    'accounting.journal_saved': 'Journal entry posted',
    'accounting.journal_deleted': 'Journal entry deleted',
    'accounting.account_deleted': 'Account deleted',
    'settings.tax_updated': 'Tax settings updated',
    'settings.receipt_updated': 'Receipt settings updated',
    'settings.profile_updated': 'Store profile updated',
    'store.saved': 'Store saved',
    'store.deleted': 'Store deleted',
    'store.switched': 'Active store switched',
  };

  static const Map<String, String> _actionLabelsSw = {
    'sale.completed': 'Mauzo yamekamilika',
    'sale.voided': 'Mauzo yamefutwa',
    'sale.reopened': 'Mauzo yamefunguliwa kuhariri',
    'inventory.added': 'Bidhaa imeongezwa',
    'inventory.updated': 'Bidhaa imehaririwa',
    'inventory.deleted': 'Bidhaa imefutwa',
    'inventory.stock_adjusted': 'Idadi ya stoo imebadilishwa',
    'receiving.recorded': 'Bidhaa zimepokelewa',
    'receiving.deleted': 'Mapokezi yamefutwa',
    'register.shift_opened': 'Zamu ya kasha imefunguliwa',
    'register.shift_closed': 'Zamu ya kasha imefungwa',
    'register.shift_reopened': 'Zamu ya kasha imefunguliwa tena',
    'register.cash_movement_added': 'Muamala wa kasha la pesa',
    'register.cash_movement_deleted': 'Muamala wa kasha umefutwa',
    'expense.added': 'Matumizi yamerekodiwa',
    'expense.updated': 'Matumizi yamehaririwa',
    'expense.deleted': 'Matumizi yamefutwa',
    'debit.payment_recorded': 'Malipo ya deni yamerekodiwa',
    'customer.deleted': 'Mteja amefutwa',
    'debit.entry_deleted': 'Kumbukumbu ya deni imefutwa',
    'debit.cleared_all': 'Madeni yote yamefutwa',
    'staff.added': 'Mfanyakazi ameongezwa',
    'staff.updated': 'Taarifa za mfanyakazi zimebadilishwa',
    'staff.permissions_updated': 'Ruhusa za cheo zimebadilishwa',
    'staff.status_changed': 'Hali ya mfanyakazi imebadilishwa',
    'staff.deleted': 'Mfanyakazi ameondolewa',
    'staff.role_deleted': 'Cheo kimefutwa',
    'auth.login_success': 'Mtumiaji ameingia',
    'auth.login_failed': 'Jaribio la kuingia limeshindwa',
    'auth.password_changed': 'Nenosiri limebadilishwa',
    'auth.logout': 'Mtumiaji ametoka',
    'accounting.journal_saved': 'Kumbukumbu ya daftari imewekwa',
    'accounting.journal_deleted': 'Kumbukumbu ya daftari imefutwa',
    'accounting.account_deleted': 'Akaunti imefutwa',
    'settings.tax_updated': 'Mipangilio ya kodi imebadilishwa',
    'settings.receipt_updated': 'Mipangilio ya risiti imebadilishwa',
    'settings.profile_updated': 'Taarifa za duka zimebadilishwa',
    'store.saved': 'Duka limehifadhiwa',
    'store.deleted': 'Duka limefutwa',
    'store.switched': 'Duka la kazi limebadilishwa',
  };
}

/// Cryptographic chain verification result across stored audit records.
class AuditIntegrityReport {
  const AuditIntegrityReport({
    required this.isValid,
    required this.totalChecked,
    required this.brokenEntryIds,
    required this.lastSequence,
    required this.headHash,
    required this.checkedAt,
  });

  final bool isValid;
  final int totalChecked;
  final List<String> brokenEntryIds;
  final int lastSequence;
  final String headHash;
  final DateTime checkedAt;

  static AuditIntegrityReport verifyChain(List<AuditLogEntry> entries) {
    final now = DateTime.now();
    if (entries.isEmpty) {
      return AuditIntegrityReport(
        isValid: true,
        totalChecked: 0,
        brokenEntryIds: const <String>[],
        lastSequence: 0,
        headHash: AuditLogEntry.genesisHash,
        checkedAt: now,
      );
    }

    final sorted = List<AuditLogEntry>.from(entries)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final broken = <String>[];
    String expectedPrevHash = AuditLogEntry.genesisHash;
    int? prevSeq;

    for (var i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      final sequenceGap = prevSeq != null && item.sequence != prevSeq + 1;
      final linkBroken = item.prevHash != expectedPrevHash;
      final hashBroken = !item.isSelfHashValid;
      if (sequenceGap || linkBroken || hashBroken) {
        broken.add(item.id);
      }
      expectedPrevHash = item.entryHash;
      prevSeq = item.sequence;
    }

    final last = sorted.last;
    return AuditIntegrityReport(
      isValid: broken.isEmpty,
      totalChecked: sorted.length,
      brokenEntryIds: List.unmodifiable(broken),
      lastSequence: last.sequence,
      headHash: last.entryHash,
      checkedAt: now,
    );
  }
}
