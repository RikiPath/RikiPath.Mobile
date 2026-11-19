import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';

class BookableMentorDto {
  const BookableMentorDto({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.headline,
    this.bio,
    this.jlptLevels = const [],
    this.teachingMethod,
  });

  factory BookableMentorDto.fromJson(Map<String, Object?> json) {
    final rawJlpt =
        json['teachingJlptLevels'] ?? json['jlptLevel'] ?? json['jlptLevels'];
    final jlptList = <String>[];
    if (rawJlpt is String && rawJlpt.trim().isNotEmpty) {
      jlptList.add(rawJlpt.trim());
    } else if (rawJlpt is List) {
      jlptList.addAll(
        rawJlpt.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );
    }
    return BookableMentorDto(
      id:
          _optionalPositiveInt(json, 'mentorId') ??
          _requiredPositiveInt(json, 'id'),
      name: _requiredString(json, 'name'),
      avatarUrl: _optionalString(json, 'avatarUrl'),
      headline:
          _optionalString(json, 'expertise') ??
          _optionalString(json, 'headline'),
      bio: _optionalString(json, 'bio'),
      jlptLevels: jlptList,
      teachingMethod:
          _optionalString(json, 'workplace') ??
          _optionalString(json, 'teachingMethod'),
    );
  }

  final int id;
  final String name;
  final String? avatarUrl;
  final String? headline;
  final String? bio;
  final List<String> jlptLevels;
  final String? teachingMethod;

  BookableMentor toDomain() => BookableMentor(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    headline: headline,
    bio: bio,
    jlptLevels: jlptLevels,
    teachingMethod: teachingMethod,
  );
}

List<Map<String, Object?>> readLearnerMentorResultList(Object? body) {
  final envelope = _readEnvelope(body);
  var result = envelope['result'] ?? envelope['data'];
  if (result is Map<Object?, Object?> && result['items'] is List<Object?>) {
    result = result['items'];
  }
  if (result is! List<Object?>) {
    throw const FormatException('Expected a Mentor result list.');
  }
  return result
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw const FormatException('Expected a Mentor result item.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

Map<String, Object?> readLearnerMentorResultMap(Object? body) {
  final envelope = _readEnvelope(body);
  final result = envelope['result'] ?? envelope['data'];
  if (result is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor result object.');
  }
  return result.map((key, value) => MapEntry(key.toString(), value));
}

Map<Object?, Object?> _readEnvelope(Object? body) {
  if (body is! Map<Object?, Object?> || body['isSuccess'] != true) {
    throw const FormatException('Expected a successful Mentor API envelope.');
  }
  return body;
}

int _requiredPositiveInt(Map<String, Object?> json, String key) {
  final value = _readInt(json[key]);
  if (value == null || value <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return value;
}

int? _optionalPositiveInt(Map<String, Object?> json, String key) {
  final raw = json[key];
  if (raw == null) return null;
  final value = _readInt(raw);
  if (value == null || value <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return value;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) throw FormatException('Expected a string field: $key.');
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Expected a string field: $key.');
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
