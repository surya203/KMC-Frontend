import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),

          Wrap(
            spacing: 25,
            runSpacing: 25,
            alignment: WrapAlignment.center,
            children: const [
              ActionCard(
                icon: Icons.people,
                title: "Alumni",
              ),
              ActionCard(
                icon: Icons.school,
                title: "Students",
              ),
              ActionCard(
                icon: Icons.event,
                title: "Events",
              ),
              ActionCard(
                icon: Icons.photo_library,
                title: "Gallery",
              ),
              ActionCard(
                icon: Icons.work,
                title: "Jobs",
              ),
              ActionCard(
                icon: Icons.campaign,
                title: "Announcements",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: AppColors.primary,
          ),

          const SizedBox(height: 15),

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}