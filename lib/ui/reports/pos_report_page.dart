import 'package:flutter/material.dart';

import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';

class PosReportPage extends StatefulWidget {
  const PosReportPage({super.key, required this.report});

  final PosReport report;

  @override
  State<PosReportPage> createState() => _PosReportPageState();
}

class _PosReportPageState extends State<PosReportPage> {
  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(report: widget.report);
  }
}
