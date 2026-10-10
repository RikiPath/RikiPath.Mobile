import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

final meetingNowProvider = Provider<DateTime>((ref) => DateTime.now());

final upcomingMeetingProvider = Provider<AsyncValue<UpcomingMeeting?>>((ref) {
  final now = ref.watch(meetingNowProvider);
  return ref
      .watch(learnerMentorBookingsControllerProvider)
      .whenData((items) => selectUpcomingMeeting(items, now: now));
});

UpcomingMeeting? selectUpcomingMeeting(
  List<LearnerMentorBooking> items, {
  required DateTime now,
}) {
  final eligible =
      items.where((booking) {
        final scheduledAt = booking.scheduledAt?.displayValue;
        return booking.paymentStatus == MentorPaymentStatus.paid &&
            (booking.status == MentorMeetingStatus.assigned ||
                booking.status == MentorMeetingStatus.accepted) &&
            booking.safeMeetingUri != null &&
            scheduledAt != null &&
            !scheduledAt.isBefore(now);
      }).toList()..sort(
        (left, right) => left.scheduledAt!.displayValue.compareTo(
          right.scheduledAt!.displayValue,
        ),
      );
  if (eligible.isEmpty) return null;
  final booking = eligible.first;
  return UpcomingMeeting(
    bookingId: booking.id,
    scheduledAt: booking.scheduledAt!,
    meetingUri: booking.safeMeetingUri!,
    status: booking.status,
    mentorName: booking.mentorName,
  );
}
