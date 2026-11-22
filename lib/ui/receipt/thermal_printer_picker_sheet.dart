import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../service/thermal_printer_service.dart';
import '../widgets/app_design.dart';

/// Lists paired Bluetooth thermal printers and lets the cashier pick one.
Future<BluetoothPrinterDevice?> showThermalPrinterPicker(
  BuildContext context,
) async {
  return showModalBottomSheet<BluetoothPrinterDevice>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const _ThermalPrinterPickerSheet(),
  );
}

class _ThermalPrinterPickerSheet extends StatefulWidget {
  const _ThermalPrinterPickerSheet();

  @override
  State<_ThermalPrinterPickerSheet> createState() =>
      _ThermalPrinterPickerSheetState();
}

class _ThermalPrinterPickerSheetState
    extends State<_ThermalPrinterPickerSheet> {
  late Future<List<BluetoothPrinterDevice>> _future;

  @override
  void initState() {
    super.initState();
    _future = ThermalPrinterService.instance.listPairedPrinters();
  }

  void _reload() {
    setState(() {
      _future = ThermalPrinterService.instance.listPairedPrinters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Select Bluetooth printer'),
                    style: AppTypography.sectionHeader,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Refresh'),
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Pair your 58mm or 80mm thermal printer in Android Bluetooth settings first.',
              ),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<BluetoothPrinterDevice>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      snapshot.error.toString(),
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.dangerDeep),
                    ),
                  );
                }
                final printers = snapshot.data ?? const [];
                if (printers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      context.tr('No paired Bluetooth printers found.'),
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: printers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = printers[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.print_outlined),
                        title: Text(
                          device.name.isEmpty ? device.address : device.name,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          device.address,
                          style: AppTypography.caption,
                        ),
                        onTap: () => Navigator.of(context).pop(device),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
