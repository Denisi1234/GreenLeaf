import 'package:flutter/material.dart';

import '../pos_report_catalog.dart';
import '../pos_report_page.dart';

class BaseReportPage extends StatelessWidget {
  const BaseReportPage({
    super.key,
    required this.report,
  });

  final PosReport report;

  @override
  Widget build(BuildContext context) {
    return PosReportPage(report: report);
  }
}