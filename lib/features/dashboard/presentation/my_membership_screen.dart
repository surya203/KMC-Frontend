import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/business_info.dart';
import '../../../core/constants/donation_info.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/membership_number_format.dart';
import '../widgets/dashboard_layout.dart';
import '../../../core/utils/membership_tenure.dart';

class MyMembershipScreen extends StatefulWidget {
  const MyMembershipScreen({super.key});

  @override
  State<MyMembershipScreen> createState() => _MyMembershipScreenState();
}

class _MyMembershipScreenState extends State<MyMembershipScreen> {
  final _api = MembershipApiService();
  final _profilesApi = ProfilesApiService();

  MemberMembership? _membership;
  MyProfile? _profile;
  MembershipPlan? _plan;
  String? _error;
  bool _sessionExpired = false;
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
      _sessionExpired = false;
    });

    try {
      final membership = await _api.fetchMyMembership();
      MyProfile? profile;
      try {
        profile = await _profilesApi.fetchMyProfile();
      } catch (_) {
        profile = null;
      }
      MembershipPlan? plan;
      try {
        plan = await _api.fetchPlanBySlug(membership.planSlug);
      } catch (_) {
        plan = null;
      }
      if (!mounted) return;
      setState(() {
        _membership = membership;
        _profile = profile;
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final expired = isSessionExpiredError(e);
      if (expired) {
        await AuthSession.instance.clearSession();
      }
      if (!mounted) return;
      setState(() {
        _sessionExpired = expired;
        _error = friendlyApiError(e);
        _loading = false;
      });
    }
  }

  Future<void> _openDonateDialog() async {
    final amountController = TextEditingController();
    var donationType = 'general';
    String? projectCategory = DonationInfo.projectCategories.first.slug;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final maxHeight = MediaQuery.of(context).size.height * 0.7;
          return AlertDialog(
            title: const Text(DonationInfo.title),
            content: SizedBox(
              width: 420,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DonationInfo.summary,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.bodyText,
                        ),
                      ),
                      if (!DonationInfo.paymentsEnabled) ...[
                        const SizedBox(height: 10),
                        Text(
                          DonationInfo.paymentUnavailableMessage,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.45,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${BusinessInfo.email} · ${BusinessInfo.phone}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          hintText: 'e.g. 500',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('General Donation'),
                        value: 'general',
                        groupValue: donationType,
                        onChanged: (value) => setDialogState(
                          () => donationType = value ?? 'general',
                        ),
                      ),
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Project Donation'),
                        value: 'project',
                        groupValue: donationType,
                        onChanged: (value) => setDialogState(
                          () => donationType = value ?? 'project',
                        ),
                      ),
                      if (donationType == 'project') ...[
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: projectCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Project category (one only)',
                            isDense: true,
                          ),
                          items: [
                            for (final category in DonationInfo.projectCategories)
                              DropdownMenuItem(
                                value: category.slug,
                                child: Text(
                                  category.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => projectCategory = value,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  DonationInfo.paymentsEnabled
                      ? 'Continue to pay'
                      : 'Continue',
                ),
              ),
            ],
          );
        },
      ),
    );

    if (submitted != true || !mounted) return;

    final rupees = double.tryParse(amountController.text.trim());
    if (rupees == null || rupees < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount of at least ₹1.')),
      );
      return;
    }
    if (donationType == 'project' &&
        (projectCategory == null || projectCategory!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose exactly one project category.')),
      );
      return;
    }

    // Payment wiring comes later. Keep UI + validation ready.
    if (!DonationInfo.paymentsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${DonationInfo.paymentUnavailableMessage} '
            '${BusinessInfo.email}',
          ),
        ),
      );
      return;
    }

    // TODO: wire Razorpay donation checkout when paymentsEnabled is true.
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final membership = _membership;
    final isCompact = DashboardLayout.isCompact(context);

    return SingleChildScrollView(
      padding: DashboardLayout.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your lifetime KMC Alumni Association subscription.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openDonateDialog,
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('Donate'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your lifetime KMC Alumni Association subscription.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openDonateDialog,
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('Donate'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(
                  message: _error!,
                  sessionExpired: _sessionExpired,
                  onRetry: _load,
                  onSignIn: () => context.go('/auth'),
                ),
                const SizedBox(height: 16),
              ],
              if (membership != null) ...[
                _StatusCard(membership: membership),
                const SizedBox(height: 16),
                _RecordCard(membership: membership, profile: _profile),
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
            ],
          ),
          if (membership.votingRights)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Voting rights enabled',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.membership, this.profile});

  final MemberMembership membership;
  final MyProfile? profile;

  @override
  Widget build(BuildContext context) {
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
            'Membership record',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Membership ID',
            value: MembershipNumberFormat.displayOrFallback(
              storedMembershipNumber: membership.membershipNumber,
              batchYear: profile?.batchYear,
              fullName: profile?.fullName,
            ),
          ),
          _Field(
            label: 'Years as Member',
            value: MembershipTenure.displayLabel(
              membership: membership,
              batchYearFallback: profile?.batchYear,
            ),
          ),
          _Field(
            label: 'Registration Date',
            value: _formatIso(membership.registrationDate),
          ),
          _Field(
            label: 'Payment Date',
            value: _formatIso(membership.paymentDate),
          ),
          _Field(label: 'Fee', value: membership.feeDisplay),
        ],
      ),
    );
  }

  String _formatIso(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
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

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    this.sessionExpired = false,
    this.onSignIn,
  });

  final String message;
  final VoidCallback onRetry;
  final bool sessionExpired;
  final VoidCallback? onSignIn;

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
          if (sessionExpired && onSignIn != null)
            TextButton(onPressed: onSignIn, child: const Text('Sign in'))
          else
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
