import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

final meetingNowProvider = Provider<DateTime>((ref) => DateTime.now());

final upcomingMeetingProvider = Provider<AsyncValue<UpcomingMeeting?>>((ref) {
  final now = ref.watch(meetingNowProvider);
  return ref
      .watch(learnerMyCoursesProvider)
      .whenData((courses) => selectUpcomingCohortMeeting(courses, now: now));
});

UpcomingMeeting? selectUpcomingCohortMeeting(
  List<LearnerStudyCourseDetail> courses, {
  required DateTime now,
}) {
  final candidates = <({
    LearnerStudyCourseDetail course,
    CourseSessionItem session,
    Uri uri,
  })>[];

  for (final course in courses) {
    if (course.status == 'Cancelled' || course.paymentStatus != 'Paid') {
      continue;
    }
    for (final session in course.sessions) {
      if (session.status != 'Scheduled') continue;
      final sessionEnd = session.scheduledAt.add(
        Duration(minutes: course.sessionMinutes > 0 ? course.sessionMinutes : 90),
      );
      if (!sessionEnd.isAfter(now)) continue;
      final uri = parseSafeExternalHttpUri(session.meetingUrl);
      if (uri == null) continue;
      candidates.add((course: course, session: session, uri: uri));
    }
  }

  if (candidates.isEmpty) return null;
  candidates.sort(
    (a, b) => a.session.scheduledAt.compareTo(b.session.scheduledAt),
  );
  final next = candidates.first;
  return UpcomingMeeting(
    bookingId: next.course.id,
    scheduledAt: MentorTimestamp.parse(
      next.session.scheduledAt.toUtc().toIso8601String(),
    ),
    meetingUri: next.uri,
    status: MentorMeetingStatus.accepted,
    mentorName: next.course.mentorName,
    courseName: next.course.name,
  );
}
