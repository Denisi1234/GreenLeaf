import '../widgets/app_image.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_item.dart';
import '../payment/payment_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_skeleton.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';

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
  OverlayEntry? _flyToCartOverlay;
  String? _successMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _inStockOnly = false;
  String _sortBy = 'name';
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
  }

  @override
  void dispose() {
    _clearFlyToCartOverlay();
    _successTimer?.cancel();
    _searchController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  void _clearFlyToCartOverlay() {
    _flyToCartOverlay?.remove();
    _flyToCartOverlay = null;
  }

  Future<void> _handleProductTap(
    ProductItem product,
    TapDownDetails details,
  ) async {
    final store = context.read<PosLocalStore>();
    final overlay = Overlay.of(context);
    final cartContext = _cartKey.currentContext;
    if (cartContext == null) return;
    final alreadyInCart = store.cartItems
        .where((item) => _productKey(item) == _productKey(product))
        .length;
    final didAdd = store.availableStockForProduct(product) > alreadyInCart &&
        store.addToCart(product);
    if (!didAdd) {
      showMarketNotice(
        context,
        title: 'Out Of Stock',
        message: '${product.name} has no more stock available',
        type: MarketNoticeType.warning,
      );
      return;
    }
    HapticFeedback.lightImpact();

    final animationTicket = ++_cartAnimationTicket;
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final cartBox = cartContext.findRenderObject() as RenderBox;
    final start = overlayBox.globalToLocal(details.globalPosition);
    final cartCenter = overlayBox.globalToLocal(
      cartBox.localToGlobal(cartBox.size.center(Offset.zero)),
    );

    _cartAnimationController.stop();
    _clearFlyToCartOverlay();
    _flyToCartOverlay = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _cartAnimation,
                builder: (context, child) {
                  final progress = _cartAnimation.value;
                  final curvedY = math.sin(progress * math.pi) * -48;
                  final position = Offset.lerp(start, cartCenter, progress)!;

                  return Positioned(
                    left: position.dx - 22,
                    top: position.dy - 22 + curvedY,
                    child: Transform.scale(
                      scale: 1 - (progress * 0.35),
                      child: Opacity(
                        opacity: 1 - (progress * 0.15),
                        child: AnimatedCartToken(
                          type: product.type,
                          imagePath: product.imagePath,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_flyToCartOverlay!);

    setState(() {
      _successMessage = '${product.name} added to cart';
    });

    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _successMessage = null);
    });
    try {
      await _cartAnimationController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted && animationTicket == _cartAnimationTicket) {
      _clearFlyToCartOverlay();
    }
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

  String _categoryOf(ProductItem product) =>
      product.category?.trim().isNotEmpty == true
          ? product.category!.trim()
          : 'Uncategorized';

  void _resetFilters() => setState(() {
        _searchController.clear();
        _searchQuery = '';
        _selectedCategory = 'All';
        _inStockOnly = false;
      });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final query = _searchQuery.trim().toLowerCase();
    final categoryNames = store.products.map(_categoryOf).toSet().toList()
      ..sort();
    final categories = ['All', ...categoryNames];
    final selectedCategory =
        categories.contains(_selectedCategory) ? _selectedCategory : 'All';
    final inventory = {for (final item in store.inventory) item.code: item};
    final products = store.products.where((product) {
      if (selectedCategory != 'All' &&
          _categoryOf(product) != selectedCategory) {
        return false;
      }
      if (_inStockOnly && store.availableStockForProduct(product) <= 0) {
        return false;
      }
      final extra =
          inventory[product.code]?.categoryData.values.join(' ') ?? '';
      return query.isEmpty ||
          '${product.name} ${product.size} ${product.code ?? ''} ${_categoryOf(product)} $extra'
              .toLowerCase()
              .contains(query);
    }).toList()
      ..sort((a, b) => switch (_sortBy) {
            'price-low' => a.priceValue.compareTo(b.priceValue),
            'price-high' => b.priceValue.compareTo(a.priceValue),
            _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          });
    return SafeArea(
        top: !widget.useSharedShell,
        child: ColoredBox(
          color: AppColors.pageBackground,
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final browser =
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const WorkspaceHeading(
                  title: 'Make a sale',
                  subtitle:
                      'Choose products, review the cart and continue to payment.'),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products, item codes or barcodes',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                          icon: const Icon(Icons.close_rounded)),
                ),
              ),
              const SizedBox(height: 12),
              _SalesCategoryStrip(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onSelected: (value) =>
                      setState(() => _selectedCategory = value)),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                        label: const Text('In stock only'),
                        selected: _inStockOnly,
                        onSelected: (value) =>
                            setState(() => _inStockOnly = value)),
                    PopupMenuButton<String>(
                      tooltip: 'Sort products',
                      initialValue: _sortBy,
                      onSelected: (value) => setState(() => _sortBy = value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'name', child: Text('Name A–Z')),
                        PopupMenuItem(
                            value: 'price-low',
                            child: Text('Price: low to high')),
                        PopupMenuItem(
                            value: 'price-high',
                            child: Text('Price: high to low'))
                      ],
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.sort_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text('Sort', style: AppTypography.bodySmall),
                          ])),
                    ),
                    Text('${products.length} products',
                        style: AppTypography.label),
                    if (query.isNotEmpty ||
                        selectedCategory != 'All' ||
                        _inStockOnly)
                      TextButton(
                          onPressed: _resetFilters,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.dangerDeep),
                          child: const Text('Clear filters')),
                  ]),
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
                                  mainAxisSpacing: 12),
                          itemBuilder: (_, __) => const MarketSkeleton(
                              width: double.infinity, height: 250, radius: 12),
                        )
                      : products.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                  child: WorkspacePanel(
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                  const Icon(Icons.search_off_rounded,
                                      size: 40, color: AppColors.textMuted),
                                  const SizedBox(height: 16),
                                  Text('No matching products',
                                      style: AppTypography.h3),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Try a different search or clear your filters.',
                                      style: AppTypography.bodySmall,
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  TextButton(
                                      onPressed: _resetFilters,
                                      child: const Text('Show all products')),
                                ]))))
                          : LayoutBuilder(builder: (context, gridConstraints) {
                              final columns = (gridConstraints.maxWidth / 205)
                                  .floor()
                                  .clamp(2, 6);
                              return GridView.builder(
                                itemCount: products.length,
                                padding: const EdgeInsets.only(bottom: 16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        mainAxisExtent:
                                            MediaQuery.textScalerOf(context)
                                                        .scale(1) >
                                                    1.2
                                                ? 290
                                                : 260,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12),
                                itemBuilder: (_, index) => ProductCard(
                                    product: products[index],
                                    onTapDown: (details) => _handleProductTap(
                                        products[index], details)),
                              );
                            })),
            ]);
            final checkout = CheckoutBar(
                cartKey: _cartKey,
                itemCount: store.cartCount,
                total: store.cartTotal,
                onCheckout: _openPaymentScreen,
                label: 'Review & checkout',
                accentColor: AppColors.successDeep);
            return Padding(
                padding: EdgeInsets.all(wide ? 24 : 16),
                child: Column(children: [
                  Expanded(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Expanded(child: browser),
                        if (wide) ...[
                          const SizedBox(width: 24),
                          SizedBox(
                              width: 350,
                              child: _SalesCartPanel(checkout: checkout)),
                        ],
                      ])),
                  if (_successMessage != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: AppColors.successDeep),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_successMessage!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall)),
                        ])),
                  if (!wide) ...[const SizedBox(height: 12), checkout],
                ]));
          }),
        ));
  }
}

