import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_item.dart';
import '../payment/payment_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../../service/pos_local_store.dart';

class MarketHomePage extends StatelessWidget {
  const MarketHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MarketDashboardView(),
    );
  }
}

class MarketDashboardView extends StatefulWidget {
  const MarketDashboardView({super.key});

  @override
  State<MarketDashboardView> createState() => _MarketDashboardViewState();
}

class _MarketDashboardViewState extends State<MarketDashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cartAnimationController;
  late final Animation<double> _cartAnimation;
  final GlobalKey _cartKey = GlobalKey();
  OverlayEntry? _flyToCartOverlay;
  String? _successMessage;
  ProductArtType? _lastAddedType;
  String? _lastAddedImagePath;
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
    final displayProducts = store.products;
    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          Column(
            children: [
              const TopBar(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE6E7EB)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        HeaderInfo(
                          icon: Icons.calendar_today_outlined,
                          label: 'May 18, 2025',
                        ),
                        Spacer(),
                        HeaderInfo(
                          icon: Icons.access_time,
                          label: '10:24 AM',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: SearchBox()),
                        SizedBox(width: 12),
                        ScanButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 144),
                  child: GridView.builder(
                    itemCount: displayProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final product = displayProducts[index];
                      return ProductCard(
                        product: product,
                        onTapDown: (details) => _handleProductTap(product, details),
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
          const Positioned(
            right: 6,
            top: 300,
            child: ScrollHandle(),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          MenuButton(),
          SizedBox(width: 12),
          Expanded(child: BrandBlock()),
          SizedBox(width: 6),
          ProfileBlock(),
        ],
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HamburgerLine(width: 30),
          SizedBox(height: 6),
          HamburgerLine(width: 24),
          SizedBox(height: 6),
          HamburgerLine(width: 30),
        ],
      ),
    );
  }
}

class HamburgerLine extends StatelessWidget {
  const HamburgerLine({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFF293140),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class BrandBlock extends StatelessWidget {
  const BrandBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8EA06D), width: 1.5),
          ),
          child: const BrandMark(),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GreenLeaf',
              style: TextStyle(
                fontSize: 21,
                height: 1,
                color: Color(0xFF2C3442),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'M a r k e t',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 4.1,
                color: Color(0xFF8EA06D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFF8EA06D),
          size: 34,
        ),
        Positioned(
          bottom: 11,
          child: Container(
            width: 17,
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8EA06D), width: 1.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
          ),
        ),
        const Positioned(
          bottom: 10,
          child: Icon(
            Icons.home_outlined,
            color: Color(0xFF8EA06D),
            size: 14,
          ),
        ),
      ],
    );
  }
}

class ProfileBlock extends StatelessWidget {
  const ProfileBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.person, color: Color(0xFF293140), size: 28),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'John Doe',
              style: TextStyle(
                color: Color(0xFF2C3442),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Cashier',
              style: TextStyle(
                color: Color(0xFF7A8393),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF293140),
          size: 24,
        ),
      ],
    );
  }
}

class HeaderInfo extends StatelessWidget {
  const HeaderInfo({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF394150)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4F5868),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E6EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 30, color: Color(0xFF7E8695)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search products by name or SKU',
              style: TextStyle(
                color: Color(0xFFB2B8C2),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E6EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF8EA06D), size: 25),
          SizedBox(height: 1),
          Text(
            'Scan',
            style: TextStyle(
              color: Color(0xFF394150),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4E6EA)),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 16,
                  color: Color(0xFF99A1AE),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: product.imagePath != null && product.imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : ProductArt(type: product.type),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2C3442),
                fontSize: 11.8,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              product.size,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7A8393),
                fontSize: 10.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.price,
              style: const TextStyle(
                color: Color(0xFF2C3442),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF202938),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x32000000),
            blurRadius: 24,
            offset: Offset(0, 12),
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
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF8EA06D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: Color(0xFF202938),
                        fontSize: 13,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'View cart',
                  style: TextStyle(
                    color: Color(0xFFD0D5DE),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: Colors.white.withValues(alpha: 0.14),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TSH ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total',
                style: TextStyle(
                  color: Color(0xFFD0D5DE),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onCheckout,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF8EA06D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Text(
                    'Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
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
