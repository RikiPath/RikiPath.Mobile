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
    final value = DateTime.tryParse(normalized);
    if (normalized.isEmpty || value == null) {
      throw const FormatException('Expected a valid Mentor timestamp.');
    }
    final hasExplicitOffset = RegExp(
      r'(?:[zZ]|[+-]\d{2}:?\d{2})$',
    ).hasMatch(normalized);
    return MentorTimestamp._(
      rawValue: normalized,
      value: value,
      hasExplicitOffset: hasExplicitOffset,
    );
  }

  final String rawValue;
  final DateTime value;
  final bool hasExplicitOffset;

  /// Offset-aware values are safe to render in the device timezone. Values
  /// without an offset retain their server-provided wall-clock components.
  DateTime get displayValue => hasExplicitOffset ? value.toLocal() : value;
}

@immutable
class MentorAvailabilitySlot {
  const MentorAvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  final int id;
  final MentorTimestamp startTime;
  final MentorTimestamp endTime;
  final bool isBooked;
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