String _productKey(ProductItem product) => product.code?.isNotEmpty == true
    ? product.code!
    : '${product.name}|${product.size}|${product.price}|${product.type.name}';

class _SalesCartPanel extends StatelessWidget {
  const _SalesCartPanel({required this.checkout});
  final Widget checkout;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lines = <String, OrderLineItem>{};
    for (final item in store.cartItems) {
      final key = _productKey(item);
      if (lines.containsKey(key)) {
        lines[key]!.quantity++;
      } else {
        lines[key] = OrderLineItem(product: item, quantity: 1);
      }
    }
    return WorkspacePanel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                    child: Text('Current sale',
                        style: AppTypography.sectionHeader)),
                WorkspaceStatus(
                    label: '${store.cartCount} units',
                    color: AppColors.textBody),
              ])),
          const Divider(height: 1),
          Expanded(
              child: lines.isEmpty
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.shopping_bag_outlined,
                                size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('Your cart is empty',
                                style: AppTypography.sectionHeader),
                            const SizedBox(height: 8),
                            Text('Select a product to start a sale.',
                                style: AppTypography.bodySmall,
                                textAlign: TextAlign.center),
                          ])))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (_, index) {
                        final line = lines.values.elementAt(index);
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.product.name,
                                  style: AppTypography.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                  'TSh ${formatCurrency(line.product.priceValue)} each',
                                  style: AppTypography.label),
                              const SizedBox(height: 8),
                              Row(children: [
                                IconButton(
                                    tooltip: 'Remove one ${line.product.name}',
                                    onPressed: () => store
                                        .removeSingleFromCart(line.product),
                                    icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 22)),
                                Text('${line.quantity}',
                                    style: AppTypography.bodyMedium),
                                IconButton(
                                    tooltip: 'Add one ${line.product.name}',
                                    onPressed: line.quantity <
                                            store.availableStockForProduct(
                                                line.product)
                                        ? () => store.addToCart(line.product)
                                        : null,
                                    icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'TSh ${formatCurrency(line.totalPrice)}',
                                        textAlign: TextAlign.right,
                                        style: AppTypography.bodySmall.copyWith(
                                            fontWeight: FontWeight.w700))),
                              ]),
                            ]);
                      },
                    )),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: checkout),
        ]));
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onScanTap,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    return MarketSearchField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onClear: () {
        controller.clear();
        onChanged('');
      },
      onScanTap: onScanTap,
    );
  }
}

