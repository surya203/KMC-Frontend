import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

/// Reconnect CTA card — matches Lovable client reference above the footer.
class ReconnectSection extends StatelessWidget {
  const ReconnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final titleSize = isCompact ? 34.0 : width < 900 ? 46.0 : 56.0;
    final quoteSize = isCompact ? 20.0 : width < 900 ? 26.0 : 30.0;
    final inset = isCompact ? 16.0 : 24.0;
    final innerH = isCompact ? 24.0 : 56.0;
    final innerV = isCompact ? 56.0 : 88.0;

    final gapBeforeFooter = isCompact ? 56.0 : 80.0;

    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(inset, 32, inset, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: innerH, vertical: innerV),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(
                      '"A platform that finally honors the legacy of our '
                      'institution. Reconnecting with my batch after 30 years '
                      'felt seamless."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: quoteSize,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '— Dr. Bhanu Prasad, Batch of 1985, Cardiothoracic Surgeon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: isCompact ? 13 : 15,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: isCompact ? 40 : 52),
                    Container(height: 1, width: 140, color: Colors.white24),
                    SizedBox(height: isCompact ? 40 : 52),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ready to ',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        ColoredBox(
                          color: AppColors.secondary,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 8 : 12,
                              vertical: isCompact ? 2 : 4,
                            ),
                            child: Text(
                              'reconnect?',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: titleSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 20 : 28),
                    Text(
                      'Verify your batch, claim your profile, and join thousands '
                      'of KMC alumni already on the platform.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: isCompact ? 15 : 18,
                        height: 1.7,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    SizedBox(height: isCompact ? 36 : 44),
                    Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go('/membership'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 22 : 32,
                              vertical: isCompact ? 16 : 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                            'Join Alumni Network',
                            style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontWeight: FontWeight.w700,
                              fontSize: isCompact ? 14 : 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/membership'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 22 : 32,
                              vertical: isCompact ? 16 : 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: Text(
                            'View Membership Tiers',
                            style: TextStyle(
                              fontFamily: 'Segoe UI',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: isCompact ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: gapBeforeFooter),
          ],
        ),
      ),
    );
  }
}
