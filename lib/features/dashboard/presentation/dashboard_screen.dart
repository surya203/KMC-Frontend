import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/announcements_api_service.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/utils/membership_tenure.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _membershipApi = MembershipApiService();
  final _profilesApi = ProfilesApiService();
  final _eventsApi = EventsApiService();
  final _announcementsApi = AnnouncementsApiService();

  MemberMembership? _membership;
  MyProfile? _profile;
  List<EventItem> _upcomingEvents = [];
  List<MyEventRegistration> _myEvents = [];
  List<AnnouncementItem> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
    });

    await AuthSession.instance.ensureReady();

    MemberMembership? membership;
    MyProfile? profile;
    List<EventItem> upcomingEvents = [];
    List<MyEventRegistration> myEvents = [];
    List<AnnouncementItem> announcements = [];

    try {
      membership = await _membershipApi.fetchMyMembership();
    } catch (_) {}

    try {
      profile = await _profilesApi.fetchMyProfile();
    } catch (_) {}

    try {
      upcomingEvents = await _eventsApi.fetchEvents(upcoming: true);
    } catch (_) {}

    try {
      myEvents = await _eventsApi.fetchMyRegistrations();
    } catch (_) {}

    try {
      announcements = await _announcementsApi.fetchAnnouncements();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _membership = membership;
      _profile = profile;
      _upcomingEvents = upcomingEvents;
      _myEvents = myEvents;
      _announcements = announcements;
      _loading = false;
    });
  }

  int get _profileCompletion => _profileCompletionPercent(_profile);

  /// Count registrations that represent attendance (exclude interest-only).
  static int _attendedEventCount(List<MyEventRegistration> registrations) {
    return registrations.where((r) => r.registrationKind != 'interest').length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                isCompact ? 16 : 20,
                isCompact ? 16 : 24,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(
                        profile: _profile,
                        membership: _membership,
                      ),
                      const SizedBox(height: 18),
                      _StatsGrid(
                        membership: _membership,
                        profile: _profile,
                        eventsAttended: _attendedEventCount(_myEvents),
                        profileCompletion: _profileCompletion,
                        batchYear:
                            _profile?.batchYear ??
                            AuthSession.instance.currentUser?.batchYear,
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 900;
                          if (!wide) {
                            return Column(
                              children: [
                                _SubscriptionCard(
                                  membership: _membership,
                                  completion: _profileCompletion,
                                ),
                                const SizedBox(height: 18),
                                _EventsChartCard(registrations: _myEvents),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _SubscriptionCard(
                                  membership: _membership,
                                  completion: _profileCompletion,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 3,
                                child: _EventsChartCard(
                                  registrations: _myEvents,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 900;
                          if (!wide) {
                            return Column(
                              children: [
                                _UpcomingReunionsCard(events: _upcomingEvents),
                                const SizedBox(height: 18),
                                _RecentNotificationsCard(
                                  announcements: _announcements,
                                ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _UpcomingReunionsCard(
                                  events: _upcomingEvents,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: _RecentNotificationsCard(
                                  announcements: _announcements,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _LatestAnnouncementsSection(
                        announcements: _announcements,
                      ),
                    ],
                  ),
                ),
              ),
            );
  }
}

int _profileCompletionPercent(MyProfile? profile) {
  if (profile == null) return 0;
  final fields = [
    profile.currentTitle,
    profile.organization,
    profile.city,
    profile.bio,
    profile.linkedinUrl,
    profile.photoUrl,
    profile.degree,
    profile.specialization,
    profile.phone,
  ];
  final filled = fields.where((f) => f != null && f.trim().isNotEmpty).length;
  return ((filled / fields.length) * 100).round();
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return 'Just now';
}

String _formatMembershipDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _membershipNumberLabel(
  MemberMembership? membership,
  MyProfile? profile,
) {
  final user = AuthSession.instance.currentUser;
  final storedNumber =
      membership?.membershipNumber ?? user?.membershipNumber;
  final batchYear = profile?.batchYear ?? user?.batchYear;
  final fullName = profile?.fullName ?? user?.fullName;

  return MembershipNumberFormat.displayOrFallback(
    storedMembershipNumber: storedNumber,
    batchYear: batchYear,
    fullName: fullName,
    fallback: membership?.status == 'active' || storedNumber != null
        ? '—'
        : 'Pending',
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.membership});

  final MyProfile? profile;
  final MemberMembership? membership;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final user = AuthSession.instance.currentUser;
    final name = profile?.fullName ?? user?.fullName ?? 'Member';
    final batch = profile?.batchYear ?? user?.batchYear;
    final spec = profile?.specialization;
    final subtitleParts = <String>[
      if (batch != null) 'Batch of $batch',
      if (spec != null && spec.isNotEmpty) spec,
      membership?.planName ?? 'Lifetime Member',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2A57), Color(0xFF102B53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: isCompact ? 14 : 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fraunces(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 32 : 52,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitleParts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: isCompact ? 14 : 16,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/my-profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x66FFFFFF)),
                ),
                child: const Text('View Profile'),
              ),
              ElevatedButton(
                onPressed: () => context.go('/my-events'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(
                  isCompact ? 'Annual Meet' : 'Register for Annual Meet',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.membership,
    required this.profile,
    required this.eventsAttended,
    required this.profileCompletion,
    this.batchYear,
  });

  final MemberMembership? membership;
  final MyProfile? profile;
  final int eventsAttended;
  final int profileCompletion;
  final int? batchYear;

  @override
  Widget build(BuildContext context) {
    final yearsMember = MembershipTenure.displayLabel(
      membership: membership,
      batchYearFallback: batchYear,
    );

    final items = [
      _StatCardData(
        icon: Icons.workspace_premium_outlined,
        title: _membershipNumberLabel(membership, profile),
        subtitle: 'Membership ID',
      ),
      _StatCardData(
        icon: Icons.event_outlined,
        title: '$eventsAttended',
        subtitle: 'Events Attended',
      ),
      _StatCardData(
        icon: Icons.calendar_today_outlined,
        title: yearsMember,
        subtitle: 'Years as Member',
      ),
      _StatCardData(
        icon: Icons.check_circle_outline_rounded,
        title: '$profileCompletion%',
        subtitle: 'Profile Complete',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 980
            ? 4
            : constraints.maxWidth > 420
                ? 2
                : 1;
        final aspectRatio = crossAxisCount == 4
            ? 1.7
            : crossAxisCount == 2
                ? 1.45
                : 2.4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, i) => _StatCard(item: items[i]),
        );
      },
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.membership,
    required this.completion,
  });

  final MemberMembership? membership;
  final int completion;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 22),
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
              Text(
                'Subscription',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  membership?.status == 'active' ? 'Active' : 'Pending',
                  style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            membership?.planName ?? 'Lifetime',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fraunces(
              fontSize: isCompact ? 28 : 40,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          Text(
            membership?.startedAt != null
                ? 'Activated ${_formatMembershipDate(membership!.startedAt!)}'
                : 'Lifetime membership',
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Profile completion',
                style: GoogleFonts.inter(
                  color: AppColors.bodyText,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$completion%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: AppColors.muted,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/my-membership'),
            child: const Text('Manage →'),
          ),
        ],
      ),
    );
  }
}

