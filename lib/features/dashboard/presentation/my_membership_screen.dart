import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/payment/razorpay_checkout.dart';

class MyMembershipScreen extends StatefulWidget {
  const MyMembershipScreen({super.key});

  @override
  State<MyMembershipScreen> createState() => _MyMembershipScreenState();
}

class _MyMembershipScreenState extends State<MyMembershipScreen> {
  final _api = MembershipApiService();

  MemberMembership? _membership;
  MembershipPlan? _plan;
  List<DonationCategory> _categories = [];
  List<DonationRecord> _donations = [];
  String? _error;
  bool _loading = true;
  bool _donating = false;

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
      var categories = <DonationCategory>[];
      var donations = <DonationRecord>[];
      try {
        plan = await _api.fetchPlanBySlug(membership.planSlug);
      } catch (_) {
        plan = null;
      }
      try {
        categories = await _api.fetchDonationCategories();
        donations = await _api.fetchMyDonations();
      } catch (_) {
        // Record still shows if donations table is not migrated yet.
      }
      if (!mounted) return;
      setState(() {
        _membership = membership;
        _plan = plan;
        _categories = categories;
        _donations = donations;
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

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Future<void> _openDonateDialog() async {
    if (_categories.isEmpty) {
      try {
        _categories = await _api.fetchDonationCategories();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
    }
    if (!mounted) return;

    final amountController = TextEditingController();
    var donationType = 'general';
    String? projectCategory =
        _categories.isEmpty ? null : _categories.first.slug;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final maxHeight = MediaQuery.of(context).size.height * 0.7;
          return AlertDialog(
            title: const Text('Make a donation'),
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
                        'Donate as a general donation, or to exactly one project.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.bodyText,
                        ),
                      ),
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
                            for (final category in _categories)
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
                child: const Text('Continue to pay'),
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

    final amountPaise = (rupees * 100).round();
    setState(() => _donating = true);

    try {
      final checkout = await _api.createDonationCheckout(
        amountPaise: amountPaise,
        donationType: donationType,
        projectCategory:
            donationType == 'project' ? projectCategory : null,
      );

      final user = AuthSession.instance.currentUser;
      if (checkout.keyId.isNotEmpty) {
        await openRazorpayCheckout(
          keyId: checkout.keyId,
          orderId: checkout.orderId,
          amountPaise: checkout.amountPaise,
          currency: checkout.currency,
          name: user?.fullName ?? 'KMC Alumni',
          email: user?.email ?? '',
          onSuccess: () async {
            try {
              final message = await _api.completeDonation(checkout.orderId);
              await _load();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          },
          onDismiss: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      } else {
        final message = await _api.completeDonation(checkout.orderId);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _donating = false);
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
              Row(
                children: [
                  Expanded(
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
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _donating ? null : _openDonateDialog,
                    icon: _donating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.volunteer_activism_outlined),
                    label: Text(_donating ? 'Processing…' : 'Donate'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (membership != null) ...[
                _StatusCard(membership: membership),
                const SizedBox(height: 16),
                _RecordCard(membership: membership),
                const SizedBox(height: 16),
                _PlanCard(membership: membership, plan: _plan),
                if (membership.projectDonations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ProjectDonationsCard(membership: membership),
                ],
                if (_donations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DonationHistoryCard(donations: _donations, formatDate: _formatDate),
                ],
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
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.membership});

  final MemberMembership membership;

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
            label: 'Membership Number',
            value: membership.membershipNumber ?? '—',
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
          _Field(
            label: 'General Donation',
            value: membership.generalDonationDisplay,
          ),
          _Field(
            label: 'Project Donation',
            value: membership.projectDonationDisplay,
          ),
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

class _ProjectDonationsCard extends StatelessWidget {
  const _ProjectDonationsCard({required this.membership});

  final MemberMembership membership;

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
            'Project donations by category',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in membership.projectDonations)
            _Field(
              label: item.label,
              value: '₹${(item.totalPaise / 100).toStringAsFixed(
                item.totalPaise % 100 == 0 ? 0 : 2,
              )}',
            ),
        ],
      ),
    );
  }
}

class _DonationHistoryCard extends StatelessWidget {
  const _DonationHistoryCard({
    required this.donations,
    required this.formatDate,
  });

  final List<DonationRecord> donations;
  final String Function(String?) formatDate;

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
            'Donation history',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          for (final donation in donations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(donation.title),
              subtitle: Text(
                '${donation.status} · ${formatDate(donation.capturedAt ?? donation.createdAt)}',
              ),
              trailing: Text(donation.amountDisplay),
            ),
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
