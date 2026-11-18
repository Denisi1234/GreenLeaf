import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/harakapay_service.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class SubscriptionPlanItem {
  final String id;
  final String title;
  final String subtitle;
  final int storeLimit;
  final int priceTzs;
  final List<String> features;
  final bool isPopular;
  final IconData icon;

  const SubscriptionPlanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.storeLimit,
    required this.priceTzs,
    required this.features,
    this.isPopular = false,
    this.icon = Icons.storefront_rounded,
  });
}

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  String _selectedPlanId = 'stores_2';

  List<SubscriptionPlanItem> _getPlans(bool isSwahili) {
    return [
      SubscriptionPlanItem(
        id: 'stores_2',
        title: isSwahili ? 'Maduka 2' : '2 Stores',
        subtitle: isSwahili ? 'Inafaa kwa biashara inayokua na matawi 2' : 'Ideal for growing business with 2 outlets',
        storeLimit: 2,
        priceTzs: 10000,
        icon: Icons.store_mall_directory_rounded,
        features: [
          isSwahili ? 'Maduka 2 kamili (Matawi 2)' : 'Up to 2 separate store outlets',
          isSwahili ? 'Mauzo na Stoo tofauti kwa kila duka' : 'Independent sales & inventory tracking',
          isSwahili ? 'Wafanyakazi wasio na kikomo' : 'Unlimited staff accounts',
          isSwahili ? 'Ripoti za kila siku za SMS & PDF' : 'Daily SMS & PDF business reports',
          isSwahili ? 'Ufikiaji wa Simu & Kompyuta' : 'Cross-platform mobile & desktop access',
        ],
      ),
      SubscriptionPlanItem(
        id: 'stores_5',
        title: isSwahili ? 'Maduka 5' : '5 Stores',
        subtitle: isSwahili ? 'Kwa wamiliki wa maduka au matawi mengi' : 'For businesses with multi-branch chain',
        storeLimit: 5,
        priceTzs: 15000,
        isPopular: true,
        icon: Icons.apartment_rounded,
        features: [
          isSwahili ? 'Maduka 5 kamili (Matawi 5)' : 'Up to 5 separate store outlets',
          isSwahili ? 'Usimamizi wa Stoo na Uhamisho wa bidhaa' : 'Full branch transfer & warehouse sync',
          isSwahili ? 'Mwenye duka kuona ripoti zote pamoja' : 'Unified multi-branch owner dashboard',
          isSwahili ? 'Wafanyakazi wasio na kikomo' : 'Unlimited staff accounts',
          isSwahili ? 'Msaada wa kipaumbele wa WhatsApp' : 'Priority WhatsApp & phone support',
        ],
      ),
    ];
  }

  void _showCheckoutSheet(SubscriptionPlanItem plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HarakaPayCheckoutSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final isSw = store.languageCode.trim().toLowerCase() == 'sw';
    final currentSub = store.subscription;
    final plans = _getPlans(isSw);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F9),
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: isSw ? 'Vifurushi vya Maduka' : 'Store Subscriptions',
              subtitle: isSw
                  ? 'Boresha idadi ya maduka na matawi yako'
                  : 'Upgrade your outlets & multi-store capacity',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  // Current Active Plan Status Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF0F172A), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSw ? 'Kifurushi Chako cha Sasa' : 'Your Current Subscription',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSub.planName,
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSw
                                    ? 'Unatumia maduka ${store.stores.length} kati ya ${currentSub.maxStores}'
                                    : 'Using ${store.stores.length} of ${currentSub.maxStores} allowed stores',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Plans Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      isSw ? 'Chagua Kifurushi cha Kulipia' : 'Choose Your Store Plan',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  // List of Plans
                  for (final plan in plans) ...[
                    _PlanOptionCard(
                      plan: plan,
                      isSwahili: isSw,
                      isSelected: _selectedPlanId == plan.id,
                      isCurrent: currentSub.planId == plan.id,
                      onTap: () {
                        setState(() => _selectedPlanId = plan.id);
                        _showCheckoutSheet(plan);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 10),

                  // Mobile Money Provider Badges
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isSw
                              ? 'Malipo ya Haraka kwa Simu (USSD Push)'
                              : 'Instant Mobile Money Payment (USSD Push)',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSw
                              ? 'Ingiza namba yako, utapokea ujumbe moja kwa moja kwenye simu yako uweke PIN bila wasiwasi.'
                              : 'Enter your phone number to receive a secure USSD pop-up instantly on your screen to authorize with PIN.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildNetworkBadge('M-Pesa (Vodacom)', const Color(0xFFE60000)),
                            _buildNetworkBadge('Tigo Pesa', const Color(0xFF00377B)),
                            _buildNetworkBadge('Airtel Money', const Color(0xFFFF0000)),
                            _buildNetworkBadge('HaloPesa', const Color(0xFFFF6F00)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkBadge(String name, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.plan,
    required this.isSwahili,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  final SubscriptionPlanItem plan;
  final bool isSwahili;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: Colors.white,
      borderColor: plan.isPopular ? const Color(0xFF0F172A) : const Color(0xFFD6E4F0),
      radius: 12,
      padding: EdgeInsets.zero,
      showShadow: true,
      child: Stack(
        children: [
          if (plan.isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(11),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Text(
                  isSwahili ? 'INAPENDWA' : 'POPULAR',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(plan.icon, color: const Color(0xFF0F172A), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.subtitle,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Tsh ${_formatNumber(plan.priceTzs)}',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSwahili ? '/ kwa mwezi' : '/ per month',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                for (final feat in plan.features) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isCurrent ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onTap,
                    child: Text(
                      isCurrent
                          ? (isSwahili ? 'Kifurushi Chako cha Sasa' : 'Current Active Plan')
                          : (isSwahili ? 'Lipia Sasa (Tsh ${_formatNumber(plan.priceTzs)})' : 'Pay Now (Tsh ${_formatNumber(plan.priceTzs)})'),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class _HarakaPayCheckoutSheet extends StatefulWidget {
  const _HarakaPayCheckoutSheet({required this.plan});
  final SubscriptionPlanItem plan;

  @override
  State<_HarakaPayCheckoutSheet> createState() => _HarakaPayCheckoutSheetState();
}

enum _CheckoutStep { input, waitingPush, success, error }

class _HarakaPayCheckoutSheetState extends State<_HarakaPayCheckoutSheet> {
  final TextEditingController _phoneController = TextEditingController();
  _CheckoutStep _step = _CheckoutStep.input;
  String _errorMessage = '';
  String? _orderId;
  Timer? _pollingTimer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    final profile = context.read<PosLocalStore>().profile;
    if (profile.contactNumber.trim().isNotEmpty) {
      _phoneController.text = HarakaPayService.instance.formatPhoneNumber(profile.contactNumber);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _step = _CheckoutStep.error;
        _errorMessage = 'Tafadhali weka namba ya simu ya kulipia.';
      });
      return;
    }

    setState(() {
      _step = _CheckoutStep.waitingPush;
      _secondsLeft = 60;
      _errorMessage = '';
    });

    final res = await HarakaPayService.instance.triggerUssdPush(
      phone: phone,
      amount: widget.plan.priceTzs.toDouble(),
      description: 'GreenLeaf ${widget.plan.title} Subscription',
    );

    if (!mounted) return;

    if (!res.success || res.orderId == null) {
      setState(() {
        _step = _CheckoutStep.error;
        _errorMessage = res.message;
      });
      return;
    }

    _orderId = res.orderId;
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsLeft -= 4;
      });

      if (_secondsLeft <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _step = _CheckoutStep.error;
            _errorMessage = 'Muda wa malipo umekwisha. Kama umekatwa pesa, tafadhali wasiliana nasi na uthibitishe.';
          });
        }
        return;
      }

      final check = await HarakaPayService.instance.checkStatus(_orderId!);
      if (!mounted) return;

      if (check.isCompleted) {
        timer.cancel();
        final store = context.read<PosLocalStore>();
        await store.activateSubscription(
          planId: widget.plan.id,
          planName: widget.plan.title,
          maxStores: widget.plan.storeLimit,
          priceTzs: widget.plan.priceTzs.toDouble(),
          orderId: _orderId!,
          phoneNumber: _phoneController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _step = _CheckoutStep.success;
          });
        }
      } else if (check.isFailed) {
        timer.cancel();
        setState(() {
          _step = _CheckoutStep.error;
          _errorMessage = check.error ?? 'Malipo yamekataliwa au yameshindikana.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final isSw = store.languageCode.trim().toLowerCase() == 'sw';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_step == _CheckoutStep.input) _buildInputView(isSw),
            if (_step == _CheckoutStep.waitingPush) _buildWaitingPushView(isSw),
            if (_step == _CheckoutStep.success) _buildSuccessView(isSw),
            if (_step == _CheckoutStep.error) _buildErrorView(isSw),
          ],
        ),
      ),
    );
  }

  Widget _buildInputView(bool isSw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSw ? 'Malipo ya Kifurushi' : 'Plan Checkout',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.plan.title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isSw
              ? 'Kiasi cha Kulipa: Tsh ${widget.plan.priceTzs}'
              : 'Amount to pay: Tsh ${widget.plan.priceTzs}',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Namba ya Simu ya Malipo' : 'Mobile Money Phone Number',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'mf. 07XXXXXXXX au 06XXXXXXXX',
            hintStyle: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF0F172A)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSw
              ? 'M-Pesa (Vodacom), Tigo Pesa, Airtel Money, au HaloPesa.'
              : 'Supports Vodacom M-Pesa, Tigo Pesa, Airtel Money & HaloPesa.',
          style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _startPayment,
            child: Text(
              isSw ? 'Tuma Ombi la USSD Kwenye Simu' : 'Send USSD Push Prompt',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingPushView(bool isSw) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Tafadhali Ingiza PIN Kwenye Simu Yako' : 'Please Enter PIN on Your Phone',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSw
              ? 'Tumetuma ombi la USSD kwenye namba ${_phoneController.text}. Tafadhali angalia screen ya simu yako na uweke PIN ili kukamilisha malipo.'
              : 'A USSD push prompt was sent to ${_phoneController.text}. Please check your phone screen and enter your PIN.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isSw ? 'Inasubiri uthibitisho... ($_secondsLeft s)' : 'Waiting for confirmation... ($_secondsLeft s)',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuccessView(bool isSw) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Hongera! Malipo Yamekamilika!' : 'Payment Successful!',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSw
              ? 'Kifurushi chako cha "${widget.plan.title}" (maduka ${widget.plan.storeLimit}) kimewashwa kikamilifu.'
              : 'Your plan "${widget.plan.title}" (up to ${widget.plan.storeLimit} stores) is now active.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isSw ? 'Funga na Uanze Kutumia' : 'Done & Start Using',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(bool isSw) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Hitilafu ya Malipo' : 'Payment Issue',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage.isNotEmpty
              ? _errorMessage
              : (isSw ? 'Malipo hayakukamilika. Tafadhali jaribu tena.' : 'Payment could not be completed. Please try again.'),
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isSw ? 'Ghairi' : 'Cancel',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() => _step = _CheckoutStep.input);
                },
                child: Text(
                  isSw ? 'Jaribu Tena' : 'Try Again',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
