import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../models/product_item.dart';
import '../payment/payment_page.dart';
import '../../service/barcode_scan_service.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_skeleton.dart';
import '../widgets/workspace_widgets.dart';
import 'suspended_sales_sheet.dart';
import 'widgets/product_card.dart';
import 'widgets/sales_cart_panel.dart';
import 'widgets/sales_controls_bar.dart';
import 'widgets/sales_dashboard_view_model.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: useSharedShell ? null : const MarketAppDrawer(),
      body: SalesDashboardView(
        useSharedShell: useSharedShell,
      ),
    );
  }
}

class SalesDashboardView extends StatefulWidget {
  const SalesDashboardView({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

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
                        color: AppColors.ink,
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

  void _handleProductTap(ProductItem product, TapDownDetails details) {
    final store = context.read<PosLocalStore>();
    final inCart = store.cartItems
        .where((item) => productKey(item) == productKey(product))
        .length;
    final remaining = store.availableStockForProduct(product) - inCart;
    if (remaining <= 0) return;

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
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.standard),
                          ),
                        ),
                        icon: const Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(context.tr('Hold Sale')),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FilledButton.icon(
                          onPressed: () => SuspendedSalesSheet.show(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.standard),
                            ),
                          ),
                          icon: const Icon(
                            Icons.history_toggle_off_rounded,
                            size: 18,
                          ),
                          label: Text(context.tr('Held Sales')),
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
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
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
                    SizedBox(height: widget.useSharedShell ? 12 : 16),
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
                    const SizedBox(height: 12),
                    SalesCategoryStrip(
                      categories: categories,
                      selectedCategory: _viewModel.selectedCategory,
                      onSelected: (cat) => _viewModel.setSelectedCategory(cat),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilterChip(
                          label: Text(context.tr('In stock')),
                          selected: _viewModel.inStockOnly,
                          side: BorderSide.none,
                          backgroundColor: AppColors.surface,
                          selectedColor: const Color(0xFFEFF6FF),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          onSelected: (val) => _viewModel.setInStockOnly(val),
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
                              child: Text(context.tr('Price: low to high')),
                            ),
                            PopupMenuItem(
                              value: 'price-high',
                              child: Text(context.tr('Price: high to low')),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sort_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('Sort'),
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          context.tr(
                            '{p0} products',
                            args: {'p0': products.length},
                          ),
                          style: AppTypography.label,
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
                              foregroundColor: AppColors.dangerDeep,
                            ),
                            child: Text(context.tr('Clear filters')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: !store.isInitialized
                          ? GridView.builder(
                              itemCount: 6,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                mainAxisExtent: 250,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (_, __) => const MarketSkeleton(
                                width: double.infinity,
                                height: 250,
                                radius: 0,
                              ),
                            )
                          : products.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: WorkspacePanel(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.search_off_rounded,
                                            size: 40,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            context.tr('No matching products'),
                                            style: AppTypography.h3,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            context.tr(
                                              'Try a different search or clear your filters.',
                                            ),
                                            style: AppTypography.bodySmall,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          TextButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              _viewModel.resetFilters();
                                            },
                                            child: Text(
                                              context.tr('Show all products'),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                            ? 290
                                            : 260,
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
                  onCheckout: _openPaymentScreen,
                  label: context.tr('Review & checkout'),
                  accentColor: AppColors.successDeep,
                );

                return Padding(
                  padding: EdgeInsets.all(wide ? 24 : 16),
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
                                color: AppColors.successDeep,
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
