import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';

class MyMembershipScreen extends StatefulWidget {
  const MyMembershipScreen({super.key});

  @override
  State<MyMembershipScreen> createState() => _MyMembershipScreenState();
}

class _MyMembershipScreenState extends State<MyMembershipScreen> {
  final _api = MembershipApiService();

  MemberMembership? _membership;
  MembershipPlan? _plan;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final membership = await _api.fetchMyMembership();
      MembershipPlan? plan;
      try {
        plan = await _api.fetchPlanBySlug(membership.planSlug);
      } catch (_) {
        plan = null;
      }
      if (!mounted) return;
      setState(() {
        _membership = membership;
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final membership = _membership;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Membership',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your lifetime KMC Alumni Association subscription.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (membership != null) ...[
                _StatusCard(membership: membership),
                const SizedBox(height: 16),
                _PlanCard(membership: membership, plan: _plan),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.go('/my-payments'),
                  child: const Text('View payment history'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.membership});

  final MemberMembership membership;

  @override
  Widget build(BuildContext context) {
    final isActive = membership.status == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.shade50
                      : AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  membership.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.green.shade800 : AppColors.bodyText,
                  ),
                ),
              ),
              const Spacer(),
              if (membership.votingRights)
                Text(
                  'Voting rights enabled',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            membership.planName,
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          if (membership.startedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Member since ${_formatDate(membership.startedAt!)}',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            ),
          ],
          if (membership.expiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expires ${_formatDate(membership.expiresAt!)}',
              style: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.membership, this.plan});

  final MemberMembership membership;
  final MembershipPlan? plan;

  @override
  Widget build(BuildContext context) {
    final benefits = plan?.benefits ?? const <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan benefits',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          if (plan?.description != null) ...[
            const SizedBox(height: 8),
            Text(
              plan!.description!,
              style: GoogleFonts.inter(
                color: AppColors.bodyText,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (benefits.isEmpty)
            Text(
              'Lifetime alumni network access for ${membership.planName}.',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            )
          else
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.inter(color: AppColors.bodyText),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 14),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
