import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../models/product_item.dart';
import '../payment/payment_page.dart';
import '../products/product_management_page.dart';
import '../../service/barcode_scan_service.dart';
import '../../service/pos_local_store.dart';
import '../../utils/quantity_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_skeleton.dart';
import '../widgets/workspace_widgets.dart';
import 'suspended_sales_sheet.dart';
import 'widgets/measurement_sale_sheet.dart';
import 'widgets/product_card.dart';
import 'widgets/sales_cart_panel.dart';
import 'widgets/sales_controls_bar.dart';
import 'widgets/sales_dashboard_view_model.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({
    super.key,
    this.useSharedShell = false,
    this.onOpenInventory,
  });

  final bool useSharedShell;
  final VoidCallback? onOpenInventory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: useSharedShell ? null : const MarketAppDrawer(),
      body: SalesDashboardView(
        useSharedShell: useSharedShell,
        onOpenInventory: onOpenInventory,
      ),
    );
  }
}

class SalesDashboardView extends StatefulWidget {
  const SalesDashboardView({
    super.key,
    this.useSharedShell = false,
    this.onOpenInventory,
  });

  final bool useSharedShell;
  final VoidCallback? onOpenInventory;

  @override
  State<SalesDashboardView> createState() => _SalesDashboardViewState();
}

