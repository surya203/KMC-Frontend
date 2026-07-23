import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/business_info.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _api = MembershipApiService();
  List<MembershipPlan> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _api.fetchPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load pricing. Please try again later.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              dark: true,
              eyebrow: 'Pricing',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                dark: true,
                regular: 'Membership fees.',
              ),
              subtitle:
                  'Membership fees are shown before checkout and processed '
                  'securely via Razorpay.',
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last updated: ${BusinessInfo.lastPolicyUpdate}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Text(
                          _error!,
                          style: GoogleFonts.inter(color: AppColors.error),
                        )
                      else if (_plans.isEmpty)
                        Text(
                          'Membership plans are currently being updated. '
                          'Please contact ${BusinessInfo.email} for details.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            height: 1.75,
                            color: AppColors.bodyText,
                          ),
                        )
                      else
                        ..._plans.map((plan) => _PlanCard(plan: plan)),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => context.go('/membership'),
                        child: const Text('Join MY KMC'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
              ),
              Text(
                plan.displayPrice,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              plan.description!,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.6,
                color: AppColors.bodyText,
              ),
            ),
          ],
          if (plan.prices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'International pricing',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: plan.prices
                  .map(
                    (p) => Text(
                      '${p.countryName}: ${p.displayPrice}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.bodyText,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (plan.benefits.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Includes',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 10),
            for (final benefit in plan.benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
