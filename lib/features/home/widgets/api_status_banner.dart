import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ApiStatusBanner extends StatelessWidget {
  const ApiStatusBanner({super.key, required this.isHealthy});

  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isHealthy
          ? AppColors.success.withValues(alpha: 0.12)
          : AppColors.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 18,
            color: isHealthy ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isHealthy
                  ? 'Backend API connected (GET /health OK)'
                  : 'Backend API offline — showing default content. Start backend on port 8000.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isHealthy ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
