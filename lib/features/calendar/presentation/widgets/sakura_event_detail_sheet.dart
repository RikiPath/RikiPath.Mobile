import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

class SakuraEventDetailSheet extends ConsumerWidget {
  const SakuraEventDetailSheet({
    super.key,
    required this.event,
    this.onDismiss,
  });

  final SakuraCalendarEvent event;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    required SakuraCalendarEvent event,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SakuraEventDetailSheet(event: event),
    );
  }

  String _formatDate(DateTime dt) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final wd = weekdays[dt.weekday - 1];
    return '$wd, ${dt.day} tháng ${dt.month}, ${dt.year}';
  }

  String _formatTimeSpan(DateTime start, DateTime end, int durationMinutes) {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr – $endStr ($durationMinutes phút)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationMins = event.durationMinutes;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
            vertical: AppSpacing.space3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Type & Status Header Row (Category always Sakura Pink, status badge follows booking status)
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: SakuraCalendarEvent.mentorConsultationDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    event.type.labelVi,
                    style: AppTypography.bodySmall.copyWith(
                      color: SakuraCalendarEvent.mentorConsultationTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (event.statusLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.statusBadgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: event.statusBadgeBorderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.statusBadgeIcon != null) ...[
                            Icon(
                              event.statusBadgeIcon,
                              size: 13,
                              color: event.statusBadgeTextColor,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            event.statusLabel!,
                            style: AppTypography.caption.copyWith(
                              color: event.statusBadgeTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),

              // Title
              Text(
                event.title,
                style: AppTypography.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Date & Time Row
              Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Text(
                            _formatDate(event.startTime),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.space4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Text(
                            _formatTimeSpan(
                              event.startTime,
                              event.endTime,
                              durationMins,
                            ),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (event.jlptLevel != null)
                          JlptBadge(
                            JlptLevel.tryParse(
                                  event.jlptLevel?.replaceAll('JLPT ', '') ??
                                      'N3',
                                ) ??
                                JlptLevel.n3,
                            backgroundColor: event.levelChipBgColor,
                            borderColor: event.levelChipBorderColor,
                            foregroundColor: event.levelChipTextColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Participant Information (Role-aware, fallback avatar is Sakura Pink)
              if (event.participantName != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SakuraCalendarEvent.mentorAvatarBgColor,
                          border: Border.all(
                            color: SakuraCalendarEvent.mentorAvatarBorderColor,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: SakuraCalendarEvent.mentorAvatarFgColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.participantName!,
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.participantRole != null)
                              Text(
                                event.participantRole!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],

              // Cancelled meeting notice per 08_Chi_Tiet_Da_Huy
              if (event.status == MentorMeetingStatus.cancelled) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 20,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          'Buổi học đã bị hủy',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Online Meeting Room Action (Strict validation, hidden when cancelled/assigned/completed)
              if (event.status != MentorMeetingStatus.cancelled &&
                  event.status != MentorMeetingStatus.assigned &&
                  event.status != MentorMeetingStatus.completed &&
                  ((event.meetingLink != null &&
                          event.meetingLink!.isNotEmpty) ||
                      (MeetingNativeRollout.isEnabled &&
                          event.roomId != null &&
                          event.roomId!.isNotEmpty))) ...[
                Builder(
                  builder: (context) {
                    final safeUri = parseSafeExternalHttpUri(event.meetingLink);
                    final nativeRoom = MeetingRoomReference.resolve(
                      roomId: event.roomId,
                      webUri: safeUri,
                    );
                    final canJoin = MeetingNativeRollout.isEnabled
                        ? nativeRoom != null
                        : safeUri != null;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: canJoin
                            ? const Color(0xFFFFF1F2)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: canJoin
                              ? const Color(0xFFFFE4E6)
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                color: canJoin
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              Expanded(
                                child: Text(
                                  canJoin
                                      ? (MeetingNativeRollout.isEnabled &&
                                                nativeRoom != null
                                            ? 'Phòng học trực tuyến RikiPath'
                                            : 'Phòng học trực tuyến Google Meet / RikiPath')
                                      : 'Chưa có link phòng học trực tuyến',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: canJoin
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (canJoin) ...[
                            const SizedBox(height: AppSpacing.space3),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (MeetingNativeRollout.isEnabled) {
                                    if (nativeRoom == null) {
                                      ref
                                          .read(
                                            rikiToastServiceProvider.notifier,
                                          )
                                          .error(
                                            title: context
                                                .l10n
                                                .mentorJoinFailedTitle,
                                            description:
                                                context.l10n.meetingLinkInvalid,
                                          );
                                      return;
                                    }
                                    final router = GoRouter.maybeOf(context);
                                    Navigator.of(context).pop();
                                    await router?.push(
                                      AppRoutes.meetingRoom(nativeRoom.roomId),
                                      extra: nativeRoom,
                                    );
                                    return;
                                  }
                                  await ref
                                      .read(mentorMeetingLinkLauncherProvider)
                                      .open(safeUri!);
                                },
                                icon: const Icon(
                                  Icons.open_in_new,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Tham gia phòng học',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE5577F),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: const Color(
                                    0xFFE5577F,
                                  ).withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.space3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],

              if (event.bookingId != null &&
                  event.type == SakuraCalendarEventType.consultation) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final courseId = event.bookingId!;
                      final router = GoRouter.maybeOf(context);
                      Navigator.of(context).pop();
                      router?.push(AppRoutes.learnerCohortDetail(courseId));
                    },
                    icon: const Icon(Icons.school_outlined, size: 18),
                    label: const Text('Mở chi tiết lớp học'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],

              // Notes / Instructions
              if (event.notes != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          event.notes!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
      ),
    );
  }
}