class _SalesDashboardViewState extends State<SalesDashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cartAnimationController;
  late final Animation<double> _cartAnimation;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _cartKey = GlobalKey();
  late final SalesDashboardViewModel _viewModel;
  OverlayEntry? _flyToCartOverlay;
  int _cartAnimationTicket = 0;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _cartAnimation = CurvedAnimation(
      parent: _cartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _viewModel = SalesDashboardViewModel(store: context.read<PosLocalStore>());
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _flyToCartOverlay?.remove();
    _cartAnimationController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _triggerFlyToCartAnimation(ProductItem product, Offset startOffset) {
    _flyToCartOverlay?.remove();
    _flyToCartOverlay = null;

    final cartBox = _cartKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartBox == null || !cartBox.attached) return;

    final endOffset = cartBox.localToGlobal(cartBox.size.center(Offset.zero));
    final ticket = ++_cartAnimationTicket;

    _flyToCartOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _cartAnimation,
          builder: (context, child) {
            final t = _cartAnimation.value;
            final dx = (1 - t) * startOffset.dx + t * endOffset.dx;
            final dy = (1 - t) * startOffset.dy +
                t * endOffset.dy -
                math.sin(t * math.pi) * 80;
            final scale = 1.0 - (t * 0.55);
            final opacity = (1.0 - (t * 0.35)).clamp(0.0, 1.0);

            return Positioned(
              left: dx - 20,
              top: dy - 20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_flyToCartOverlay!);
    _cartAnimationController.forward(from: 0).whenComplete(() {
      if (ticket == _cartAnimationTicket) {
        _flyToCartOverlay?.remove();
        _flyToCartOverlay = null;
      }
    });
  }

  Future<void> _handleProductTap(
    ProductItem product,
    TapDownDetails details,
  ) async {
    final store = context.read<PosLocalStore>();
    final inCart = store.cartQuantityForProduct(product);
    final remaining =
        roundQuantity(store.availableStockForProduct(product) - inCart);
    if (remaining <= 0) return;

    if (product.allowFractional) {
      final result = await MeasurementSaleSheet.show(
        context,
        product: product,
        availableStock: remaining,
      );
      if (result == null || !mounted) return;
      final added = store.addToCartQuantity(
        product,
        result.quantity,
        customPrice: result.customPrice,
      );
      if (!added) return;
      HapticFeedback.lightImpact();
      _triggerFlyToCartAnimation(product, details.globalPosition);
      _viewModel.setSuccessMessage(
        context.tr('Added {p0} to cart', args: {'p0': product.name}),
      );
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _viewModel.setSuccessMessage(null);
      });
      return;
    }

    HapticFeedback.lightImpact();
    store.addToCart(product);
    _triggerFlyToCartAnimation(product, details.globalPosition);
    _viewModel.setSuccessMessage(
      context.tr('Added {p0} to cart', args: {'p0': product.name}),
    );
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _viewModel.setSuccessMessage(null);
    });
  }

  Future<void> _handleBarcodeValue(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return;
    final store = context.read<PosLocalStore>();
    final matched = store.findProductByBarcode(code);
    if (matched == null) {
      _searchController.text = code;
      _viewModel.setSearchQuery(code);
      showMarketNotice(
        context,
        title: context.tr('Barcode not found'),
        message: context.tr('No product matched barcode {p0}', args: {'p0': code}),
        type: MarketNoticeType.warning,
      );
      return;
    }

    final added = store.addToCart(matched);
    if (!added) {
      showMarketNotice(
        context,
        title: context.tr('Out Of Stock'),
        message: context.tr(
          '{p0} has no more stock available',
          args: {'p0': matched.name},
        ),
        type: MarketNoticeType.warning,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _searchController.clear();
    _viewModel.setSearchQuery('');
    showMarketNotice(
      context,
      title: context.tr('Added to cart'),
      message: matched.name,
      type: MarketNoticeType.success,
    );
  }

  Future<void> _scanBarcode() async {
    final scanned = await BarcodeScanService.instance.scan(context);
    if (scanned == null || !mounted) return;
    await _handleBarcodeValue(scanned);
  }

  void _openQuickCartSheet() {
    final store = context.read<PosLocalStore>();
    if (store.cartItems.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.extraRounded),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(sheetCtx).size.height * 0.72,
          child: SalesCartPanel(
            checkout: CheckoutBar(
              cartKey: GlobalKey(),
              itemCount: sheetCtx.watch<PosLocalStore>().cartCount,
              total: sheetCtx.watch<PosLocalStore>().cartTotal,
              currency: sheetCtx.watch<PosLocalStore>().profile.currency,
              onCheckout: () {
                Navigator.of(sheetCtx).pop();
                _openPaymentScreen();
              },
              label: context.tr('Review & checkout'),
              accentColor: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _openPaymentScreen() {
    final store = context.read<PosLocalStore>();
    if (store.cartItems.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PaymentPage(
          items: List<ProductItem>.from(store.cartItems),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final products = _viewModel.filteredProducts;
        final categories = _viewModel.availableCategories;

        return SafeArea(
          top: !widget.useSharedShell,
          child: ColoredBox(
            color: AppColors.pageBackground,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;

                final holdActions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (store.cartItems.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final sale = await store.suspendCurrentSale();
                          if (sale != null && context.mounted) {
                            showMarketNotice(
                              context,
                              title: context.tr('Sale Held'),
                              message: context.tr(
                                'Sale {p0} parked/held successfully.',
                                args: {'p0': sale.id},
                              ),
                              type: MarketNoticeType.info,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.kpiAmberBg,
                          foregroundColor: AppColors.kpiAmber,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          context.tr('Hold Sale'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => SuspendedSalesSheet.show(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.kpiSkyBg,
                            foregroundColor: AppColors.kpiSky,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(
                            Icons.history_toggle_off_rounded,
                            size: 18,
                          ),
                          label: Text(
                            context.tr('Held Sales'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (store.suspendedSales.isNotEmpty)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kpiDanger,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${store.suspendedSales.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );

                final browser = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.useSharedShell)
                      Align(
                        alignment: Alignment.centerRight,
                        child: holdActions,
                      )
                    else
                      WorkspaceHeading(
                        title: context.tr('Make a sale'),
                        subtitle: context.tr(
                          'Choose products, review the cart and continue to payment.',
                        ),
                        action: holdActions,
                      ),
                    const SizedBox(height: 12),
                    SearchBox(
                      controller: _searchController,
                      hintText: context.tr('Search products or barcode'),
                      onChanged: (val) => _viewModel.setSearchQuery(val),
                      onSubmitted: (val) {
                        if (store.findProductByBarcode(val) != null) {
                          _handleBarcodeValue(val);
                        }
                      },
                      onScanTap: _scanBarcode,
                    ),
                    if (categories.length > 1) ...[
                      const SizedBox(height: 10),
                      SalesCategoryStrip(
                        categories: categories,
                        selectedCategory: _viewModel.selectedCategory,
                        onSelected: (cat) =>
                            _viewModel.setSelectedCategory(cat),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(
                              '{p0} products',
                              args: {'p0': products.length},
                            ),
                            style: AppTypography.sectionHeader,
                          ),
                        ),
                        if (_viewModel.searchQuery.isNotEmpty ||
                            _viewModel.selectedCategory != 'All' ||
                            _viewModel.inStockOnly)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _viewModel.resetFilters();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDeep,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.tr('Clear filters'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          tooltip: context.tr('Sort products'),
                          initialValue: _viewModel.sortBy,
                          onSelected: (val) => _viewModel.setSortBy(val),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'name',
                              child: Text(context.tr('Name A–Z')),
                            ),
                            PopupMenuItem(
                              value: 'price-low',
                              child:
                                  Text(context.tr('Price: low to high')),
                            ),
                            PopupMenuItem(
                              value: 'price-high',
                              child:
                                  Text(context.tr('Price: high to low')),
                            ),
                          ],
                          icon: const Icon(Icons.sort_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: !store.isInitialized
                          ? GridView.builder(
                              itemCount: 6,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                mainAxisExtent: 224,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (_, __) => const MarketSkeleton(
                                width: double.infinity,
                                height: 224,
                                radius: 10,
                              ),
                            )
                          : products.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: store.inventory.isEmpty
                                        ? MarketEmptyState(
                                            icon: Icons.inventory_2_outlined,
                                            title: context.strings.isSwahili
                                                ? 'Hakuna bidhaa bado'
                                                : 'No products yet',
                                            message: context.strings.isSwahili
                                                ? 'Ongeza bidhaa yako ya kwanza ili uanze kufanya mauzo.'
                                                : 'Add your first product to start making sales.',
                                            actionLabel:
                                                context.strings.isSwahili
                                                    ? 'Ongeza bidhaa'
                                                    : 'Add product',
                                            actionIcon: Icons.add_rounded,
                                            onAction: () {
                                              if (widget.onOpenInventory !=
                                                  null) {
                                                widget.onOpenInventory!();
                                              } else {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        const ProductManagementPage(),
                                                  ),
                                                );
                                              }
                                            },
                                          )
                                        : MarketEmptyState(
                                            icon: Icons.search_off_rounded,
                                            title: context
                                                .tr('No matching products'),
                                            message: context.tr(
                                              'Try a different search or clear your filters.',
                                            ),
                                            actionLabel:
                                                context.tr('Show all products'),
                                            actionIcon:
                                                Icons.filter_alt_off_rounded,
                                            onAction: () {
                                              _searchController.clear();
                                              _viewModel.resetFilters();
                                            },
                                          ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, gridConstraints) {
                                    final columns = (gridConstraints.maxWidth /
                                            205)
                                        .floor()
                                        .clamp(2, 6);
                                    return GridView.builder(
                                      itemCount: products.length,
                                      padding: const EdgeInsets.only(bottom: 16),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        mainAxisExtent: MediaQuery.textScalerOf(
                                                      context,
                                                    ).scale(1) >
                                                1.2
                                            ? 256
                                            : 224,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                      ),
                                      itemBuilder: (_, index) => ProductCard(
                                        product: products[index],
                                        onTapDown: (details) =>
                                            _handleProductTap(
                                          products[index],
                                          details,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );

                final checkout = CheckoutBar(
                  cartKey: _cartKey,
                  itemCount: store.cartCount,
                  total: store.cartTotal,
                  currency: store.profile.currency,
                  onViewCart: wide ? null : _openQuickCartSheet,
                  onCheckout: _openPaymentScreen,
                  label: context.tr('Review & checkout'),
                  accentColor: AppColors.primary,
                );

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 24 : 14,
                    wide ? 20 : 14,
                    wide ? 24 : 14,
                    wide ? 24 : 14,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: browser),
                            if (wide) ...[
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 350,
                                child: SalesCartPanel(checkout: checkout),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_viewModel.successMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: AppColors.primaryDeep,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _viewModel.successMessage!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!wide) ...[const SizedBox(height: 12), checkout],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
