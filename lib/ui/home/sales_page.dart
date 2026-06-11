import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_item.dart';
import '../business_category_config.dart';
import '../payment/payment_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_skeleton.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';

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
  ProductArtType? _lastAddedType;
  String? _lastAddedImagePath;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;
  int _cartAnimationTicket = 0;

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
    Future<void>.delayed(const Duration(milliseconds: 800)).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _clearFlyToCartOverlay();
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
    final didAdd = store.addToCart(product);
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
      _lastAddedType = product.type;
      _lastAddedImagePath = product.imagePath;
      _successMessage = '${product.name} added to cart';
    });

    _cartAnimationController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 420));

    if (!mounted || animationTicket != _cartAnimationTicket) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (animationTicket != _cartAnimationTicket) return;
    _clearFlyToCartOverlay();

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted || animationTicket != _cartAnimationTicket) return;
    if (_successMessage == '${product.name} added to cart') {
      setState(() => _successMessage = null);
    }
  }

  void _openPaymentScreen() {
    HapticFeedback.mediumImpact();
    final store = context.read<PosLocalStore>();
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
    final config = store.businessCategoryConfig;
    final query = _searchQuery.trim().toLowerCase();
    final categories = <String>[
      'All',
      ...store.products.map((product) => product.type.name).toSet(),
    ];
    final displayProducts = store.products.where((product) {
      final categoryMatches =
          _selectedCategory == 'All' || product.type.name == _selectedCategory;
      if (!categoryMatches) return false;
      if (query.isEmpty) return true;
      final price = product.priceValue.toStringAsFixed(0);
      return product.name.toLowerCase().contains(query) ||
          product.size.toLowerCase().contains(query) ||
          price.contains(query) ||
          product.type.name.toLowerCase().contains(query);
    }).toList();
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );
    final content = Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: AppColors.pageBackground),
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.zero,
                  AppSpacing.lg, AppSpacing.zero),
              child: Column(
                children: [
                  SearchBox(
                    controller: _searchController,
                    hintText: config.salesHint,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onScanTap: null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SalesCategoryStrip(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.zero, AppSpacing.md, 138),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    if (_isLoading) {
                      return GridView.builder(
                        itemCount: 6,
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: compact ? 2 : 3,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, index) {
                          return MarketSkeleton(
                            width: double.infinity,
                            height: 100,
                            radius: AppRadius.card,
                          );
                        },
                      );
                    }
                    if (displayProducts.isEmpty) {
                      return Center(
                        child: MarketSurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          radius: AppRadius.rounded,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _emptyStateTitle(config.category, _searchQuery),
                                textAlign: TextAlign.center,
                                style: AppTypography.h3,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _emptyStateMessage(config.category),
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              MarketButton(
                                label: 'Clear Search',
                                icon: Icons.clear_rounded,
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                height: 48,
                                radius: AppRadius.standard,
                                fontSize: 14,
                                isFullWidth: false,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      itemCount: displayProducts.length,
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: compact ? 2 : 3,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, index) {
                        final product = displayProducts[index];
                        return ProductCard(
                          product: product,
                          onTapDown: (details) =>
                              _handleProductTap(product, details),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        if (_successMessage != null)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 102,
            child: SuccessMessageBanner(
              message: _successMessage!,
              type: _lastAddedType ?? ProductArtType.aquafina,
              imagePath: _lastAddedImagePath,
            ),
          ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md,
          child: CheckoutBar(
            cartKey: _cartKey,
            itemCount: store.cartCount,
            total: store.cartTotal,
            onCheckout: _openPaymentScreen,
            accentColor: config.primaryColor,
            label: _checkoutLabel(config.category),
          ),
        ),
      ],
    );

    return Theme(
      data: interTheme,
      child: SafeArea(
        top: !widget.useSharedShell,
        child: content,
      ),
    );
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
      height: 40,
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
  const _SalesCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: selected ? AppShadows.soft : null,
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.textMain,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
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
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'TSh $buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: onTapDown,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    child: _DashboardTileArt(product: product),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.size,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _money(product.priceValue),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Icon(
                            Icons.add_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      return Image.file(
        File(product.imagePath!),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: AppTypography.h3.copyWith(
            color: AppColors.textMuted,
            fontSize: 20,
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
    this.accentColor = AppColors.primary,
  });

  final GlobalKey cartKey;
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: cartKey,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Text(
                    '$itemCount',
                    style: AppTypography.helperText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemCount Items',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Current Cart',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TSH ${total.toStringAsFixed(0)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Total Amount',
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: FloatingActionButton.extended(
                heroTag: 'sales_checkout_fab',
                onPressed: onCheckout,
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 8,
                highlightElevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
                extendedPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                label: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _checkoutLabel(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Charge Sale',
    BusinessCategory.electronics => 'Charge & Register',
    BusinessCategory.retail => 'Checkout',
  };
}

String _emptyStateTitle(BusinessCategory category, String query) {
  if (query.trim().isNotEmpty) return 'No products found';
  return switch (category) {
    BusinessCategory.pharmacy => 'No medicines yet',
    BusinessCategory.electronics => 'No electronics yet',
    BusinessCategory.retail => 'No products yet',
  };
}

String _emptyStateMessage(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy =>
      'Add medicines with expiry and dosage details from product setup.',
    BusinessCategory.electronics =>
      'Add items with model and serial tracking from product setup.',
    BusinessCategory.retail => 'Try another name or clear the search.',
  };
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
        borderRadius: BorderRadius.circular(AppRadius.standard),
        boxShadow: AppShadows.medium,
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
        ],
      ),
    );
  }
}