class _SalesCategoryStrip extends StatelessWidget {
  const _SalesCategoryStrip({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return _SalesCategoryChip(
            label: category,
            selected: selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _SalesCategoryChip extends StatelessWidget {
  const _SalesCategoryChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.ink,
        labelStyle: AppTypography.bodySmall
            .copyWith(color: selected ? Colors.white : AppColors.textBody),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.border),
      );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTapDown,
  });

  final ProductItem product;
  final ValueChanged<TapDownDetails> onTapDown;

  String _money(double value) {
    return 'TSh ${formatCurrency(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final inCart = store.cartItems
        .where((item) => _productKey(item) == _productKey(product))
        .length;
    final remaining =
        (store.availableStockForProduct(product) - inCart).clamp(0, 1 << 31);
    TapDownDetails? tapDetails;
    return Semantics(
      button: true,
      enabled: remaining > 0,
      label:
          '${product.name}, ${_money(product.priceValue)}, $remaining available',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: inCart > 0 ? AppColors.successDeep : AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: remaining > 0 ? (details) => tapDetails = details : null,
          onTap: remaining > 0
              ? () {
                  final box = context.findRenderObject() as RenderBox;
                  onTapDown(tapDetails ??
                      TapDownDetails(
                          globalPosition:
                              box.localToGlobal(box.size.center(Offset.zero))));
                }
              : null,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: 104,
                width: double.infinity,
                child: ColoredBox(
                  color: AppColors.surfaceSecondary,
                  child: Stack(children: [
                    Positioned.fill(child: _DashboardTileArt(product: product)),
                    if (remaining <= 5)
                      Positioned(
                          top: 8,
                          left: 8,
                          child: WorkspaceStatus(
                            label: remaining == 0
                                ? (inCart > 0 ? 'All in cart' : 'Out of stock')
                                : '$remaining left',
                            color: remaining == 0 && inCart == 0
                                ? AppColors.dangerDeep
                                : AppColors.warningDeep,
                          )),
                    if (inCart > 0)
                      Positioned(
                          bottom: 8,
                          right: 8,
                          child: WorkspaceStatus(
                              label: '$inCart in cart',
                              color: AppColors.successDeep)),
                  ]),
                )),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700))),
                          if (product.size.isNotEmpty)
                            Text(product.size,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(_money(product.priceValue),
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                                fontWeight: FontWeight.w800)))),
                            const SizedBox(width: 8),
                            Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                    color: remaining > 0
                                        ? AppColors.ink
                                        : AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(
                                    remaining > 0
                                        ? Icons.add_rounded
                                        : Icons.remove_rounded,
                                    color: remaining > 0
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    size: 20)),
                          ]),
                        ]))),
          ]),
        ),
      ),
    );
  }
}

class _DashboardTileArt extends StatelessWidget {
  const _DashboardTileArt({
    required this.product,
  });

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Image(
        image: appImageProvider(context, product.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _DashboardFallbackArt(label: product.name),
      );
    }
    return _DashboardFallbackArt(label: product.name);
  }
}

class _DashboardFallbackArt extends StatelessWidget {
  const _DashboardFallbackArt({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();

    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.manrope(
            color: const Color(0xFF64748B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({
    super.key,
    required this.cartKey,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
    required this.label,
    this.accentColor = const Color(0xFF0F172A),
  });

  final GlobalKey cartKey;
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: itemCount > 0,
        child: Material(
          color: itemCount > 0 ? accentColor : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: itemCount > 0 ? onCheckout : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.shopping_bag_outlined,
                      key: cartKey,
                      color: itemCount > 0 ? Colors.white : AppColors.textMuted,
                      size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(itemCount > 0 ? label : 'Select products to start',
                            style: AppTypography.bodySmall.copyWith(
                                color: itemCount > 0
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('$itemCount units • TSh ${formatCurrency(total)}',
                            style: AppTypography.bodySmall.copyWith(
                                color: itemCount > 0
                                    ? Colors.white
                                    : AppColors.textMuted)),
                      ])),
                  Icon(Icons.arrow_forward_rounded,
                      size: 20,
                      color:
                          itemCount > 0 ? Colors.white : AppColors.textMuted),
                ]),
              )),
        ),
      );
}

class SuccessMessageBanner extends StatelessWidget {
  const SuccessMessageBanner({
    super.key,
    required this.message,
    required this.type,
    this.imagePath,
  });

  final String message;
  final ProductArtType type;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.successDeep),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          AnimatedCartToken(
            type: type,
            imagePath: imagePath,
            compact: true,
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 18),
        ],
      ),
    );
  }
}
