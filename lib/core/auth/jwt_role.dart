import 'dart:convert';

import '../network/auth_service.dart';

/// Reads the `role` claim from a JWT access token without verifying the
/// signature (UI gating only; API still enforces auth).
String? roleFromAccessToken([String? accessToken]) {
  final token = accessToken ?? AuthService.tokens?.accessToken;
  if (token == null || token.isEmpty) return null;

  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(normalized)))
            as Map<String, dynamic>;
    final role = payload['role'];
    if (role is String && role.trim().isNotEmpty) {
      return role.trim();
    }
  } catch (_) {
    return null;
  }
  return null;
}
