import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';

final learnerCalendarEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      final courses = await ref
          .watch(learnerMyCoursesProvider.future)
          .timeout(const Duration(seconds: 10));

      final events = <SakuraCalendarEvent>[];

      for (final course in courses) {
        if (course.status == 'Cancelled') continue;
        final sessionMinutes =
            course.sessionMinutes > 0 ? course.sessionMinutes : 90;

        for (final session in course.sessions) {
          final start = session.scheduledAt.toLocal();
          final end = start.add(Duration(minutes: sessionMinutes));

          final (status, statusText) = switch (session.status) {
            'Completed' || 'Present' => (
              MentorMeetingStatus.completed,
              'Đã hoàn thành',
            ),
            'Cancelled' => (MentorMeetingStatus.cancelled, 'Đã hủy'),
            _ => (MentorMeetingStatus.accepted, 'Đã lên lịch'),
          };

          events.add(
            SakuraCalendarEvent(
              id: 'cohort_course_${course.id}_session_${session.id}',
              title: '${course.name} · Buổi ${session.number}',
              subtitle:
                  course.level.isNotEmpty ? 'JLPT ${course.level}' : null,
              startTime: start,
              endTime: end,
              type: SakuraCalendarEventType.consultation,
              status: status,
              statusLabel: statusText,
              participantName: course.mentorName,
              participantRole: 'Cố vấn lớp nhóm',
              jlptLevel: course.level.isNotEmpty ? 'JLPT ${course.level}' : null,
              meetingLink: session.meetingUrl,
              roomId: session.roomId,
              bookingId: course.id,
              sourceProvider: 'learnerMyCoursesProvider',
              sourceEntityId: '${course.id}:${session.id}',
              notes: 'Vui lòng vào phòng học nhóm đúng giờ.',
            ),
          );
        }
      }

      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
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
