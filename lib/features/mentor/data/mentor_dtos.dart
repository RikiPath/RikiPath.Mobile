import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

class MentorAvailabilityDto {
  const MentorAvailabilityDto({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.isApproved = true,
    this.bookedCount = 0,
  });

  factory MentorAvailabilityDto.fromJson(Map<String, Object?> json) {
    return MentorAvailabilityDto(
      id: _requiredPositiveInt(json, 'id'),
      startTime: MentorTimestamp.parse(_requiredString(json, 'startTime')),
      endTime: MentorTimestamp.parse(_requiredString(json, 'endTime')),
      isBooked: _requiredBool(json, 'isBooked'),
      isApproved: json['isApproved'] as bool? ?? true,
      bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final MentorTimestamp startTime;
  final MentorTimestamp endTime;
  final bool isBooked;
  final bool isApproved;
  final int bookedCount;

  MentorAvailabilitySlot toDomain() => MentorAvailabilitySlot(
    id: id,
    startTime: startTime,
    endTime: endTime,
    isBooked: isBooked,
    isApproved: isApproved,
    bookedCount: bookedCount,
  );
}

class WeeklyAvailabilityDto {
  const WeeklyAvailabilityDto({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.date,
    required this.period,
  });

  factory WeeklyAvailabilityDto.fromJson(Map<String, Object?> json) {
    final dateStr = _requiredString(json, 'date');
    final parsedDate = DateTime.parse(dateStr);
    return WeeklyAvailabilityDto(
      id: _requiredPositiveInt(json, 'id'),
      mentorId: _requiredPositiveInt(json, 'mentorId'),
      mentorName: _requiredString(json, 'mentorName'),
      date: parsedDate,
      period: _requiredString(json, 'period'),
    );
  }

  final int id;
  final int mentorId;
  final String mentorName;
  final DateTime date;
  final String period;

  WeeklyAvailabilityItem toDomain() => WeeklyAvailabilityItem(
    id: id,
    mentorId: mentorId,
    mentorName: mentorName,
    date: date,
    period: period,
  );
}

class MentorMeetingDto {
  const MentorMeetingDto({
    required this.id,
    required this.status,
    this.learnerName,
    this.scheduledAt,
    this.meetingLink,
  });

  factory MentorMeetingDto.fromJson(Map<String, Object?> json) {
    return MentorMeetingDto(
      id: _requiredPositiveInt(json, 'id'),
      learnerName: _optionalString(json, 'learnerName'),
      scheduledAt: switch (_optionalString(json, 'scheduledAt')) {
        final value? => MentorTimestamp.parse(value),
        null => null,
      },
      status: MentorMeetingStatus.fromApiValue(_requiredString(json, 'status')),
      meetingLink: _optionalString(json, 'meetingLink'),
    );
  }

  final int id;
  final String? learnerName;
  final MentorTimestamp? scheduledAt;
  final MentorMeetingStatus status;
  final String? meetingLink;

  MentorMeetingSummary toDomain() => MentorMeetingSummary(
    id: id,
    learnerName: learnerName,
    scheduledAt: scheduledAt,
    status: status,
    meetingLink: meetingLink,
  );
}

List<Map<String, Object?>> readMentorResultList(Object? body) {
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

int _requiredPositiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = switch (value) {
    int() => value,
    _ => null,
  };
  if (parsed == null || parsed <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return parsed;
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

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Expected a boolean field: $key.');
  return value;
}
