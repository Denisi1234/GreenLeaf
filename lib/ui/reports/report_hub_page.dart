import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'reports_catalog_page.dart';

class ReportHubPage extends StatelessWidget {
  const ReportHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: theme,
      child: const ReportsCatalogPage(embedded: true),
    );
  }
}
