import 'package:flutter/material.dart';

import '../widgets/market_shared_widgets.dart';

class SubscriptionPlanPage extends StatelessWidget {
  const SubscriptionPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: Column(
        children: [
          const MarketPageHeader(
            title: 'Subscription Plan',
            isGradient: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                _CurrentPlanCard(),
                SizedBox(height: 24),
                Text(
                  'Available Plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2A4A),
                  ),
                ),
                SizedBox(height: 16),
                _PlanOption(
                  title: 'Starter',
                  price: 'Free',
                  features: [
                    'Up to 100 products',
                    'Basic reporting',
                    'Single store access',
                  ],
                  isCurrent: true,
                ),
                SizedBox(height: 16),
                _PlanOption(
                  title: 'Professional',
                  price: 'TSH 50,000/mo',
                  features: [
                    'Unlimited products',
                    'Advanced analytics',
                    'Multi-store management',
                    'Staff permissions',
                  ],
                  isCurrent: false,
                  highlight: true,
                ),
                SizedBox(height: 16),
                _PlanOption(
                  title: 'Enterprise',
                  price: 'Contact Us',
                  features: [
                    'Custom integrations',
                    'Dedicated support',
                    'Unlimited stores',
                    'API access',
                  ],
                  isCurrent: false,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Plan',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6F7887),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Starter Free',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1562E8),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF1562E8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            value: 0.4,
            backgroundColor: Color(0xFFF1F5FF),
            color: Color(0xFF1562E8),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          const Text(
            '40/100 products used',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6F7887),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.price,
    required this.features,
    required this.isCurrent,
    this.highlight = false,
  });

  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF1562E8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFF1562E8) : const Color(0xFFE4E8EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : const Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.white70 : const Color(0xFF1562E8),
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    isCurrent ? Icons.check_circle : Icons.check_circle_outline,
                    size: 18,
                    color: highlight ? Colors.white : const Color(0xFF1562E8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14.5,
                        color:
                            highlight ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
