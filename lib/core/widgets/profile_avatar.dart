import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../utils/membership_number_format.dart';
import '../utils/resilient_profile_image.dart';

/// Circular profile photo — prefers local bytes, then network URL.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.localBytes,
    this.networkUrl,
    required this.name,
    required this.size,
    this.cacheKey,
  });

  final Uint8List? localBytes;
  final String? networkUrl;
  final String name;
  final double size;
  final Object? cacheKey;

  String get _initial => MembershipNumberFormat.avatarInitial(name);

  @override
  Widget build(BuildContext context) {
    final bytes = localBytes;

    Widget child;
    if (bytes != null && bytes.isNotEmpty) {
      child = Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        key: ValueKey(cacheKey ?? bytes.length),
        errorBuilder: (_, _, _) => _networkOrPlaceholder(),
      );
    } else {
      child = _networkOrPlaceholder();
    }

    return ClipOval(
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _networkOrPlaceholder() {
    final url = networkUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ResilientProfileImage(
        photoUrl: url,
        width: size,
        height: size,
        fallback: _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.muted,
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: GoogleFonts.fraunces(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
        ),
      ),
    );
  }
}

String formatUserError(Object error) {
  if (error is FormatException) return error.message;
  return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
