import '../widgets/app_design.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import 'onboarding_illustrations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingItem> _slides = [
    _OnboardingItem(
      titleEn: 'Welcome to TrackMauzo!',
      titleSw: 'Karibu TrackMauzo!',
      subtitleEn:
          'The ultimate app for making your shop sales and daily stock management as convenient and smooth as possible.',
      subtitleSw:
          'Mfumo wa kisasa wa kurahisisha mauzo, kuweka stoo sawa, na kusimamia duka lako kwa urahisi zaidi.',
      art: OnboardingThemeArt.salesTracker,
    ),
    _OnboardingItem(
      titleEn: 'Smart Stock & Inventory',
      titleSw: 'Udhibiti Mahiri wa Stoo',
      subtitleEn:
          'Keep accurate product levels, low stock warnings, and instant pricing updates all in real-time.',
      subtitleSw:
          'Fuatilia idadi kamili ya bidhaa, tahadhari ya bidhaa zilizopungua, na bei za haraka popote ulipo.',
      art: OnboardingThemeArt.stockManager,
    ),
    _OnboardingItem(
      titleEn: 'Real-time Profit Insights',
      titleSw: 'Uchambuzi Halisi wa Faida',
      subtitleEn:
          'Understand your shop performance, high-selling products, and revenue anytime without paperwork.',
      subtitleSw:
          'Tambua mwenendo wa biashara, bidhaa zinazoongoza kwa mauzo, na faida yako bila madaftari ya zamani.',
      art: OnboardingThemeArt.reportsInsights,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final isSwahili = store.languageCode == 'sw';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // 1. Top Bar: Brand Logo & Language Switcher Pill
                  _TopBar(
                    isSwahili: isSwahili,
                    onToggleLanguage: () {
                      final newLang = isSwahili ? 'en' : 'sw';
                      store.setLanguageCode(newLang);
                    },
                  ),

                  // 2. Center Slider (Illustration + Title + Subtitle)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        final title = isSwahili ? slide.titleSw : slide.titleEn;
                        final subtitle =
                            isSwahili ? slide.subtitleSw : slide.subtitleEn;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final artSize = (constraints.maxHeight * 0.44)
                                .clamp(200.0, 310.0);

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Spacer(flex: 1),
                                      // Clean Custom Vector Illustration
                                      OnboardingIllustration(
                                        art: slide.art,
                                        size: artSize,
                                      ),
                                      const SizedBox(height: 24),
                                      // Bold clean headline
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF111111),
                                          letterSpacing: -0.6,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Subtitle with comfortable reading line-height
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          subtitle,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const Spacer(flex: 2),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 3. Smooth Modern Page Indicators (Active Pill + Inactive Dots)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isSelected = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 26 : 8,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF111111)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Primary Dark Pill Button ("Access Your Account" / "Get Started")
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF191C1F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? (isSwahili ? 'Anza Sasa' : 'Access Your Account')
                            : (isSwahili ? 'Endelea' : 'Continue'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Secondary Bottom Link ("Don't have an account? Signup")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSwahili
                              ? 'Una akaunti tayari? '
                              : "Don't have an account? ",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onSignIn,
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            isSwahili ? 'Ingia' : 'Signup',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isSwahili,
    required this.onToggleLanguage,
  });

  final bool isSwahili;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Logo & Title with clean green mark
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModernGreenRibbonLogo(),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'TrackMauzo',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Language Selector Pill
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleLanguage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF0FDF4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSwahili ? 'Kiswahili' : 'English',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernGreenRibbonLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/app_logo.png',
        width: 44,
        height: 44,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RibbonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stylized "Z / N" ribbon in vibrant green matching the reference
    final path = Path()
      ..moveTo(w * 0.15, h * 0.72)
      ..cubicTo(w * 0.15, h * 0.88, w * 0.40, h * 0.90, w * 0.52, h * 0.74)
      ..lineTo(w * 0.78, h * 0.32)
      ..cubicTo(w * 0.88, h * 0.16, w * 0.65, h * 0.08, w * 0.50, h * 0.22)
      ..cubicTo(w * 0.38, h * 0.34, w * 0.60, h * 0.58, w * 0.85, h * 0.48);

    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF111111), Color(0xFF111111)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.titleEn,
    required this.titleSw,
    required this.subtitleEn,
    required this.subtitleSw,
    required this.art,
  });

  final String titleEn;
  final String titleSw;
  final String subtitleEn;
  final String subtitleSw;
  final OnboardingThemeArt art;
}
