import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';

@immutable
class MentorTimestamp {
  const MentorTimestamp._({
    required this.rawValue,
    required this.value,
    required this.hasExplicitOffset,
  });

  factory MentorTimestamp.parse(String rawValue) {
    final normalized = rawValue.trim();
    final hasExplicitOffset = RegExp(
      r'(?:[zZ]|[+-]\d{2}:?\d{2})$',
    ).hasMatch(normalized);
    // The Backend stores Mentor meeting instants in UTC but serializes some
    // PostgreSQL timestamps without an offset. Treat those as UTC, never as
    // the phone's local timezone.
    final value = DateTime.tryParse(
      hasExplicitOffset ? normalized : '${normalized}Z',
    );
    if (normalized.isEmpty || value == null) {
      throw const FormatException('Expected a valid Mentor timestamp.');
    }
    return MentorTimestamp._(
      rawValue: normalized,
      value: value,
      hasExplicitOffset: hasExplicitOffset,
    );
  }

  final String rawValue;
  final DateTime value;
  final bool hasExplicitOffset;

  /// Display all Mentor slots in Vietnam time, independent of device timezone.
  DateTime get displayValue => value.toUtc().add(const Duration(hours: 7));
}

@immutable
class MentorAvailabilitySlot {
  const MentorAvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.isApproved = true,
    this.bookedCount = 0,
  });

  final int id;
  final MentorTimestamp startTime;
  final MentorTimestamp endTime;
  final bool isBooked;
  final bool isApproved;
  final int bookedCount;
}

@immutable
class WeeklyPeriodItem {
  const WeeklyPeriodItem({required this.date, required this.period});

  final DateTime date;
  final String period; // "Morning", "Afternoon", "Evening"

  String get formattedDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get key => '$formattedDate#$period';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyPeriodItem &&
          runtimeType == other.runtimeType &&
          formattedDate == other.formattedDate &&
          period == other.period;

  @override
  int get hashCode => Object.hash(formattedDate, period);
}

@immutable
class WeeklyAvailabilityItem {
  const WeeklyAvailabilityItem({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.date,
    required this.period,
  });

  final int id;
  final int mentorId;
  final String mentorName;
  final DateTime date;
  final String period;

  String get formattedDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get key => '$formattedDate#$period';
}

enum MentorMeetingStatus {
  awaitingPayment('AwaitingPayment'),
  pendingAssignment('PendingAssignment'),
  assigned('Assigned'),
  accepted('Accepted'),
  completed('Completed'),
  cancelled('Cancelled'),
  unknown('Unknown');

  const MentorMeetingStatus(this.apiValue);

  final String apiValue;

  static MentorMeetingStatus fromApiValue(String value) {
    return values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => unknown,
    );
  }
}

@immutable
class MentorMeetingSummary {
  const MentorMeetingSummary({
    required this.id,
    required this.status,
    this.learnerName,
    this.scheduledAt,
    this.meetingLink,
  });

  final int id;
  final String? learnerName;
  final MentorTimestamp? scheduledAt;
  final MentorMeetingStatus status;
  final String? meetingLink;

  Uri? get safeMeetingUri {
    return parseSafeExternalHttpUri(meetingLink);
  }
}
