import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../events/widgets/event_registrations_dialog.dart';

class AdminEventRegistrationsScreen extends StatelessWidget {
  const AdminEventRegistrationsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/admin/events'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to events'),
              ),
              const SizedBox(height: 8),
              Text(
                eventTitle,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Members who registered for this event.',
                style: GoogleFonts.inter(color: AppColors.bodyText),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.62,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: EventRegistrationsPanel(eventId: eventId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
