import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

/// Scans barcodes via Android ML Kit Code Scanner when available, falling back
/// cleanly to a USB/Bluetooth HID keyboard scanner & manual entry dialog.
class BarcodeScanService {
  BarcodeScanService({Future<String?> Function()? scanOverride})
      : _scanOverride = scanOverride;

  static const MethodChannel _channel =
      MethodChannel('trackmauzo/barcode_scanner');

  static BarcodeScanService instance = BarcodeScanService();

  final Future<String?> Function()? _scanOverride;

  static void setTestOverride(Future<String?> Function()? handler) {
    instance = BarcodeScanService(scanOverride: handler);
  }

  static void resetForTests() {
    instance = BarcodeScanService();
  }

  Future<String?> scan(BuildContext context) async {
    final override = _scanOverride;
    if (override != null) {
      final result = await override();
      final trimmed = result?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    try {
      final result = await _channel.invokeMethod<String>('scanBarcode');
      final trimmed = result?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    } on MissingPluginException {
      if (!context.mounted) return null;
      return _showManualOrHidSheet(context);
    } on PlatformException catch (error) {
      if (error.code == 'scan_unavailable' && context.mounted) {
        return _showManualOrHidSheet(context);
      }
      return null;
    }
  }

  Future<String?> _showManualOrHidBarcodeSheet(BuildContext context) {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetContext.tr('Scan or enter barcode'),
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                sheetContext.tr(
                  'Use a USB/Bluetooth barcode scanner or type the code below.',
                ),
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: sheetContext.tr('Barcode / SKU'),
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                ),
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  Navigator.of(sheetContext).pop(trimmed.isEmpty ? null : trimmed);
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(sheetContext.tr('Cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final trimmed = controller.text.trim();
                      Navigator.of(sheetContext).pop(
                        trimmed.isEmpty ? null : trimmed,
                      );
                    },
                    child: Text(sheetContext.tr('Confirm')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<String?> _showManualOrHidSheet(BuildContext context) =>
      _showManualOrHidBarcodeSheet(context);
}
