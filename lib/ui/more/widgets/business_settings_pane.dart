import 'package:flutter/material.dart';

import '../store_profile_page.dart';

/// Clean native Android/iOS Business settings pane.
class BusinessSettingsPane extends StatelessWidget {
  const BusinessSettingsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoreProfileForm(showOperations: true);
  }
}
