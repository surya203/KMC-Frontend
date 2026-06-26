import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
            "Our Community",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            "Building one of India's strongest medical alumni networks.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 35),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.3,
            children: const [
              _StatCard(
                icon: Icons.people_alt_outlined,
                number: "15,000+",
                title: "Alumni",
              ),
              _StatCard(
                icon: Icons.school_outlined,
                number: "60+",
                title: "Batches",
              ),
              _StatCard(
                icon: Icons.event_available_outlined,
                number: "1",
                title: "Upcoming Event",
              ),
              _StatCard(
                icon: Icons.public_outlined,
                number: "1000+",
                title: "Global Members",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String title;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.15),
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