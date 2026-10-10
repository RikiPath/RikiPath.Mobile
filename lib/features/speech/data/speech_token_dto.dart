import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';

class SpeechTokenDto {
  const SpeechTokenDto({
    required this.token,
    required this.region,
    required this.language,
    required this.expiresInSeconds,
  });

  factory SpeechTokenDto.fromEnvelope(Object? body) {
    if (body is! Map<Object?, Object?> || body['isSuccess'] != true) {
      throw const FormatException('Expected a successful Speech envelope.');
    }
    final result = body['result'];
    if (result is! Map<Object?, Object?>) {
      throw const FormatException('Expected a Speech token result.');
    }

    return SpeechTokenDto(
      token: _requiredString(result, 'token'),
      region: _requiredString(result, 'region'),
      language: _requiredString(result, 'language'),
      expiresInSeconds: _requiredPositiveInt(result, 'expiresInSeconds'),
    );
  }

  final String token;
  final String region;
  final String language;
  final int expiresInSeconds;

  SpeechToken toDomain() => SpeechToken(
    value: token,
    region: region,
    language: language,
    expiresInSeconds: expiresInSeconds,
  );
}

String _requiredString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected a non-empty string field: $key.');
  }
  return value.trim();
}

int _requiredPositiveInt(Map<Object?, Object?> json, String key) {
  final value = json[key];
  final parsed = switch (value) {
    int value => value,
    num value when value.isFinite && value == value.truncateToDouble() =>
      value.toInt(),
    _ => null,
  };
  if (parsed == null || parsed <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return parsed;
}
