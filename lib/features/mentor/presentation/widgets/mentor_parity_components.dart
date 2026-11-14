import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Shared Sakura status pill badge used across Mentor operational screens.
class MentorStatusBadge extends StatelessWidget {
  const MentorStatusBadge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color mentorMeetingStatusColor(MentorMeetingStatus status) {
  return switch (status) {
    MentorMeetingStatus.accepted ||
    MentorMeetingStatus.assigned => AppColors.brandPrimary,
    MentorMeetingStatus.completed => AppColors.success,
    MentorMeetingStatus.pendingAssignment ||
    MentorMeetingStatus.awaitingPayment => AppColors.warning,
    MentorMeetingStatus.cancelled => AppColors.error,
    MentorMeetingStatus.unknown => AppColors.textMuted,
  };
}

String mentorDisputeStatusLabel(MentorDisputeStatus status) {
  return switch (status) {
    MentorDisputeStatus.submitted => 'Mới tiếp nhận',
    MentorDisputeStatus.underReview => 'Đang thẩm định',
    MentorDisputeStatus.awaitingResponse => 'Chờ Mentor giải trình',
    MentorDisputeStatus.resolved => 'Đã giải quyết',
    MentorDisputeStatus.rejected => 'Đã từ chối',
    MentorDisputeStatus.closed => 'Đã đóng',
  };
}

String mentorDisputeHistoryActionLabel(
  String action,
  MentorDisputeStatus fallbackStatus,
) {
  return switch (action.trim()) {
    'Submitted' || 'Created' => 'Gửi khiếu nại',
    'UnderReview' || 'MovedToUnderReview' => 'Chuyển thẩm định',
    'RequestedMentorResponse' => 'Yêu cầu Mentor giải trình',
    'MentorResponded' => 'Mentor đã giải trình',
    'Resolved' => 'Hoàn tất xử lý',
    'Rejected' => 'Từ chối khiếu nại',
    'Closed' => 'Đóng khiếu nại',
    _ => mentorDisputeStatusLabel(fallbackStatus),
  };
}

Color mentorDisputeStatusColor(MentorDisputeStatus status) {
  return switch (status) {
    MentorDisputeStatus.submitted ||
    MentorDisputeStatus.underReview => AppColors.warning,
    MentorDisputeStatus.awaitingResponse => AppColors.brandPrimary,
    MentorDisputeStatus.resolved => AppColors.success,
    MentorDisputeStatus.rejected => AppColors.error,
    MentorDisputeStatus.closed => AppColors.textMuted,
  };
}

String mentorDisputeCategoryLabel(MentorDisputeCategory category) {
  return switch (category) {
    MentorDisputeCategory.mentorAbsent => 'Mentor vắng mặt',
    MentorDisputeCategory.sessionNotConducted => 'Buổi học không diễn ra',
    MentorDisputeCategory.mediaRoomIssue => 'Lỗi phòng học / âm thanh',
    MentorDisputeCategory.qualityIssue => 'Chất lượng buổi tư vấn',
    MentorDisputeCategory.inappropriateBehavior => 'Hành vi chưa phù hợp',
    MentorDisputeCategory.policyDispute => 'Tranh chấp chính sách',
    MentorDisputeCategory.other => 'Khác',
  };
}

String mentorAttendanceStatusLabel(MentorAttendanceStatus status) {
  return switch (status) {
    MentorAttendanceStatus.notJoined => 'Chưa vào phòng',
    MentorAttendanceStatus.joined => 'Đang trong phòng',
    MentorAttendanceStatus.temporarilyDisconnected => 'Mất kết nối tạm thời',
    MentorAttendanceStatus.left => 'Đã rời phòng',
    MentorAttendanceStatus.completed => 'Hoàn thành điểm danh',
    MentorAttendanceStatus.unknown => 'Chưa xác định',
  };
}

String formatMentorTimestamp(MentorTimestamp? timestamp, BuildContext context) {
  return mentorTimeLabel(timestamp, context);
}

String formatDurationCompact(int totalSeconds) {
  if (totalSeconds <= 0) return '0s';
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes == 0) return '${seconds}s';
  if (seconds == 0) return '${minutes}m';
  return '${minutes}m ${seconds}s';
}

String formatShortDateTime(MentorTimestamp? timestamp) {
  if (timestamp == null) return '—';
  return DateFormat('dd/MM · HH:mm').format(timestamp.value.toLocal());
}

/// Resolves the best meeting join URI (preferring native room if rollout allows).
MeetingRoomReference? resolveMentorNativeRoom({
  String? meetingLink,
  String? roomId,
}) {
  final meetingUri = parseSafeExternalHttpUri(meetingLink);
  final fromLink = MeetingRoomReference.resolve(webUri: meetingUri);
  if (fromLink != null) return fromLink;
  final trimmedRoom = roomId?.trim();
  if (trimmedRoom != null && trimmedRoom.isNotEmpty) {
    return MeetingRoomReference.fromUserInput(trimmedRoom);
  }
  return null;
}

bool canMentorJoinRoom({String? meetingLink, String? roomId}) {
  final meetingUri = parseSafeExternalHttpUri(meetingLink);
  final nativeRoom = resolveMentorNativeRoom(
    meetingLink: meetingLink,
    roomId: roomId,
  );
  return MeetingNativeRollout.isEnabled
      ? nativeRoom != null
      : (meetingUri != null || nativeRoom != null);
}

/// Shared Attendance telemetry card rendered in Meeting Detail, Session Prep & Disputes.
class MentorAttendanceListCard extends StatelessWidget {
  const MentorAttendanceListCard({required this.records, super.key});

  final List<MentorAttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color: AppColors.brandPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  l10n.mentorMeetingAttendanceTitle,
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          if (records.isEmpty)
            Text(
              l10n.mentorMeetingAttendanceEmpty,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.cardBorderMuted),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.participantName.isEmpty
                                  ? record.role
                                  : '${record.participantName} (${record.role})',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          MentorStatusBadge(
                            label: mentorAttendanceStatusLabel(record.status),
                            color: record.isOnline
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.space3,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Vào đầu: ${formatShortDateTime(record.firstJoinedAtUtc)}',
                            style: AppTypography.caption,
                          ),
                          Text(
                            'Tổng thời lượng: ${formatDurationCompact(record.totalDurationSeconds)}',
                            style: AppTypography.caption,
                          ),
                          Text(
                            'Kết nối lại: ${record.reconnectionCount}',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
