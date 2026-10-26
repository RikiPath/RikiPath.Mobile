class DailyReviewQueueDto {
  const DailyReviewQueueDto({required this.totalDue, required this.items});

  factory DailyReviewQueueDto.fromJson(Map<String, Object?> json) {
    return DailyReviewQueueDto(
      totalDue: _requiredInt(json, 'totalDue'),
      items: _objectList(
        json['items'],
        'items',
      ).map(DailyReviewCardDto.fromJson).toList(growable: false),
    );
  }

  final int totalDue;
  final List<DailyReviewCardDto> items;
}

class DailyReviewCardDto {
  const DailyReviewCardDto({
    required this.reviewCardId,
    required this.contentType,
    required this.term,
    required this.reading,
    required this.meaning,
    required this.note,
    required this.repetitions,
    required this.nextReviewDate,
  });

  factory DailyReviewCardDto.fromJson(Map<String, Object?> json) {
    return DailyReviewCardDto(
      reviewCardId: _requiredInt(json, 'reviewCardId'),
      contentType: _requiredString(json, 'contentType'),
      term: _requiredString(json, 'term'),
      reading: _optionalString(json, 'reading'),
      meaning: _requiredString(json, 'meaning'),
      note: _optionalString(json, 'note'),
      repetitions: _requiredInt(json, 'repetitions'),
      nextReviewDate: _requiredDateTime(json, 'nextReviewDate'),
    );
  }

  final int reviewCardId;
  final String contentType;
  final String term;
  final String? reading;
  final String meaning;
  final String? note;
  final int repetitions;
  final DateTime nextReviewDate;
}

class DailyReviewSubmitResultDto {
  const DailyReviewSubmitResultDto({
    required this.reviewCardId,
    required this.qualitySubmitted,
    required this.shouldRepeatInSession,
    required this.newEaseFactor,
    required this.newIntervalDays,
    required this.repetitions,
    required this.nextReviewDate,
  });

  factory DailyReviewSubmitResultDto.fromJson(Map<String, Object?> json) {
    return DailyReviewSubmitResultDto(
      reviewCardId: _requiredInt(json, 'reviewCardId'),
      qualitySubmitted: _requiredInt(json, 'qualitySubmitted'),
      shouldRepeatInSession: _requiredBool(json, 'shouldRepeatInSession'),
      newEaseFactor: _requiredDouble(json, 'newEaseFactor'),
      newIntervalDays: _requiredInt(json, 'newIntervalDays'),
      repetitions: _requiredInt(json, 'repetitions'),
      nextReviewDate: _requiredDateTime(json, 'nextReviewDate'),
    );
  }

  final int reviewCardId;
  final int qualitySubmitted;
  final bool shouldRepeatInSession;
  final double newEaseFactor;
  final int newIntervalDays;
  final int repetitions;
  final DateTime nextReviewDate;
}

DailyReviewQueueDto readDailyReviewQueue(Object? body) {
  return DailyReviewQueueDto.fromJson(_successfulResult(body));
}

DailyReviewSubmitResultDto readDailyReviewSubmitResult(Object? body) {
  return DailyReviewSubmitResultDto.fromJson(_successfulResult(body));
}

Map<String, Object?> _successfulResult(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful review envelope.');
  }
  return _stringKeyedMap(envelope['result']);
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.map((key, item) {
    if (key is! String) throw const FormatException('Expected string keys.');
    return MapEntry(key, item);
  });
}

List<Map<String, Object?>> _objectList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('Expected a list field named $field.');
  }
  return value.map(_stringKeyedMap).toList(growable: false);
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('Expected an integer field named $field.');
}

double _requiredDouble(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('Expected a numeric field named $field.');
}

bool _requiredBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw FormatException('Expected a boolean field named $field.');
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value as String?;
  throw FormatException('Expected a nullable string field named $field.');
}

DateTime _requiredDateTime(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! String) {
    throw FormatException('Expected a timestamp field named $field.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Expected a timestamp field named $field.');
  }
  if (parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
