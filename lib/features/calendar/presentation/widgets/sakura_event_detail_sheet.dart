import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_reschedule_sheet.dart';

class SakuraEventDetailSheet extends ConsumerWidget {

  Future<void> _showRescheduleSheet(BuildContext context, WidgetRef ref) async {
    final bookings = await ref.read(learnerMentorBookingsControllerProvider.future);
    final booking = bookings.where((b) => b.id == event.bookingId).firstOrNull;
    if (booking == null) return;
    if (context.mounted) {
      Navigator.of(context).pop();
      await LearnerMentorRescheduleSheet.show(context, booking: booking);
    }
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy buổi tư vấn?'),
        content: const Text(
          'Theo chính sách của RikiPath, bạn có thể hủy lịch hẹn trước giờ bắt đầu. Vé tư vấn (ticket) hoặc số dư sẽ được hoàn lại vào tài khoản theo quy định.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true && event.bookingId != null) {
      final success = await ref
          .read(learnerMentorMutationControllerProvider.notifier)
          .cancelBooking(
            bookingId: event.bookingId!,
            reason: 'Người dùng yêu cầu hủy từ lịch',
          );

      if (context.mounted) {
        ref.invalidate(learnerCalendarEventsProvider);
        ref.invalidate(mentorCalendarEventsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã hủy lịch hẹn và cập nhật trạng thái hoàn vé thành công.'
                  : 'Không thể hủy lịch hẹn hoặc lịch đã được xử lý.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

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
                        border: Border.all(
                          color: event.statusBadgeBorderColor,
                        ),
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
                            JlptLevel.tryParse(event.jlptLevel?.replaceAll('JLPT ', '') ?? 'N3') ?? JlptLevel.n3,
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
                          'Buổi tư vấn đã bị hủy',
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

              // Online Meeting Room Action (Strict validation, no fake links, hidden when cancelled per 08_Chi_Tiet_Da_Huy)
              if (event.meetingLink != null &&
                  event.meetingLink!.isNotEmpty &&
                  event.status != MentorMeetingStatus.cancelled) ...[
                Builder(
                  builder: (context) {
                    final uri = Uri.tryParse(event.meetingLink!);
                    final isValidUrl = uri != null &&
                        uri.hasScheme &&
                        (uri.scheme == 'http' || uri.scheme == 'https');

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: isValidUrl ? const Color(0xFFFFF1F2) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isValidUrl ? const Color(0xFFFFE4E6) : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                color: isValidUrl ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              Expanded(
                                child: Text(
                                  isValidUrl
                                      ? 'Phòng học trực tuyến Google Meet / RikiPath'
                                      : 'Chưa có link phòng học trực tuyến',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isValidUrl ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (isValidUrl) ...[
                            const SizedBox(height: AppSpacing.space3),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(mentorMeetingLinkLauncherProvider)
                                      .open(uri);
                                },
                                icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white),
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
                                  shadowColor: const Color(0xFFE5577F).withValues(alpha: 0.35),
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

              // Booking Reschedule & Cancellation Actions (Policy-compliant with confirmation)
              if (event.bookingId != null &&
                  event.type == SakuraCalendarEventType.consultation &&
                  event.status != MentorMeetingStatus.cancelled &&
                  event.status != MentorMeetingStatus.completed) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('sakura_event_reschedule_button'),
                        onPressed: () => _showRescheduleSheet(context, ref),
                        icon: const Icon(
                          Icons.edit_calendar_outlined,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                        label: const Text(
                          'Dời lịch hẹn',
                          style: TextStyle(
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAF6FF),
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(
                            color: Color(0xFF7DD3FC),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('sakura_event_cancel_button'),
                        onPressed: () => _showCancelDialog(context, ref),
                        icon: const Icon(
                          Icons.event_busy,
                          size: 18,
                          color: Color(0xFFDC3545),
                        ),
                        label: const Text(
                          'Hủy buổi tư vấn này',
                          style: TextStyle(
                            color: Color(0xFFDC3545),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC3545),
                          side: const BorderSide(
                            color: Color(0xFFF5C8CF),
                            width: 1.2,
                          ),
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
