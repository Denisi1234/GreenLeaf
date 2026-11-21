import 'package:track_mauzo/l10n/app_localization.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../inventory_product_item.dart';
import '../../models/product_item.dart';

class ProductCsvService {
  const ProductCsvService._();

  static Future<void> exportInventoryCsv(List<InventoryProductItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('Code,Name,Category,CostPrice,SalePrice,Quantity,Unit');
    for (final item in items) {
      buffer.writeln(
        '"${item.code}","${item.name.replaceAll('"', '""')}","${item.category}",${item.purchasePrice},${item.sellingPrice},${item.stockCount},"${item.unit}"',
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
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
              backgroundColor: AppColors.successDeep,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child:  Text(context.tr('Import')),
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
        final stock = parts.length >= 5 ? (int.tryParse(parts[4]) ?? 0) : 0;
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
              unit: 'Pcs',
            ),
          );
          addedCount++;
        } catch (_) {}
      }
    }
    return addedCount;
  }
}
