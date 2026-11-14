import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

final mentorCalendarEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      var meetings = const <MentorMeetingSummary>[];
      var availability = const <MentorAvailabilitySlot>[];
      Object? firstError;
      var anySucceeded = false;

      final meetingsFuture = ref
          .watch(mentorMeetingsControllerProvider.future)
          .timeout(const Duration(seconds: 10));
      final availabilityFuture = ref
          .watch(mentorAvailabilityControllerProvider.future)
          .timeout(const Duration(seconds: 10));

      await Future.wait(<Future<void>>[
        meetingsFuture
            .then((value) {
              meetings = value;
              anySucceeded = true;
            })
            .catchError((Object err, StackTrace st) {
              firstError ??= err;
            }),
        availabilityFuture
            .then((value) {
              availability = value;
              anySucceeded = true;
            })
            .catchError((Object err, StackTrace st) {
              firstError ??= err;
            }),
      ]);

      if (!anySucceeded && firstError != null) {
        Error.throwWithStackTrace(firstError!, StackTrace.current);
      }

      final events = <SakuraCalendarEvent>[];

      for (final meeting in meetings) {
        if (meeting.scheduledAt == null) continue;

        final start = meeting.scheduledAt!.value.toLocal();
        final rawEnd = meeting.endsAt?.value.toLocal();
        final end = (rawEnd != null && rawEnd.isAfter(start))
            ? rawEnd
            : start.add(const Duration(minutes: 90));
        final durationMin = end.difference(start).inMinutes.clamp(15, 240);

        final learner = meeting.learnerName?.trim().isNotEmpty == true
            ? meeting.learnerName!.trim()
            : 'Học viên';
        final title = 'Tư vấn JLPT: $learner';

        final statusText = switch (meeting.status) {
          MentorMeetingStatus.accepted => 'Đã xác nhận',
          MentorMeetingStatus.assigned => 'Đã nhận lịch',
          MentorMeetingStatus.pendingAssignment => 'Chờ phân công',
          MentorMeetingStatus.awaitingPayment => 'Chờ thanh toán',
          MentorMeetingStatus.completed => 'Đã hoàn thành',
          MentorMeetingStatus.cancelled => 'Đã hủy',
          _ => 'Lịch tư vấn',
        };

        final question = meeting.question?.trim();
        final reviewComment = meeting.reviewComment?.trim();
        final notes = (question != null && question.isNotEmpty)
            ? question
            : (reviewComment != null && reviewComment.isNotEmpty)
            ? 'Đánh giá học viên: $reviewComment'
            : null;

        final levelPrefix = (meeting.jlptLevel?.trim().isNotEmpty == true)
            ? 'JLPT ${meeting.jlptLevel!.trim()} · '
            : '';

        events.add(
          SakuraCalendarEvent(
            id: 'meeting_${meeting.id}',
            title: title,
            subtitle: '${levelPrefix}Thời lượng: $durationMin phút',
            startTime: start,
            endTime: end,
            type: SakuraCalendarEventType.consultation,
            status: meeting.status,
            statusLabel: statusText,
            participantName: learner,
            participantRole: 'Học viên',
            jlptLevel: meeting.jlptLevel,
            meetingLink: meeting.meetingLink,
            roomId: meeting.roomId,
            bookingId: meeting.id,
            sourceProvider: 'mentor',
            sourceEntityId: '${meeting.id}',
            notes: notes,
          ),
        );
      }

      for (final slot in availability) {
        if (slot.isBooked) continue;

        final start = slot.startTime.value.toLocal();
        final end = slot.endTime.value.toLocal();
        final statusInfo = _resolveSlotStatusPresentation(slot);

        events.add(
          SakuraCalendarEvent(
            id: 'slot_${slot.id}',
            title: 'Khung giờ rảnh',
            subtitle:
                '${statusInfo.label} · ${slot.bookedCount}/${slot.maxLearners} học viên',
            startTime: start,
            endTime: end,
            type: SakuraCalendarEventType.availableSlot,
            statusLabel: statusInfo.label,
            availabilityId: slot.id,
            customColor: statusInfo.color,
            customBackgroundColor: statusInfo.backgroundColor,
            sourceProvider: 'mentor',
            sourceEntityId: '${slot.id}',
            notes: statusInfo.notes,
          ),
        );
      }

      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
    });

({String label, Color color, Color backgroundColor, String? notes})
_resolveSlotStatusPresentation(MentorAvailabilitySlot slot) {
  if (slot.isRejected) {
    return (
      label: 'Bị từ chối',
      color: const Color(0xFFE11D48),
      backgroundColor: const Color(0xFFFFF1F2),
      notes: slot.rejectionReason?.trim().isNotEmpty == true
          ? 'Lý do từ chối: ${slot.rejectionReason!.trim()}'
          : 'Khung giờ đã bị từ chối bởi quản trị viên.',
    );
  }
  if (slot.hasCancelRequest) {
    return (
      label: 'Đang xin hủy',
      color: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFFFFBEB),
      notes: slot.cancelReason?.trim().isNotEmpty == true
          ? 'Lý do xin hủy: ${slot.cancelReason!.trim()}'
          : 'Đang chờ quản trị viên xét duyệt yêu cầu hủy khung giờ.',
    );
  }
  if (slot.hasChangeRequest) {
    return (
      label: 'Xin đổi ca',
      color: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFEFF6FF),
      notes: slot.changeRequestReason?.trim().isNotEmpty == true
          ? 'Yêu cầu đổi ca: ${slot.changeRequestReason!.trim()}'
          : 'Đang chờ xử lý yêu cầu đổi ca.',
    );
  }
  if (slot.isPendingApproval) {
    return (
      label: 'Chờ duyệt',
      color: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFFFFBEB),
      notes: 'Khung giờ đang chờ quản trị viên phê duyệt công bố.',
    );
  }
  return (
    label: 'Sẵn sàng',
    color: const Color(0xFF0F766E),
    backgroundColor: const Color(0xFFF0FDFA),
    notes: 'Khung giờ đã được công bố cho học viên đặt lịch.',
  );
}