class _EventsChartCard extends StatelessWidget {
  const _EventsChartCard({required this.registrations});

  final List<MyEventRegistration> registrations;

  /// Count this member's attendance-style registrations per calendar year.
  static ({List<int> years, List<double> counts}) yearlyAttendance(
    List<MyEventRegistration> registrations, {
    int yearCount = 6,
  }) {
    final nowYear = DateTime.now().year;
    final years = List<int>.generate(yearCount, (i) => nowYear - (yearCount - 1 - i));
    final countsByYear = {for (final y in years) y: 0};

    // Prefer real attendance; also count RSVP ("registered") as attended intent.
    // Skip pure "interest" so the chart matches "Events Attended".
    for (final reg in registrations) {
      final kind = reg.registrationKind;
      if (kind == 'interest') continue;
      final year = reg.startsAt.toLocal().year;
      if (!countsByYear.containsKey(year)) continue;
      countsByYear[year] = countsByYear[year]! + 1;
    }

    return (
      years: years,
      counts: years.map((y) => countsByYear[y]!.toDouble()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final series = yearlyAttendance(registrations);
    final total = series.counts.fold<double>(0, (a, b) => a + b).toInt();

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events Attended',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'No attendance recorded in the last 6 years'
                          : 'Your attendance by year · $total total',
                      style: GoogleFonts.inter(
                        color: AppColors.bodyText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Yearly',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _EventsLineChartPainter(
                values: series.counts,
                labels: series.years.map((y) => '$y').toList(),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsLineChartPainter extends CustomPainter {
  _EventsLineChartPainter({
    required this.values,
    required this.labels,
  });

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.fold<double>(0, (a, b) => a > b ? a : b);
    final scaleMax = maxVal <= 0 ? 1.0 : maxVal;
    final chartHeight = size.height - 24;
    final stepX = values.length == 1 ? size.width / 2 : size.width / (values.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : i * stepX;
      final y = chartHeight - (values[i] / scaleMax) * (chartHeight - 12);
      points.add(Offset(x, y.clamp(8.0, chartHeight)));
    }

    final fillPath = Path()..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    final dotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final valueStyle = TextStyle(
      color: AppColors.heading,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorder);
      final count = values[i].round();
      final tp = TextPainter(
        text: TextSpan(text: '$count', style: valueStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height - 6));
    }

    final labelStyle = TextStyle(
      color: AppColors.mutedText,
      fontSize: 11,
    );
    for (var i = 0; i < labels.length && i < values.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = values.length == 1 ? size.width / 2 : i * stepX;
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EventsLineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}

class _UpcomingReunionsCard extends StatelessWidget {
  const _UpcomingReunionsCard({required this.events});

  final List<EventItem> events;

  @override
  Widget build(BuildContext context) {
    final event = events.isNotEmpty ? events.first : null;

    return Container(
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
              Expanded(
                child: Text(
                  'Upcoming Reunions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/my-events'),
                child: const Text('View all'),
              ),
            ],
          ),
          if (event == null)
            Text(
              'No upcoming events yet.',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stackVertically = constraints.maxWidth < 480;
                final image = ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: event.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.coverImageUrl!,
                          width: stackVertically ? double.infinity : 96,
                          height: stackVertically ? 140 : 72,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: stackVertically ? double.infinity : 96,
                          height: stackVertically ? 140 : 72,
                          color: AppColors.muted,
                          child: const Icon(Icons.event),
                        ),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.displayDate} · ${event.displayVenue}',
                      style: GoogleFonts.inter(
                        color: AppColors.bodyText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          context.go('/my-events/${event.slug}'),
                      child: const Text('Register'),
                    ),
                  ],
                );

                if (stackVertically) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      image,
                      const SizedBox(height: 14),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecentNotificationsCard extends StatelessWidget {
  const _RecentNotificationsCard({required this.announcements});

  final List<AnnouncementItem> announcements;

  @override
  Widget build(BuildContext context) {
    final items = announcements.take(4).toList();

    return Container(
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
            'Recent Notifications',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No notifications yet.',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            )
          else
            for (final item in items) ...[
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.muted,
                    child: Icon(
                      item.isRead ? Icons.mail_outline : Icons.mark_email_unread,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    _relativeTime(item.publishedAt),
                    style: GoogleFonts.inter(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => context.go('/announcements'),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _LatestAnnouncementsSection extends StatelessWidget {
  const _LatestAnnouncementsSection({required this.announcements});

  final List<AnnouncementItem> announcements;

  @override
  Widget build(BuildContext context) {
    final items = announcements.take(3).toList();
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Latest Announcements',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fraunces(
                  fontSize: isCompact ? 22 : 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                  height: 1.15,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/announcements'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 16,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'No announcements yet.',
            style: GoogleFonts.inter(color: AppColors.bodyText),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items) ...[
                      _AnnouncementTile(item: item),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: _AnnouncementTile(item: items[i])),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final AnnouncementItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/announcements'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.authorRoleLabel.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _relativeTime(item.publishedAt),
                style: GoogleFonts.inter(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatCardData item;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isCompact ? 14 : 16,
            backgroundColor: AppColors.background,
            child: Icon(
              item.icon,
              size: isCompact ? 16 : 18,
              color: AppColors.heading,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.title,
              maxLines: 1,
              style: GoogleFonts.fraunces(
                color: AppColors.heading,
                fontSize: item.title.length > 14
                    ? (isCompact ? 18 : 22)
                    : item.title.length > 10
                        ? (isCompact ? 22 : 28)
                        : (isCompact ? 30 : 44),
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.bodyText,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.icon,
    required this.title,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
}
