import 'dart:convert';

import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';

/// Session claims copied into the backend-issued access token.
///
/// This parser only checks the local consistency and expiry of an already
/// received token. Cryptographic signature validation remains the backend's
/// responsibility; no signing secret belongs in a mobile application.
class JwtSessionClaims {
  const JwtSessionClaims({
    required this.userId,
    required this.role,
    required this.expiresAt,
  });

  factory JwtSessionClaims.parse(String token) {
    final segments = token.split('.');
    if (segments.length != 3 || segments.any((segment) => segment.isEmpty)) {
      throw const FormatException('Expected a three-segment JWT.');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('The JWT payload is not valid JSON.');
    }

    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('The JWT payload must be a JSON object.');
    }

    final userId = _readPositiveIntClaim(decoded, const <String>[
      'nameid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
    ]);
    final roleValue = _readStringClaim(decoded, const <String>[
      'role',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
    ]);
    final role = BackendUserRole.fromApiValue(roleValue);
    if (role == null) {
      throw FormatException('Unknown JWT role: $roleValue.');
    }

    final expiresAtSeconds = _readPositiveIntClaim(decoded, const <String>[
      'exp',
    ]);
    late final DateTime expiresAt;
    try {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiresAtSeconds * Duration.millisecondsPerSecond,
        isUtc: true,
      );
    } on RangeError {
      throw const FormatException('The JWT expiry is outside the valid range.');
    }
    return JwtSessionClaims(userId: userId, role: role, expiresAt: expiresAt);
  }

  final int userId;
  final BackendUserRole role;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime instant) => !instant.toUtc().isBefore(expiresAt);
}

int _readPositiveIntClaim(Map<Object?, Object?> payload, List<String> names) {
  final value = _firstClaim(payload, names);
  final parsed = switch (value) {
    int() => value,
    String() => int.tryParse(value),
    _ => null,
  };
  if (parsed == null || parsed <= 0) {
    throw FormatException(
      'Expected a positive integer JWT claim: ${names[0]}.',
    );
  }
  return parsed;
}

String _readStringClaim(Map<Object?, Object?> payload, List<String> names) {
  final value = _firstClaim(payload, names);
  if (value is! String || value.isEmpty) {
    throw FormatException('Expected a string JWT claim: ${names[0]}.');
  }
  return value;
}

Object? _firstClaim(Map<Object?, Object?> payload, List<String> names) {
  for (final name in names) {
    if (payload.containsKey(name)) return payload[name];
  }
  return null;
}
