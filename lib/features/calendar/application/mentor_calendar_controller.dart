import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

final mentorCalendarEventsProvider =
    FutureProvider.autoDispose<List<SakuraCalendarEvent>>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      var cohorts = const <StudyCohortSummary>[];
      var availability = const <MentorAvailabilitySlot>[];
      Object? firstError;
      var anySucceeded = false;

      final cohortsFuture = ref
          .watch(mentorAssignedCohortsProvider.future)
          .timeout(const Duration(seconds: 10));
      final availabilityFuture = ref
          .watch(mentorAvailabilityControllerProvider.future)
          .timeout(const Duration(seconds: 10));

      await Future.wait(<Future<void>>[
        cohortsFuture
            .then((value) {
              cohorts = value;
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

      for (final cohort in cohorts) {
        final (status, statusText) = switch (cohort.status) {
          'Completed' => (MentorMeetingStatus.completed, 'Đã kết thúc'),
          'Cancelled' => (MentorMeetingStatus.cancelled, 'Đã hủy'),
          _ => (MentorMeetingStatus.accepted, 'Lớp nhóm'),
        };

        for (final session in cohort.sessions) {
          final start = session.startTime.toLocal();
          final end = session.endTime.toLocal();
          final durationMin = end.difference(start).inMinutes.clamp(15, 240);

          events.add(
            SakuraCalendarEvent(
              id: 'cohort_${cohort.id}_session_${session.number}',
              title: '${cohort.name} · Buổi ${session.number}',
              subtitle: 'JLPT ${cohort.level} · $durationMin phút · ${cohort.enrolledCount}/${cohort.capacity} HV',
              startTime: start,
              endTime: end,
              type: SakuraCalendarEventType.consultation,
              status: status,
              statusLabel: statusText,
              participantName: '${cohort.enrolledCount}/${cohort.capacity} học viên',
              participantRole: 'Lớp nhóm',
              jlptLevel: cohort.level,
              roomId: session.roomId,
              bookingId: cohort.id,
              sourceProvider: 'mentorAssignedCohortsProvider',
              sourceEntityId: '${cohort.id}:${session.number}',
              notes: 'Mở chi tiết lớp nhóm để xem danh sách học viên, bài tập và điểm danh.',
            ),
          );
        }
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
    notes: 'Khung giờ đã được công bố để Admin mở lớp nhóm.',
  );
}

@immutable
class MentorGoogleCalendarStatus {
  const MentorGoogleCalendarStatus({
    required this.configured,
    required this.connected,
    this.lastSyncedAt,
  });

  final bool configured;
  final bool connected;
  final DateTime? lastSyncedAt;
}

final mentorGoogleCalendarControllerProvider = AsyncNotifierProvider.autoDispose<
  MentorGoogleCalendarController,
  MentorGoogleCalendarStatus
>(MentorGoogleCalendarController.new);

class MentorGoogleCalendarController
    extends AsyncNotifier<MentorGoogleCalendarStatus> {
  @override
  Future<MentorGoogleCalendarStatus> build() async {
    ref.watch(authenticatedUserIdProvider);
    return _fetchStatus();
  }

  Future<MentorGoogleCalendarStatus> _fetchStatus() async {
    final res = await ref
        .read(apiClientProvider)
        .get<Object?>(MentorApiPaths.mentorCalendar);
    final map = readMapOrEmpty(res.data);
    final result = map['result'] is Map ? readMapOrEmpty(map['result']) : map;
    return MentorGoogleCalendarStatus(
      configured: readBoolOrFalse(result, 'configured'),
      connected: readBoolOrFalse(result, 'connected'),
      lastSyncedAt: readOptionalTimestamp(result, 'lastSyncedAt')?.value,
    );
  }

  Future<String?> connect() async {
    final res = await ref
        .read(apiClientProvider)
        .post<Object?>(MentorApiPaths.mentorCalendarConnect);
    final map = readMapOrEmpty(res.data);
    final result = map['result'] is Map ? readMapOrEmpty(map['result']) : map;
    return readOptionalString(result, 'url');
  }

  Future<void> syncNow() async {
    await ref
        .read(apiClientProvider)
        .post<Object?>(MentorApiPaths.mentorCalendarSync);
    if (!ref.mounted) return;
    ref.invalidateSelf();
  }

  Future<void> disconnect() async {
    await ref
        .read(apiClientProvider)
        .delete<Object?>(MentorApiPaths.mentorCalendar);
    if (!ref.mounted) return;
    ref.invalidateSelf();
  }
}
