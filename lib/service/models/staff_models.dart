class AppProfileData {
  const AppProfileData({
    required this.storeName,
    required this.ownerName,
    required this.roleTitle,
    required this.contactNumber,
    required this.emailAddress,
    required this.physicalAddress,
    required this.memberSince,
    required this.taxId,
    required this.weekdayOpen,
    required this.weekdayClose,
    required this.saturdayOpen,
    required this.saturdayClose,
    required this.sundaySchedule,
    required this.open24Hours,
    this.logoPath,
  });

  factory AppProfileData.empty() {
    return const AppProfileData(
      storeName: '',
      ownerName: '',
      roleTitle: '',
      contactNumber: '',
      emailAddress: '',
      physicalAddress: '',
      memberSince: '',
      taxId: '',
      weekdayOpen: '',
      weekdayClose: '',
      saturdayOpen: '',
      saturdayClose: '',
      sundaySchedule: '',
      open24Hours: false,
      logoPath: null,
    );
  }

  final String storeName;
  final String ownerName;
  final String roleTitle;
  final String contactNumber;
  final String emailAddress;
  final String physicalAddress;
  final String memberSince;
  final String taxId;
  final String weekdayOpen;
  final String weekdayClose;
  final String saturdayOpen;
  final String saturdayClose;
  final String sundaySchedule;
  final bool open24Hours;
  final String? logoPath;

  /// Currency used for receipts and reports.
  String get currency => 'TSh';

  AppProfileData copyWith({
    String? storeName,
    String? ownerName,
    String? roleTitle,
    String? contactNumber,
    String? emailAddress,
    String? physicalAddress,
    String? memberSince,
    String? taxId,
    String? weekdayOpen,
    String? weekdayClose,
    String? saturdayOpen,
    String? saturdayClose,
    String? sundaySchedule,
    bool? open24Hours,
    String? logoPath,
  }) {
    return AppProfileData(
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      roleTitle: roleTitle ?? this.roleTitle,
      contactNumber: contactNumber ?? this.contactNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      memberSince: memberSince ?? this.memberSince,
      taxId: taxId ?? this.taxId,
      weekdayOpen: weekdayOpen ?? this.weekdayOpen,
      weekdayClose: weekdayClose ?? this.weekdayClose,
      saturdayOpen: saturdayOpen ?? this.saturdayOpen,
      saturdayClose: saturdayClose ?? this.saturdayClose,
      sundaySchedule: sundaySchedule ?? this.sundaySchedule,
      open24Hours: open24Hours ?? this.open24Hours,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}

class StaffRoleData {
  const StaffRoleData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.permissions,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> permissions;
  final int sortOrder;

  bool get isOwnerAdmin => id == 'role-owner' || id == 'role-admin' || title.toLowerCase() == 'owner' || title.toLowerCase() == 'admin';

  StaffRoleData copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? permissions,
    int? sortOrder,
  }) {
    return StaffRoleData(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      permissions: permissions ?? this.permissions,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum StaffStatus {
  active('active', 'Active', 'Hai'),
  onLeave('on_leave', 'On Leave', 'Likizo'),
  inactive('inactive', 'Inactive', 'Hafifu');

  const StaffStatus(this.value, this.label, this.swahiliLabel);

  final String value;
  final String label;
  final String swahiliLabel;

  String localized(bool isSwahili) => isSwahili ? swahiliLabel : label;

  static StaffStatus fromValue(String? value) {
    for (final status in StaffStatus.values) {
      if (status.value == value) return status;
    }
    return StaffStatus.active;
  }
}

enum EmploymentType {
  fullTime('full_time', 'Full-time'),
  partTime('part_time', 'Part-time'),
  contract('contract', 'Contract'),
  intern('intern', 'Intern'),
  temporary('temporary', 'Temporary');

  const EmploymentType(this.value, this.label);

  final String value;
  final String label;

  static EmploymentType? fromValue(String? value) {
    for (final type in EmploymentType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class StaffMemberData {
  const StaffMemberData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleId,
    required this.createdAt,
    this.username = '',
    this.passwordHash = '',
    this.passwordSalt = '',
    this.employeeNumber = '',
    this.jobTitle = '',
    this.department = '',
    this.hireDate = '',
    this.employmentType = '',
    this.hourlyRate = 0,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.address = '',
    this.notes = '',
    this.avatarPath,
    this.status = StaffStatus.active,
    this.updatedAt = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String roleId;
  final String createdAt;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final String employeeNumber;
  final String jobTitle;
  final String department;
  final String hireDate;
  final String employmentType;
  final double hourlyRate;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String address;
  final String notes;
  final String? avatarPath;
  final StaffStatus status;
  final String updatedAt;

  bool get hasLogin => username.trim().isNotEmpty;
  bool get hasPassword => passwordHash.isNotEmpty;
  bool get isActive => status == StaffStatus.active;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  StaffMemberData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? roleId,
    String? createdAt,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    String? employeeNumber,
    String? jobTitle,
    String? department,
    String? hireDate,
    String? employmentType,
    double? hourlyRate,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? address,
    String? notes,
    String? avatarPath,
    StaffStatus? status,
    String? updatedAt,
  }) {
    return StaffMemberData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      employmentType: employmentType ?? this.employmentType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      avatarPath: avatarPath ?? this.avatarPath,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
