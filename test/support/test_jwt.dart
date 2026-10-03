import 'dart:convert';

String createTestJwt({
  required int userId,
  required String role,
  DateTime? expiresAt,
  Map<String, Object?> additionalClaims = const <String, Object?>{},
}) {
  final header = _encode(<String, Object?>{'alg': 'HS512', 'typ': 'JWT'});
  final payload = _encode(<String, Object?>{
    'nameid': userId.toString(),
    'role': role,
    'exp':
        (expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 1)))
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerSecond,
    ...additionalClaims,
  });
  return '$header.$payload.test-signature';
}

String _encode(Map<String, Object?> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
