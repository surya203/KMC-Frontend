import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/admin_api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = AdminApiService();

  AnalyticsOverview? _overview;
  AnalyticsEngagement? _engagement;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSessionChanged);
    _load();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    if (AuthSession.instance.isAuthenticated &&
        (_error != null || (!_loading && _overview == null))) {
      _load();
    }
  }

  Future<void> _load({int attempt = 0}) async {
    await AuthSession.instance.ensureReady();

    if (!mounted) return;
    setState(() {
      _loading = attempt == 0;
      if (attempt == 0) _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchAnalyticsOverview(),
        _api.fetchAnalyticsEngagement(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as AnalyticsOverview;
        _engagement = results[1] as AnalyticsEngagement;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (attempt < 2 && _shouldRetry(e)) {
        await Future<void>.delayed(
          Duration(milliseconds: 500 * (attempt + 1)),
        );
        if (mounted) await _load(attempt: attempt + 1);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = _formatError(e);
        _loading = false;
      });
    }
  }

  bool _shouldRetry(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('admin request failed') ||
        message.contains('server error') ||
        message.contains('could not reach') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('sign in required');
  }

  String _formatError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final overview = _overview;
    final engagement = _engagement;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 900 ? 3 : (width > 375 ? 2 : 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics overview',
                style: GoogleFonts.fraunces(
                  fontSize: width < 375 ? 28 : 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Members, events, revenue, and verification queue.',
                style: GoogleFonts.inter(color: AppColors.bodyText),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (overview != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    final cards = [
                      _StatCard(
                        label: 'Total members',
                        value: '${overview.totalMembers}',
                        icon: Icons.people_outline,
                      ),
                      _StatCard(
                        label: 'Active memberships',
                        value: '${overview.activeMemberships}',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      _StatCard(
                        label: 'Pending verifications',
                        value: '${overview.pendingVerifications}',
                        icon: Icons.verified_user_outlined,
                        onTap: () => context.go('/admin/verifications'),
                      ),
                      _StatCard(
                        label: 'Published events',
                        value: '${overview.publishedEvents}',
                        icon: Icons.event_outlined,
                      ),
                      _StatCard(
                        label: 'Upcoming events',
                        value: '${overview.upcomingEvents}',
                        icon: Icons.upcoming_outlined,
                      ),
                      _StatCard(
                        label: 'Captured revenue',
                        value: overview.displayRevenue,
                        icon: Icons.payments_outlined,
                      ),
                    ];

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final card in cards)
                          SizedBox(width: cardWidth, child: card),
                      ],
                    );
                  },
                ),
              if (engagement != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Event engagement',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${engagement.totalEventRegistrations} total registrations · '
                        '${engagement.membersWithEventActivity} active members engaged',
                        style: GoogleFonts.inter(color: AppColors.bodyText),
                      ),
                      const SizedBox(height: 16),
                      if (engagement.events.isEmpty)
                        Text(
                          'No published events yet.',
                          style: GoogleFonts.inter(color: AppColors.mutedText),
                        )
                      else
                        for (final event in engagement.events.take(6))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${event.registeredCount}'
                                  '${event.capacity != null ? ' / ${event.capacity}' : ''} registered',
                                  style: GoogleFonts.inter(
                                    color: AppColors.mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 12),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
