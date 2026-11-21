import 'package:flutter/services.dart';

import '../ui/receipt/receipt_document.dart';
import 'esc_pos_receipt_builder.dart';

class BluetoothPrinterDevice {
  const BluetoothPrinterDevice({
    required this.name,
    required this.address,
  });

  final String name;
  final String address;
}

class ThermalPrinterException implements Exception {
  const ThermalPrinterException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Manages paired Bluetooth 58mm/80mm ESC-POS thermal printers.
class ThermalPrinterService {
  ThermalPrinterService({
    Future<List<BluetoothPrinterDevice>> Function()? listOverride,
    Future<void> Function(String address, Uint8List bytes)? printOverride,
  })  : _listOverride = listOverride,
        _printOverride = printOverride;

  static const MethodChannel _channel =
      MethodChannel('trackmauzo/thermal_printer');

  static ThermalPrinterService instance = ThermalPrinterService();

  final Future<List<BluetoothPrinterDevice>> Function()? _listOverride;
  final Future<void> Function(String address, Uint8List bytes)? _printOverride;

  static void setTestOverrides({
    Future<List<BluetoothPrinterDevice>> Function()? listPrinters,
    Future<void> Function(String address, Uint8List bytes)? printBytes,
  }) {
    instance = ThermalPrinterService(
      listOverride: listPrinters,
      printOverride: printBytes,
    );
  }

  static void resetForTests() {
    instance = ThermalPrinterService();
  }

  Future<bool> requestPermissions() async {
    if (_listOverride != null || _printOverride != null) return true;
    try {
      return await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      throw ThermalPrinterException(
        error.message ?? 'Bluetooth permission check failed.',
      );
    }
  }

  Future<List<BluetoothPrinterDevice>> listPairedPrinters() async {
    final override = _listOverride;
    if (override != null) return override();

    try {
      final granted = await requestPermissions();
      if (!granted) {
        throw const ThermalPrinterException(
          'Bluetooth permission is required to find paired printers.',
        );
      }
      final raw = await _channel.invokeMethod<List<Object?>>(
        'listPairedPrinters',
      );
      if (raw == null) return const [];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map((item) => BluetoothPrinterDevice(
                name: (item['name'] ?? '').toString(),
                address: (item['address'] ?? '').toString(),
              ))
          .where((device) => device.address.isNotEmpty)
          .toList(growable: false);
    } on MissingPluginException {
      throw const ThermalPrinterException(
        'Direct Bluetooth thermal printing is available on Android devices.',
      );
    } on PlatformException catch (error) {
      throw ThermalPrinterException(
        error.message ?? 'Could not list paired Bluetooth printers.',
      );
    }
  }

  Future<void> printRawBytes({
    required String address,
    required Uint8List bytes,
  }) async {
    if (address.trim().isEmpty) {
      throw const ThermalPrinterException('No thermal printer selected.');
    }
    final override = _printOverride;
    if (override != null) {
      await override(address, bytes);
      return;
    }

    try {
      final granted = await requestPermissions();
      if (!granted) {
        throw const ThermalPrinterException(
          'Bluetooth permission is required to print.',
        );
      }
      await _channel.invokeMethod<bool>(
        'printBytes',
        <String, Object?>{'address': address, 'bytes': bytes},
      );
    } on MissingPluginException {
      throw const ThermalPrinterException(
        'Direct Bluetooth thermal printing is available on Android devices.',
      );
    } on PlatformException catch (error) {
      throw ThermalPrinterException(
        error.message ?? 'Could not send receipt to Bluetooth printer.',
      );
    }
  }

  Future<void> printReceipt({
    required ReceiptDocument receipt,
    required String address,
    ThermalPaperWidth paperWidth = ThermalPaperWidth.mm58,
    bool openCashDrawer = false,
  }) async {
    final bytes = EscPosReceiptBuilder.buildReceipt(
      receipt,
      paperWidth: paperWidth,
      openCashDrawer: openCashDrawer,
    );
    await printRawBytes(address: address, bytes: bytes);
  }

  Future<void> printTestTicket({
    required String address,
    required String storeName,
    ThermalPaperWidth paperWidth = ThermalPaperWidth.mm58,
  }) async {
    final bytes = EscPosReceiptBuilder.buildTestTicket(
      storeName: storeName,
      paperWidth: paperWidth,
    );
    await printRawBytes(address: address, bytes: bytes);
  }
}
