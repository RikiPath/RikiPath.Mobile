import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

final mentorCalendarEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
  final meetingsAsync =
      await ref.watch(mentorMeetingsControllerProvider.future);
  final availabilityAsync =
      await ref.watch(mentorAvailabilityControllerProvider.future);

  final events = <SakuraCalendarEvent>[];

  // 1. Add booked/scheduled meetings
  for (final meeting in meetingsAsync) {
    if (meeting.scheduledAt == null) continue;

    final start = meeting.scheduledAt!.displayValue;
    // 90 minutes authoritative JLPT booking duration
    final end = start.add(const Duration(minutes: 90));

    final learner = meeting.learnerName ?? 'Học viên';
    final title = 'Tư vấn JLPT: $learner';

    final statusText = switch (meeting.status) {
      MentorMeetingStatus.accepted => 'Đã xác nhận',
      MentorMeetingStatus.assigned => 'Đã nhận lớp',
      MentorMeetingStatus.pendingAssignment => 'Chờ phân công',
      MentorMeetingStatus.awaitingPayment => 'Chờ thanh toán',
      MentorMeetingStatus.completed => 'Đã hoàn thành',
      MentorMeetingStatus.cancelled => 'Đã hủy',
      _ => 'Lịch giảng dạy',
    };

    events.add(
      SakuraCalendarEvent(
        id: 'meeting_${meeting.id}',
        title: title,
        subtitle: 'Thời lượng: 90 phút',
        startTime: start,
        endTime: end,
        type: SakuraCalendarEventType.consultation,
        status: meeting.status,
        statusLabel: statusText,
        participantName: learner,
        participantRole: 'Học viên',
        meetingLink: meeting.meetingLink,
        notes: meeting.reviewComment != null
            ? 'Đánh giá học viên: ${meeting.reviewComment}'
            : 'Buổi hướng dẫn cá nhân hóa 1-1 trực tuyến.',
      ),
    );
  }

  // 2. Add available slots (not yet booked or open for registration)
  for (final slot in availabilityAsync) {
    if (slot.isBooked) continue; // Booked slots will appear via meetings

    final start = slot.startTime.displayValue;
    final end = slot.endTime.displayValue;

    events.add(
      SakuraCalendarEvent(
        id: 'slot_${slot.id}',
        title: 'Khung giờ trống đã đăng ký',
        subtitle: 'Sẵn sàng nhận lịch',
        startTime: start,
        endTime: end,
        type: SakuraCalendarEventType.availableSlot,
        statusLabel: 'Sẵn sàng',
        availabilityId: slot.id,
        notes: 'Khung giờ bạn đã đăng ký để học viên đặt lịch tư vấn.',
      ),
    );
  }

  events.sort((a, b) => a.startTime.compareTo(b.startTime));
  return events;
});
