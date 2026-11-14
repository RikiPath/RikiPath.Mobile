import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

/// Reads the JSON `result` object from a standard RikiPath API envelope.
Map<String, Object?> readMentorEnvelopeObject(Object? body) {
  if (body is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor API response envelope.');
  }
  final result = body['result'];
  if (result is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor API result object.');
  }
  return result.map((key, value) => MapEntry(key.toString(), value));
}

/// Reads the JSON `result` list from a standard RikiPath API envelope.
List<Map<String, Object?>> readMentorEnvelopeList(Object? body) {
  if (body is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor API response envelope.');
  }
  final result = body['result'];
  if (result is! List<Object?>) {
    throw const FormatException('Expected a Mentor API result list.');
  }
  return result
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw const FormatException('Expected a Mentor API result object.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

int readRequiredPositiveInt(Map<String, Object?> json, String key) {
  final value = readOptionalInt(json, key);
  if (value == null || value <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return value;
}

int readIntOrZero(Map<String, Object?> json, String key) =>
    readOptionalInt(json, key) ?? 0;

int? readOptionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  throw FormatException('Expected an integer field: $key.');
}

double readDoubleOrZero(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  throw FormatException('Expected a numeric field: $key.');
}

String readRequiredString(Map<String, Object?> json, String key) {
  final value = readOptionalString(json, key);
  if (value == null) {
    throw FormatException('Expected a string field: $key.');
  }
  return value;
}

String readStringOrEmpty(Map<String, Object?> json, String key) =>
    readOptionalString(json, key) ?? '';

String? readOptionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Expected a string field: $key.');
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

bool readBoolOrFalse(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return false;
  if (value is bool) return value;
  throw FormatException('Expected a boolean field: $key.');
}

bool? readOptionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException('Expected a boolean field: $key.');
}

MentorTimestamp? readOptionalTimestamp(Map<String, Object?> json, String key) {
  final raw = readOptionalString(json, key);
  return raw == null ? null : MentorTimestamp.parse(raw);
}

MentorTimestamp readRequiredTimestamp(Map<String, Object?> json, String key) =>
    MentorTimestamp.parse(readRequiredString(json, key));

DateTime? readOptionalDateOnly(Map<String, Object?> json, String key) {
  final raw = readOptionalString(json, key);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

DateTime readRequiredDateOnly(Map<String, Object?> json, String key) {
  final raw = readRequiredString(json, key);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Expected a valid date field: $key.');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String formatDateOnly(DateTime value) {
  final d = DateTime(value.year, value.month, value.day);
  final year = d.year.toString().padLeft(4, '0');
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

Map<String, Object?> readMapOrEmpty(Object? raw) {
  if (raw is Map<Object?, Object?>) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
