import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final _api = EventsApiService();
  List<MyEventRegistration> _registrations = [];
  String? _error;
  bool _loading = true;
  String? _cancellingId;

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
      final items = await _api.fetchMyRegistrations();
      if (!mounted) return;
      setState(() {
        _registrations = items;
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

  Future<void> _cancel(String eventId) async {
    setState(() => _cancellingId = eventId);
    try {
      await _api.cancelRegistration(eventId);
      if (!mounted) return;
      setState(() => _cancellingId = null);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancellingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _signOut() async {
    await AuthSession.instance.clearSession();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'My event registrations',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Text(
                        _error!,
                        style: GoogleFonts.inter(color: AppColors.bodyText),
                      )
                    : _registrations.isEmpty
                        ? Text(
                            'You have not registered for any events yet.',
                            style: GoogleFonts.inter(color: AppColors.bodyText),
                          )
                        : ListView.separated(
                            itemCount: _registrations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _registrations[index];
                              final isCancelling = _cancellingId == item.eventId;
                              return Material(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: AppColors.heading,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${item.displayDate} · ${item.displayVenue}',
                                        style: GoogleFonts.inter(
                                          color: AppColors.bodyText,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () =>
                                                context.go('/events/${item.slug}'),
                                            child: const Text('View event'),
                                          ),
                                          OutlinedButton(
                                            onPressed: isCancelling
                                                ? null
                                                : () => _cancel(item.eventId),
                                            child: isCancelling
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text('Cancel registration'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ),
    );
  }
}
