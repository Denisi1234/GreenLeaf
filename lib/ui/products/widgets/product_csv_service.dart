import 'package:aza_pos/l10n/app_localization.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/quantity_formatter.dart';
import '../../widgets/app_design.dart';
import '../inventory_product_item.dart';
import '../../models/product_item.dart';

class ProductCsvService {
  const ProductCsvService._();

  static Future<void> exportInventoryCsv(List<InventoryProductItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Code,Name,Category,CostPrice,SalePrice,Quantity,Unit,AllowFractional,PackName,PackSize');
    for (final item in items) {
      buffer.writeln(
        '"${item.code}","${item.name.replaceAll('"', '""')}","${item.category}",${item.purchasePrice},${item.sellingPrice},${formatQuantity(item.stockCount)},"${item.unit}",${item.allowFractional},"${item.packName ?? ''}",${item.packSize != null ? formatQuantity(item.packSize!) : ''}',
      );
    }
    final fileName =
        'inventory_export_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(buffer.toString())),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }

  static Future<int> showImportCsvDialog(BuildContext context, PosLocalStore store) async {
    final textController = TextEditingController();
    final imported = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title:  Text(context.tr('Import CSV Items')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Format: Name, Category, Cost, Price, Stock\n(One item per line)'),
              style: AppTypography.label,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 7,
              decoration:  InputDecoration(
                hintText:
                    context.tr('Milk 1L, Dairy, 2000, 2500, 30\nBread, Bakery, 1500, 1800, 20'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:  Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(context.tr('Import')),
          ),
        ],
      ),
    );

    if (imported == null || imported.isEmpty) return 0;

    final lines = imported.split('\n');
    int addedCount = 0;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 4) {
        final name = parts[0];
        final category = parts[1];
        final cost = double.tryParse(parts[2]) ?? 0.0;
        final price = double.tryParse(parts[3]) ?? (cost * 1.25);
        final stock = roundQuantity(
            parts.length >= 5 ? (double.tryParse(parts[4]) ?? 0.0) : 0.0);
        final unit =
            parts.length >= 6 && parts[5].isNotEmpty ? parts[5] : 'Pcs';
        final allowFractional = parts.length >= 7
            ? parts[6].toLowerCase() == 'true' || parts[6] == '1'
            : isMeasuredUnit(unit);
        final packName =
            parts.length >= 8 && parts[7].isNotEmpty ? parts[7] : null;
        final packSize =
            parts.length >= 9 ? double.tryParse(parts[8]) : null;
        final nextCode =
            'P${(store.inventory.length + addedCount + 1).toString().padLeft(3, '0')}';

        try {
          await store.addProduct(
            InventoryProductItem(
              code: nextCode,
              name: name,
              category: category.isNotEmpty ? category : 'General',
              purchasePrice: cost,
              sellingPrice: price,
              stockCount: stock,
              stockState: stock <= 0
                  ? InventoryStockState.outOfStock
                  : stock <= 5
                      ? InventoryStockState.lowStock
                      : InventoryStockState.inStock,
              artType: ProductArtType.aquafina,
              unit: unit,
              allowFractional: allowFractional,
              packName: packName,
              packSize: packSize != null && packSize > 0 ? packSize : null,
            ),
          );
          addedCount++;
        } catch (_) {}
      }
    }
    return addedCount;
  }
}
