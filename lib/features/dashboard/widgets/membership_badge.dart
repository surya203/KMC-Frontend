import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/auth_service.dart';

class MembershipBadge extends StatelessWidget {
  const MembershipBadge({super.key, required this.membership});

  final MembershipSummary membership;

  @override
  Widget build(BuildContext context) {
    final isActive = membership.status.toLowerCase() == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.muted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isActive ? AppColors.primary : AppColors.border,
            child: Icon(
              isActive ? Icons.verified : Icons.hourglass_top,
              color: isActive ? Colors.white : AppColors.bodyText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership.planName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(membership.status),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.bodyText,
                  ),
                ),
                if (membership.votingRights) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Voting rights enabled',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active member';
      case 'pending':
        return 'Membership pending';
      default:
        return status;
    }
  }
}
