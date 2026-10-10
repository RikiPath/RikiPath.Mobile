import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

@immutable
class UpcomingMeeting {
  const UpcomingMeeting({
    required this.bookingId,
    required this.scheduledAt,
    required this.meetingUri,
    required this.status,
    this.mentorName,
  });

  final int bookingId;
  final MentorTimestamp scheduledAt;
  final Uri meetingUri;
  final MentorMeetingStatus status;
  final String? mentorName;
}
