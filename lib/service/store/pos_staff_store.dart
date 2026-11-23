part of '../pos_local_store.dart';

/// Staff roles, members and permission helpers for [PosLocalStore].
mixin PosStaffStore on ChangeNotifier {
  String get _activeStoreId;
  PosLocalDatabase get _database;
  List<StaffRoleData> get _staffRoles;
  List<StaffMemberData> get _staffMembers;
  PhpApiClient? get cloudApi;
  bool hasPermission(String permission);
  StaffMemberData? get currentUser;
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
  });

  List<StaffMemberData> staffMembersForRole(String roleId) {
    return _staffMembers.where((staff) => staff.roleId == roleId).toList();
  }

  Future<StaffRoleData> saveStaffRole(StaffRoleData role) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    final existingIndex = _staffRoles.indexWhere((item) => item.id == role.id);
    final nextRole = existingIndex == -1
        ? role.copyWith(sortOrder: _staffRoles.length)
        : role.copyWith(sortOrder: _staffRoles[existingIndex].sortOrder);
    if (existingIndex == -1) {
      _staffRoles.add(nextRole);
    } else {
      _staffRoles[existingIndex] = nextRole;
    }
    _staffRoles.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
    await _database.upsertStaffRole(
      _staffRoleToMap(nextRole),
      _activeStoreId,
    );
    return nextRole;
  }

  Future<void> updateStaffRolePermissions(
    String roleId,
    List<String> permissions,
  ) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    final index = _staffRoles.indexWhere((role) => role.id == roleId);
    if (index == -1) return;
    final oldRole = _staffRoles[index];
    _staffRoles[index] = oldRole.copyWith(
      permissions: List<String>.from(permissions),
    );
    notifyListeners();
    await _database.upsertStaffRole(
      _staffRoleToMap(_staffRoles[index]),
      _activeStoreId,
    );
    unawaited(
      recordAuditEvent(
        module: AuditModule.staff,
        action: 'staff.permissions_updated',
        severity: AuditSeverity.critical,
        entityType: 'Staff Role',
        entityId: roleId,
        entityLabel: oldRole.title,
        summary: 'Updated permissions for role ${oldRole.title}',
        beforeValues: {'Permissions': oldRole.permissions.join(', ')},
        afterValues: {'Permissions': permissions.join(', ')},
      ),
    );
  }

  Future<void> deleteStaffRole(String roleId) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    if (_staffMembers.any((staff) => staff.roleId == roleId)) return;
    StaffRoleData? removed;
    for (final role in _staffRoles) {
      if (role.id == roleId) {
        removed = role;
        break;
      }
    }
    _staffRoles.removeWhere((role) => role.id == roleId);
    notifyListeners();
    await _database.deleteStaffRoleRecord(roleId, _activeStoreId);
    unawaited(
      recordAuditEvent(
        module: AuditModule.staff,
        action: 'staff.role_deleted',
        severity: AuditSeverity.critical,
        entityType: 'Staff Role',
        entityId: roleId,
        entityLabel: removed?.title ?? roleId,
        summary: 'Deleted staff role ${removed?.title ?? roleId}',
      ),
    );
  }

  Future<StaffMemberData> saveStaffMember(StaffMemberData staff,
      {String? cloudPassword}) async {
    final existingIndex =
        _staffMembers.indexWhere((item) => item.id == staff.id);
    final previous = existingIndex == -1 ? null : _staffMembers[existingIndex];
    final isSelf = existingIndex != -1 &&
        staff.id == currentUser?.id &&
        staff.roleId == _staffMembers[existingIndex].roleId;
    if (!isSelf && !hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    final nextStaff = existingIndex == -1
        ? staff
        : staff.copyWith(createdAt: _staffMembers[existingIndex].createdAt);
    final nextMembers = List<StaffMemberData>.from(_staffMembers);
    if (existingIndex == -1) {
      nextMembers.insert(0, nextStaff);
    } else {
      nextMembers[existingIndex] = nextStaff;
    }
    await _database.saveStaffRecord(
      {..._staffMemberToMap(nextStaff), 'store_id': _activeStoreId},
      cloudPassword,
    );
    _staffMembers
      ..clear()
      ..addAll(nextMembers);
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.staff,
        action: previous == null ? 'staff.added' : 'staff.updated',
        severity: AuditSeverity.info,
        entityType: 'Staff Member',
        entityId: nextStaff.id,
        entityLabel: nextStaff.name,
        summary: previous == null
            ? 'Added staff member ${nextStaff.name} (${nextStaff.phone})'
            : 'Updated profile for ${nextStaff.name}',
        beforeValues: previous == null
            ? const <String, String>{}
            : {
                'Name': previous.name,
                'Role ID': previous.roleId,
                'Phone': previous.phone,
                'Status': previous.status.name,
              },
        afterValues: {
          'Name': nextStaff.name,
          'Role ID': nextStaff.roleId,
          'Phone': nextStaff.phone,
          'Status': nextStaff.status.name,
        },
      ),
    );
    return nextStaff;
  }

  Future<StaffMemberData> addStaffMember({
    required String name,
    required String email,
    required String phone,
    required String roleId,
    String username = '',
    String? password,
    String employeeNumber = '',
    String jobTitle = '',
    String department = '',
    String hireDate = '',
    String employmentType = '',
    double hourlyRate = 0,
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    String emergencyContactRelation = '',
    String address = '',
    String notes = '',
    String? avatarPath,
    StaffStatus status = StaffStatus.active,
  }) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    final now = DateTime.now().toIso8601String();
    final credentials = password == null || password.isEmpty
        ? (hash: '', salt: '')
        : _hashPassword(password);

    return saveStaffMember(
      StaffMemberData(
        id: 'staff-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32).toRadixString(16)}',
        name: name,
        email: email,
        phone: phone,
        roleId: roleId,
        createdAt: now,
        username: username,
        passwordHash: credentials.hash,
        passwordSalt: credentials.salt,
        employeeNumber: employeeNumber,
        jobTitle: jobTitle,
        department: department,
        hireDate: hireDate,
        employmentType: employmentType,
        hourlyRate: hourlyRate,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        emergencyContactRelation: emergencyContactRelation,
        address: address,
        notes: notes,
        avatarPath: avatarPath,
        status: status,
        updatedAt: now,
      ),
      cloudPassword: password,
    );
  }

  Future<StaffMemberData> updateStaffMember(
    StaffMemberData member, {
    String? newPassword,
  }) async {
    var next = member;
    if (newPassword != null && newPassword.isNotEmpty) {
      final credentials = _hashPassword(newPassword);
      next = next.copyWith(
        passwordHash: credentials.hash,
        passwordSalt: credentials.salt,
      );
    }
    next = next.copyWith(updatedAt: DateTime.now().toIso8601String());
    return saveStaffMember(next, cloudPassword: newPassword);
  }

  Future<void> setStaffStatus(String staffId, StaffStatus status) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    final index = _staffMembers.indexWhere((staff) => staff.id == staffId);
    if (index == -1) return;
    final target = _staffMembers[index];
    await saveStaffMember(target.copyWith(
      status: status,
      updatedAt: DateTime.now().toIso8601String(),
    ));
    unawaited(
      recordAuditEvent(
        module: AuditModule.staff,
        action: 'staff.status_changed',
        severity: AuditSeverity.warning,
        entityType: 'Staff Member',
        entityId: staffId,
        entityLabel: target.name,
        summary:
            'Changed ${target.name} status from ${target.status.name} to ${status.name}',
        beforeValues: {'Status': target.status.name},
        afterValues: {'Status': status.name},
      ),
    );
  }

  bool staffUsernameExists(String username, {String? excludingId}) {
    final needle = username.trim().toLowerCase();
    if (needle.isEmpty) return false;
    for (final staff in _staffMembers) {
      if (staff.id == excludingId) continue;
      if (staff.username.trim().toLowerCase() == needle) return true;
    }
    return false;
  }

  bool staffEmployeeNumberExists(String employeeNumber, {String? excludingId}) {
    final needle = employeeNumber.trim().toLowerCase();
    if (needle.isEmpty) return false;
    for (final staff in _staffMembers) {
      if (staff.id == excludingId) continue;
      if (staff.employeeNumber.trim().toLowerCase() == needle) return true;
    }
    return false;
  }

  ({String hash, String salt}) _hashPassword(String password) {
    return StaffCredentials.hashPassword(password);
  }

  Future<void> updateStaffMemberRole(String staffId, String roleId) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    final index = _staffMembers.indexWhere((staff) => staff.id == staffId);
    if (index == -1) return;
    await saveStaffMember(_staffMembers[index].copyWith(roleId: roleId));
  }

  Future<void> deleteStaffMember(String staffId) async {
    if (!hasPermission('Manage Staff')) {
      throw StateError('You do not have permission to manage staff.');
    }
    StaffMemberData? removed;
    for (final s in _staffMembers) {
      if (s.id == staffId) {
        removed = s;
        break;
      }
    }
    await _database.deleteStaffMember(staffId);
    _staffMembers.removeWhere((staff) => staff.id == staffId);
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.staff,
        action: 'staff.deleted',
        severity: AuditSeverity.critical,
        entityType: 'Staff Member',
        entityId: staffId,
        entityLabel: removed?.name ?? staffId,
        summary: 'Removed staff member ${removed?.name ?? staffId}',
      ),
    );
  }

  Map<String, Object?> _staffRoleToMap(StaffRoleData role) {
    return <String, Object?>{
      'id': role.id,
      'title': role.title,
      'subtitle': role.subtitle,
      'permissions_json': jsonEncode(role.permissions),
      'sort_order': role.sortOrder,
    };
  }

  StaffRoleData _staffRoleFromMap(Map<String, Object?> map) {
    final permissions =
        jsonDecode(map['permissions_json'] as String? ?? '[]') as List<dynamic>;
    return StaffRoleData(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      permissions: permissions.map((item) => item.toString()).toList(),
      sortOrder: (map['sort_order'] as num).toInt(),
    );
  }

  Map<String, Object?> _staffMemberToMap(StaffMemberData staff) {
    return <String, Object?>{
      'id': staff.id,
      'name': staff.name,
      'email': staff.email,
      'phone': staff.phone,
      'role_id': staff.roleId,
      'created_at': staff.createdAt,
      'username': staff.username,
      'password_hash': staff.passwordHash,
      'password_salt': staff.passwordSalt,
      'employee_number': staff.employeeNumber,
      'job_title': staff.jobTitle,
      'department': staff.department,
      'hire_date': staff.hireDate,
      'employment_type': staff.employmentType,
      'hourly_rate': staff.hourlyRate,
      'emergency_contact_name': staff.emergencyContactName,
      'emergency_contact_phone': staff.emergencyContactPhone,
      'emergency_contact_relation': staff.emergencyContactRelation,
      'address': staff.address,
      'notes': staff.notes,
      'avatar_path': staff.avatarPath,
      'status': staff.status.value,
      'updated_at': staff.updatedAt,
    };
  }

  StaffMemberData _staffMemberFromMap(Map<String, Object?> map) {
    return StaffMemberData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      roleId: map['role_id'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      username: map['username'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      passwordSalt: map['password_salt'] as String? ?? '',
      employeeNumber: map['employee_number'] as String? ?? '',
      jobTitle: map['job_title'] as String? ?? '',
      department: map['department'] as String? ?? '',
      hireDate: map['hire_date'] as String? ?? '',
      employmentType: map['employment_type'] as String? ?? '',
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble() ?? 0,
      emergencyContactName: map['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: map['emergency_contact_phone'] as String? ?? '',
      emergencyContactRelation:
          map['emergency_contact_relation'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      avatarPath: map['avatar_path'] as String?,
      status: StaffStatus.fromValue(map['status'] as String?),
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
