import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';

String staffDual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

enum StaffStatusFilter {
  all('All', 'Zote'),
  active('Active', 'Hai'),
  onLeave('On Leave', 'Likizo'),
  inactive('Inactive', 'Hafifu');

  const StaffStatusFilter(this.label, this.swahiliLabel);

  final String label;
  final String swahiliLabel;

  String localized(AppStrings strings) =>
      strings.isSwahili ? swahiliLabel : label;
}

Color avatarColorForStaffName(String name) {
  const colors = <Color>[
    Color(0xFFF2D9D2),
    Color(0xFFF3F4F6),
    Color(0xFFF3F4F6),
    Color(0xFFF3F4F6),
    Color(0xFFF3F4F6),
  ];
  final index = name.hashCode.abs() % colors.length;
  return colors[index];
}
