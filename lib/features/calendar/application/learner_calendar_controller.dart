import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';

final learnerCalendarEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      final bookingsAsync = await ref
          .watch(learnerMentorBookingsControllerProvider.future)
          .timeout(const Duration(seconds: 10));

      final events = <SakuraCalendarEvent>[];

      for (final booking in bookingsAsync) {
        if (booking.scheduledAt == null) continue;

        // Strictly convert UTC timestamp to user device local timezone (no hardcoded offset)
        final start = booking.scheduledAt!.value.toLocal();
        // Dùng thời điểm kết thúc Backend cung cấp để giữ đúng booking lịch sử.
        final end =
            booking.endsAt?.value.toLocal() ??
            start.add(const Duration(minutes: 90));

        // Enforce N5, N4, N3, N2 only (disallow N1)
        final validatedJlpt = SakuraCalendarEvent.normalizeConsultationLevel(
          booking.jlptLevel,
        );
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
            subtitle: booking.jlptLevel != null
                ? 'Trình độ: ${booking.jlptLevel}'
                : null,
            startTime: start,
            endTime: end,
            type: SakuraCalendarEventType.consultation,
            status: booking.status,
            statusLabel: statusText,
            participantName: booking.mentorName,
            participantRole: 'Cố vấn chuyên môn',
            jlptLevel: validatedJlpt == null ? null : 'JLPT $validatedJlpt',
            meetingLink: booking.meetingLink,
            roomId: booking.roomId,
            bookingId: booking.id,
            sourceProvider: 'learnerMentorBookingsControllerProvider',
            sourceEntityId: booking.id.toString(),
            notes: 'Vui lòng vào phòng học đúng giờ.',
          ),
        );
      }

      // Sort chronologically
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
    }, retry: (_, _) => null);

/// Chỉ ánh xạ những slot công khai, còn chỗ do API Learner trả về.
final learnerCalendarAvailableSlotsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      final slots = await ref
          .watch(learnerMentorAvailabilityControllerProvider.future)
          .timeout(const Duration(seconds: 10));
      return [
        for (final slot in slots)
          if (!slot.isBooked)
            SakuraCalendarEvent(
              id: 'available_${slot.id}',
              title: 'Còn chỗ: ${slot.mentorName}',
              startTime: slot.startTime.value.toLocal(),
              endTime: slot.endTime.value.toLocal(),
              type: SakuraCalendarEventType.availableSlot,
              statusLabel: 'Có thể đặt',
              participantName: slot.mentorName,
              participantRole: 'Cố vấn chuyên môn',
              availabilityId: slot.id,
              sourceProvider: 'learnerMentorAvailabilityControllerProvider',
              sourceEntityId: slot.id.toString(),
              notes:
                  'Chọn gói tư vấn và trình độ JLPT để kiểm tra điều kiện đặt lịch.',
            ),
      ];
    }, retry: (_, _) => null);

/// Daily queue chỉ có nghĩa cho ngày hiện tại, không suy diễn lịch SRS tương lai.
final learnerCalendarSrsEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      final queue = await ref
          .watch(dailyReviewRepositoryProvider)
          .loadDailyQueue()
          .timeout(const Duration(seconds: 10));
      if (queue.totalDue <= 0) return const [];
      final now = DateTime.now();
      return [
        SakuraCalendarEvent(
          id: 'srs_${now.year}_${now.month}_${now.day}',
          title: '${queue.totalDue} thẻ cần ôn',
          startTime: DateTime(now.year, now.month, now.day),
          endTime: DateTime(now.year, now.month, now.day + 1),
          type: SakuraCalendarEventType.srsReview,
          statusLabel: 'Đến hạn hôm nay',
          isAllDay: true,
          sourceProvider: 'dailyReviewRepositoryProvider',
          navigationTarget: 'dailyReview',
        ),
      ];
    }, retry: (_, _) => null);

/// Lộ trình hiện không có ngày học dự kiến; chỉ hiển thị mốc hoàn thành thật.
final learnerCalendarLearningEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      final path = await ref
          .watch(learningPathControllerProvider.future)
          .timeout(const Duration(seconds: 10));
      if (path == null) return const [];
      return [
        for (final day in path.dailySchedules)
          if (day.completedAt != null)
            SakuraCalendarEvent(
              id: 'learning_${path.pathId ?? path.userId}_${day.day}',
              title: 'Đã học: ${day.title}',
              subtitle: day.focus,
              startTime: day.completedAt!.toLocal(),
              endTime: day.completedAt!.toLocal().add(
                const Duration(minutes: 1),
              ),
              type: SakuraCalendarEventType.learningPlan,
              statusLabel: 'Đã hoàn thành',
              sourceProvider: 'learningPathControllerProvider',
              sourceEntityId: '${path.pathId ?? path.userId}:${day.day}',
              navigationTarget: 'learnRoadmap',
            ),
      ];
    }, retry: (_, _) => null);
