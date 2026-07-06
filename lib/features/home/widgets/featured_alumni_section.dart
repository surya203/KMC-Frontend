import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'section_header.dart';

class FeaturedAlumniSection extends StatelessWidget {
  const FeaturedAlumniSection({super.key});

  static const _alumni = [
    (
      '“KMC shaped my career. The bonds I formed here remain my strongest support system.”',
      'Dr. Ramesh Reddy',
      'Chief Cardiologist, AIIMS Delhi · Batch 1992',
      'https://i.pravatar.cc/200?img=12',
    ),
    (
      '“Our alma mater taught us not just medicine, but compassion and excellence.”',
      'Dr. Priya Sharma',
      'Director of Pediatrics, Apollo Hospitals · Batch 2001',
      'https://i.pravatar.cc/200?img=47',
    ),
    (
      '“From Warangal to the world — proud KMC graduate and lifelong learner.”',
      'Dr. Arjun Kumar',
      'Neurosurgeon, Cleveland Clinic, USA · Batch 1988',
      'https://i.pravatar.cc/200?img=33',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              SectionHeader(
                eyebrow: 'Featured Alumni',
                regularTitle: 'From Warangal ',
                italicTitle: 'to',
                titleSuffix: ' the world.',
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _alumni.length; i++) ...[
                          if (i > 0) const SizedBox(width: 20),
                          Expanded(child: _AlumniCard(data: _alumni[i])),
                        ],
                      ],
                    );
                  }

                  return Column(
                    children: [
                      for (final person in _alumni) ...[
                        _AlumniCard(data: person),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlumniCard extends StatelessWidget {
  const _AlumniCard({required this.data});

  final (String, String, String, String) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.$1,
            style: GoogleFonts.fraunces(
              fontSize: 18,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.network(
                  data.$4,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.muted,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.$2,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.$3,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
