import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

enum _BillingCycle { monthly, yearly }

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  _BillingCycle _billingCycle = _BillingCycle.monthly;
  String _selectedPlanId = 'business';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    final plans = _buildPlans(strings);

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.pageBackground,
          elevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.ink,
          title: Text(strings.subscriptionPlansTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Text(
                        strings.subscriptionPlansSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.subscriptionPlansSubtitleTwo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _BillingToggle(
                billingCycle: _billingCycle,
                onChanged: (value) {
                  setState(() => _billingCycle = value);
                },
                strings: strings,
              ),
              const SizedBox(height: 10),
              ...plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanCard(
                    plan: plan,
                    billingCycle: _billingCycle,
                    strings: strings,
                    isSelected: _selectedPlanId == plan.id,
                    onChoose: () {
                      setState(() => _selectedPlanId = plan.id);
                      showMarketNotice(
                        context,
                        title: plan.title,
                        message: strings.comingSoon,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.allPlansIncludeMultiPlatformAccess,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _PlatformRow(strings: strings),
              const SizedBox(height: 10),
              Text(
                strings.securePaymentsCancelAnytime,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_PlanData> _buildPlans(AppStrings strings) {
    return [
      _PlanData(
        id: 'starter',
        title: strings.starter,
        description: strings.starterDescription,
        icon: Icons.rocket_launch_outlined,
        accent: const Color(0xFF2F8C68),
        soft: const Color(0xFFEAF8F1),
        monthlyPrice: 19,
        yearlyPrice: 190,
        features: [
          strings.upToOneUser,
          strings.manageUpToOneThousandProducts,
          strings.basicReports,
          strings.customerManagement,
          strings.emailSupport,
        ],
      ),
      _PlanData(
        id: 'business',
        title: strings.business,
        description: strings.businessDescription,
        icon: Icons.work_outline_rounded,
        accent: const Color(0xFF2D6CEA),
        soft: const Color(0xFFEAF2FF),
        monthlyPrice: 49,
        yearlyPrice: 490,
        isPopular: true,
        features: [
          strings.upToFiveUsers,
          strings.manageUpToTenThousandProducts,
          strings.advancedReports,
          strings.customerManagement,
          strings.inventoryManagement,
          strings.priorityEmailChatSupport,
        ],
      ),
    ];
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.billingCycle,
    required this.onChanged,
    required this.strings,
  });

  final _BillingCycle billingCycle;
  final ValueChanged<_BillingCycle> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE4E8EF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BillingPill(
              label: strings.monthly,
              selected: billingCycle == _BillingCycle.monthly,
              onTap: () => onChanged(_BillingCycle.monthly),
            ),
            _BillingPill(
              label: strings.annually,
              selected: billingCycle == _BillingCycle.yearly,
              onTap: () => onChanged(_BillingCycle.yearly),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingPill extends StatelessWidget {
  const _BillingPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3F7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF2D6CEA) : AppColors.mutedText,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.strings,
    required this.isSelected,
    required this.onChoose,
  });

  final _PlanData plan;
  final _BillingCycle billingCycle;
  final AppStrings strings;
  final bool isSelected;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = plan.monthlyPrice;
    final yearlyPrice = plan.yearlyPrice;

    return MarketSurfaceCard(
      backgroundColor: Colors.white,
      borderColor: plan.isPopular
          ? plan.accent.withValues(alpha: 0.55)
          : const Color(0xFFE7EAF0),
      radius: 22,
      showShadow: false,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          if (plan.isPopular)
            Positioned(
              right: 0,
              top: 0,
              child: ClipPath(
                clipper: _RibbonClipper(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 8, 12, 8),
                  color: plan.accent,
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: plan.soft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        plan.icon,
                        color: plan.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 20.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            plan.description,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 360;
                    final priceBlock = _PriceBlock(
                      billingCycle: billingCycle,
                      monthlyPrice: monthlyPrice,
                      yearlyPrice: yearlyPrice,
                      accent: plan.accent,
                      strings: strings,
                      isSelected: isSelected,
                      onChoose: onChoose,
                    );
                    final featureList = _PlanFeatures(
                      features: plan.features,
                      accent: plan.accent,
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          featureList,
                          const SizedBox(height: 14),
                          priceBlock,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: featureList),
                        const SizedBox(width: 10),
                        SizedBox(width: 152, child: priceBlock),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.billingCycle,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.accent,
    required this.strings,
    required this.isSelected,
    required this.onChoose,
  });

  final _BillingCycle billingCycle;
  final int monthlyPrice;
  final int yearlyPrice;
  final Color accent;
  final AppStrings strings;
  final bool isSelected;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final selectedPrice =
        billingCycle == _BillingCycle.monthly ? monthlyPrice : yearlyPrice;
    final yearlySave = strings.saveSeventeenPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.monthly,
                style: TextStyle(
                  color: billingCycle == _BillingCycle.monthly
                      ? accent
                      : AppColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strings.annually,
                style: TextStyle(
                  color: billingCycle == _BillingCycle.yearly
                      ? accent
                      : AppColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '\$$selectedPrice',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Text(
          billingCycle == _BillingCycle.monthly
              ? '/ ${strings.monthly.toLowerCase()}'
              : '/ ${strings.annually.toLowerCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Divider(color: AppColors.border.withValues(alpha: 0.9), height: 1),
        const SizedBox(height: 10),
        Text(
          '\$$yearlyPrice',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ ${strings.annually.toLowerCase()} ($yearlySave)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _PlanActionButton(
          label: isSelected ? strings.currentPlan : strings.choosePlan,
          accent: accent,
          selected: isSelected,
          onChoose: onChoose,
        ),
      ],
    );
  }
}

class _PlanActionButton extends StatelessWidget {
  const _PlanActionButton({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onChoose,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: selected
          ? ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onChoose,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: accent,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

class _PlanFeatures extends StatelessWidget {
  const _PlanFeatures({
    required this.features,
    required this.accent,
  });

  final List<String> features;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final platforms = [
      _PlatformData(Icons.language_rounded, strings.web),
      _PlatformData(Icons.phone_iphone_rounded, strings.ios),
      _PlatformData(Icons.android_rounded, strings.android),
      _PlatformData(Icons.laptop_windows_rounded, strings.windows),
      _PlatformData(Icons.laptop_mac_rounded, strings.mac),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: platforms
          .map(
            (platform) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7EAF0)),
                  ),
                  child: Icon(
                    platform.icon,
                    color: AppColors.mutedText,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  platform.label,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _PlatformData {
  const _PlatformData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _PlanData {
  const _PlanData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.soft,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color soft;
  final int monthlyPrice;
  final int yearlyPrice;
  final List<String> features;
  final bool isPopular;
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(12, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
