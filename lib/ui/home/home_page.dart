import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_item.dart';
import '../payment/payment_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../more/duka_ai_page.dart';

class MarketHomePage extends StatelessWidget {
  const MarketHomePage({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:
          useSharedShell ? null : const MarketAppDrawer(selectedItem: 'Sales'),
      body: MarketDashboardView(
        showHeader: !useSharedShell,
      ),
    );
  }
}

class MarketDashboardView extends StatefulWidget {
  const MarketDashboardView({
    super.key,
    this.showHeader = true,
  });

  final bool showHeader;

  @override
  State<MarketDashboardView> createState() => _MarketDashboardViewState();
}

class _MarketDashboardViewState extends State<MarketDashboardView>
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
          child: ColoredBox(color: Colors.white),
        ),
        Column(
          children: [
            if (widget.showHeader) const TopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children: [
                  SearchBox(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _SalesCategoryStrip(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 138),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    if (displayProducts.isEmpty) {
                      return Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE7EAF0)),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 34,
                                color: Color(0xFF7A859C),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No products found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF33363F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Try another name or clear the search.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF7A859C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      itemCount: displayProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: compact ? 2 : 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
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
            left: 16,
            right: 16,
            bottom: 102,
            child: SuccessMessageBanner(
              message: _successMessage!,
              type: _lastAddedType ?? ProductArtType.aquafina,
              imagePath: _lastAddedImagePath,
            ),
          ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: CheckoutBar(
            cartKey: _cartKey,
            itemCount: store.cartCount,
            total: store.cartTotal,
            onCheckout: _openPaymentScreen,
          ),
        ),
      ],
    );

    return Theme(
      data: interTheme,
      child: widget.showHeader
          ? SafeArea(child: content)
          : SafeArea(top: false, child: content),
    );
  }
}

// ... (other imports)

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Sales',
      centerTitle: false,
      showBackButton: false,
      leading: const DrawerMenuButton(),
      actions: [
        HeaderActionButton(
          icon: Icons.smart_toy_outlined,
          background: Colors.white,
          foreground: const Color(0xFF33363F),
          borderColor: const Color(0xFFE7EAF0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DukaAiAdvisorPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        HeaderActionButton(
          icon: Icons.notifications_none_rounded,
          background: Colors.white,
          foreground: const Color(0xFF33363F),
          borderColor: const Color(0xFFE7EAF0),
          showDot: true,
        ),
      ],
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.manrope(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search products by name or SKU',
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: Color(0xFF64748B),
                        ),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
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
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F6FEB) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFF1F6FEB) : const Color(0xFFE5EAF0),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: selected ? Colors.white : const Color(0xFF4B5563),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
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
    return 'TSh$buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTapDown: onTapDown,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E5EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x050F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: ColoredBox(
                          color: const Color(0xFFF8FAFC),
                          child: _DashboardTileArt(product: product),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD7E2FF)),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF2563EB),
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.size,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A859C),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _money(product.priceValue),
                        style: const TextStyle(
                          color: Color(0xFF1B9B69),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(product.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _DashboardFallbackArt(label: product.name),
        ),
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
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E8EF)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 23,
            fontWeight: FontWeight.w500,
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
  });

  final GlobalKey cartKey;
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF1F2937),
                  size: 22,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE54040),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemCount Items',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'View cart',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TSH ${total.toStringAsFixed(0)}',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCheckout,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1FB91C1C),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Checkout',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E7A47),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedCartToken(
              type: type,
              imagePath: imagePath,
              compact: true,
            ),
            const SizedBox(width: 10),
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
