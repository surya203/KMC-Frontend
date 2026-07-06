import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key, this.stats});

  final CommunityStats? stats;

  @override
  Widget build(BuildContext context) {
    final data = stats ?? CommunityStats.fallback;

    return Container(
      width: double.infinity,
      color: const Color(0xffF8FAFC),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 50,
      ),
      child: Column(
        children: [
          const Text(
            'Our Community',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Building one of India\'s strongest medical alumni networks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          if (data.fromApi) ...[
            const SizedBox(height: 8),
            Text(
              'Live stats from API',
              style: TextStyle(
                color: AppColors.success.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 35),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.3,
            children: [
              _StatCard(
                icon: Icons.people_alt_outlined,
                number: data.alumni,
                title: 'Alumni',
              ),
              _StatCard(
                icon: Icons.school_outlined,
                number: data.batches,
                title: 'Batches',
              ),
              _StatCard(
                icon: Icons.event_available_outlined,
                number: data.upcomingEvents,
                title: 'Upcoming Event',
              ),
              _StatCard(
                icon: Icons.public_outlined,
                number: data.globalMembers,
                title: 'Global Members',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.number,
    required this.title,
  });

  final IconData icon;
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
