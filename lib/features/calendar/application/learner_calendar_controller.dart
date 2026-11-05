import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

final learnerCalendarEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
  final bookingsAsync =
      await ref.watch(learnerMentorBookingsControllerProvider.future);

  final events = <SakuraCalendarEvent>[];

  for (final booking in bookingsAsync) {
    if (booking.scheduledAt == null) continue;

    final start = booking.scheduledAt!.displayValue;
    // Authoritative JLPT 1-1 booking session is exactly 90 minutes
    final end = start.add(const Duration(minutes: 90));

    final title = booking.mentorName != null
        ? 'Tư vấn JLPT với ${booking.mentorName}'
        : 'Buổi tư vấn JLPT';

    final statusText = switch (booking.status) {
      MentorMeetingStatus.accepted => 'Đã xác nhận',
      MentorMeetingStatus.assigned => 'Đã phân công',
      MentorMeetingStatus.pendingAssignment => 'Chờ phân công',
      MentorMeetingStatus.awaitingPayment => 'Chờ thanh toán',
      MentorMeetingStatus.completed => 'Đã hoàn thành',
      MentorMeetingStatus.cancelled => 'Đã hủy',
      _ => 'Lịch hẹn',
    };

    events.add(
      SakuraCalendarEvent(
        id: 'booking_${booking.id}',
        title: title,
        subtitle: booking.jlptLevel != null ? 'Trình độ: ${booking.jlptLevel}' : null,
        startTime: start,
        endTime: end,
        type: SakuraCalendarEventType.consultation,
        status: booking.status,
        statusLabel: statusText,
        participantName: booking.mentorName,
        participantRole: 'Cố vấn chuyên môn',
        jlptLevel: booking.jlptLevel ?? 'JLPT N3',
        meetingLink: booking.meetingLink,
        roomId: booking.roomId,
        bookingId: booking.id,
        notes: 'Thời lượng buổi tư vấn: 90 phút. Vui lòng vào phòng học đúng giờ.',
      ),
    );
  }

  // Sort chronologically
  events.sort((a, b) => a.startTime.compareTo(b.startTime));
  return events;
});
