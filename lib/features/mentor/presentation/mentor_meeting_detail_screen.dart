import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';

class MentorMeetingDetailScreen extends ConsumerWidget {
  const MentorMeetingDetailScreen({required this.meetingId, super.key});

  final int? meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorMeetingsControllerProvider);
    return Scaffold(
      key: const Key('mentor_meeting_detail_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.mentorMeetingDetailTitle)),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('mentor_meeting_detail_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('mentor_meeting_detail_error'),
              message: context.l10n.mentorMeetingsError,
              onRetry: ref
                  .read(mentorMeetingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _DetailData(
            meeting: value
                .where((meeting) => meeting.id == meetingId)
                .firstOrNull,
            onJoin: (uri) => _openMeeting(ref, context, uri),
            onCancel: meetingId == null
                ? null
                : (reason) async {
                    final success = await ref
                        .read(mentorMeetingsControllerProvider.notifier)
                        .cancelMeeting(meetingId!, reason);
                    if (!context.mounted) return;
                    if (success) {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .success(
                            title: 'Hủy lịch thành công',
                            description:
                                'Đã hủy buổi tư vấn và hoàn lại 1 vé cho học viên.',
                          );
                    } else {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .error(
                            title: 'Hủy lịch thất bại',
                            description:
                                'Không thể hủy lịch hẹn. Vui lòng thử lại.',
                          );
                    }
                  },
            onReplyReview: meetingId == null
                ? null
                : (reply) async {
                    final success = await ref
                        .read(mentorMeetingsControllerProvider.notifier)
                        .replyReview(meetingId!, reply);
                    if (!context.mounted) return;
                    if (success) {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .success(
                            title: 'Gửi phản hồi thành công',
                            description: 'Đã gửi phản hồi đánh giá của học viên.',
                          );
                    } else {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .error(
                            title: 'Gửi phản hồi thất bại',
                            description: 'Không thể gửi phản hồi. Vui lòng thử lại.',
                          );
                    }
                  },
            onRespondDispute: meetingId == null
                ? null
                : (responseText) async {
                    final success = await ref
                        .read(mentorMeetingsControllerProvider.notifier)
                        .respondDispute(meetingId!, responseText);
                    if (!context.mounted) return;
                    if (success) {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .success(
                            title: 'Gửi giải trình thành công',
                            description: 'Bản giải trình đã được chuyển đến Quản trị viên.',
                          );
                    } else {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .error(
                            title: 'Gửi giải trình thất bại',
                            description: 'Không thể gửi giải trình. Vui lòng thử lại.',
                          );
                    }
                  },
          ),
        },
      ),
    );
  }

  Future<void> _openMeeting(
    WidgetRef ref,
    BuildContext context,
    Uri uri,
  ) async {
    final room = MeetingRoomReference.resolve(webUri: uri);
    if (MeetingNativeRollout.isEnabled) {
      if (room == null) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: context.l10n.mentorJoinFailedTitle,
              description: context.l10n.meetingLinkInvalid,
            );
        return;
      }
      await context.push(AppRoutes.meetingRoom(room.roomId), extra: room);
      return;
    }
    final opened = await ref.read(mentorMeetingLinkLauncherProvider).open(uri);
    if (opened || !context.mounted) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: context.l10n.mentorJoinFailedTitle,
          description: context.l10n.mentorJoinFailedDescription,
        );
  }
}

class _DetailData extends StatelessWidget {
  const _DetailData({
    required this.meeting,
    required this.onJoin,
    this.onCancel,
    this.onReplyReview,
    this.onRespondDispute,
  });

  final MentorMeetingSummary? meeting;
  final Future<void> Function(Uri uri) onJoin;
  final Future<void> Function(String reason)? onCancel;
  final Future<void> Function(String reply)? onReplyReview;
  final Future<void> Function(String responseText)? onRespondDispute;

  @override
  Widget build(BuildContext context) {
    final value = meeting;
    if (value == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: MentorEmptyState(
            key: const Key('mentor_meeting_detail_missing'),
            icon: Icons.event_busy_outlined,
            title: context.l10n.mentorMeetingDetailTitle,
            description: context.l10n.mentorMeetingNotFound,
          ),
        ),
      );
    }

    final meetingUri = value.safeMeetingUri;
    final nativeRoom = MeetingRoomReference.resolve(webUri: meetingUri);
    final canJoin = MeetingNativeRollout.isEnabled
        ? nativeRoom != null
        : meetingUri != null;
    final isConfirmed = value.status == MentorMeetingStatus.assigned ||
        value.status == MentorMeetingStatus.accepted;

    return ListView(
      key: const Key('mentor_meeting_detail_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        // Hero Card trạng thái yêu cầu
        RikiCard(
            borderColor: isConfirmed
              ? AppColors.brandPrimary.withValues(alpha: 0.35)
              : AppColors.warning.withValues(alpha: 0.4),
            backgroundColor: isConfirmed
              ? AppColors.brandPrimary.withValues(alpha: 0.04)
              : AppColors.warning.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? AppColors.brandTint
                      : AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConfirmed
                      ? Icons.check_circle_outline
                      : Icons.assignment_ind_outlined,
                  color: isConfirmed
                      ? AppColors.brandPrimary
                      : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfirmed
                          ? 'Đã xác nhận buổi học'
                          : mentorStatusLabel(value.status, context),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConfirmed
                          ? 'Buổi học đã được lên lịch. Vui lòng vào phòng đúng giờ.'
                          : mentorStatusLabel(value.status, context),
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        MentorPageHeader(
          title: context.l10n.mentorMeetingDetailTitle,
          subtitle: value.learnerName ?? context.l10n.mentorLearnerUnknown,
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiCard(
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                icon: Icons.person_outline,
                label: context.l10n.mentorLearnerLabel,
                value: value.learnerName ?? context.l10n.mentorLearnerUnknown,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.mentorScheduleLabel,
                value: mentorTimeLabel(value.scheduledAt, context),
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.verified_outlined,
                label: context.l10n.mentorStatusLabel,
                value: mentorStatusLabel(value.status, context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        if (!canJoin)
          RikiInfoBanner(
            key: const Key('mentor_meeting_link_unavailable'),
            message: context.l10n.mentorMeetingLinkUnavailable,
          )
        else
          RikiPrimaryButton(
            key: const Key('mentor_join_meeting_button'),
            label: context.l10n.mentorJoinMeeting,
            leadingIcon: Icons.videocam_outlined,
            onPressed: () => onJoin(meetingUri!),
          ),
        const SizedBox(height: AppSpacing.space3),

        // Mentor Cancel button for assigned or accepted meetings
        if ((value.status == MentorMeetingStatus.assigned ||
                value.status == MentorMeetingStatus.accepted) &&
            onCancel != null) ...[
          RikiSecondaryButton(
            key: const Key('mentor_cancel_meeting_button'),
            label: 'Hủy buổi dạy (Hoàn vé cho học viên)',
            leadingIcon: Icons.cancel_outlined,
            onPressed: () => _showCancelDialog(context),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Review & Reply section
        if (value.status == MentorMeetingStatus.completed ||
            value.reviewRating != null) ...[
          RikiCard(
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rate_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      'Đánh giá từ học viên',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (value.reviewRating != null)
                      Text(
                        '⭐ \${value.reviewRating}/5',
                        style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                  ],
                ),
                if (value.reviewComment != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    value.reviewComment!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
                const SizedBox(height: AppSpacing.space2),
                if (value.reviewReply != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Phản hồi của bạn: \${value.reviewReply}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.brandPrimary),
                    ),
                  )
                else if (onReplyReview != null)
                  RikiTextButton(
                    key: const Key('mentor_reply_review_button'),
                    label: 'Gửi phản hồi cho đánh giá',
                    leadingIcon: Icons.reply,
                    onPressed: () => _showReplyReviewDialog(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Dispute section
        if (value.hasDispute) ...[
          RikiCard(
            borderColor: AppColors.error.withValues(alpha: 0.3),
            backgroundColor: AppColors.error.withValues(alpha: 0.04),
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      'Khiếu nại từ học viên',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ],
                ),
                if (value.disputeReason != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Lý do khiếu nại: \${value.disputeReason}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
                const SizedBox(height: AppSpacing.space2),
                if (value.disputeResponse != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Giải trình của bạn: \${value.disputeResponse}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.brandPrimary),
                    ),
                  )
                else if (onRespondDispute != null)
                  RikiTextButton(
                    key: const Key('mentor_respond_dispute_button'),
                    label: 'Gửi bản giải trình khiếu nại',
                    leadingIcon: Icons.description_outlined,
                    onPressed: () => _showRespondDisputeDialog(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Ghi chú & mục tiêu học tập của học viên
        RikiCard(
          borderColor: AppColors.border,
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 18,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    'Mục tiêu học viên cần hỗ trợ',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Ôn tập lộ trình học JLPT, giải thích các dạng bài đọc hiểu N3-N2 và luyện nói giao tiếp tiếng Nhật.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        RikiTextButton(
          label: MaterialLocalizations.of(context).backButtonTooltip,
          leadingIcon: Icons.arrow_back,
          onPressed: context.pop,
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy buổi dạy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      'Khi bạn hủy buổi dạy, hệ thống sẽ tự động hoàn lại 1 vé tư vấn cho học viên và giải phóng lịch rảnh của bạn.',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              key: const Key('mentor_cancellation_reason_input'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy lịch dạy',
                hintText: 'Nhập lý do báo bận hoặc việc đột xuất...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            key: const Key('mentor_confirm_cancel_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final reason = reasonController.text.trim();
              onCancel?.call(reason.isEmpty ? 'Cố vấn báo bận' : reason);
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  void _showReplyReviewDialog(BuildContext context) {
    final replyController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Phản hồi đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gửi phản hồi cảm ơn hoặc giải đáp thắc mắc của học viên sau buổi học:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              key: const Key('mentor_reply_review_input'),
              controller: replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nội dung phản hồi',
                hintText: 'Cảm ơn bạn đã tham gia buổi học...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            key: const Key('mentor_confirm_reply_button'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final reply = replyController.text.trim();
              if (reply.isNotEmpty) {
                onReplyReview?.call(reply);
              }
            },
            child: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
  }

  void _showRespondDisputeDialog(BuildContext context) {
    final responseController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Giải trình khiếu nại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trình bày chi tiết lý do và bằng chứng từ phía bạn để Quản trị viên xem xét xử lý:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              key: const Key('mentor_dispute_response_input'),
              controller: responseController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nội dung giải trình',
                hintText: 'Tôi đã có mặt đúng giờ và hoàn thành bài giảng...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            key: const Key('mentor_confirm_dispute_response_button'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final resp = responseController.text.trim();
              if (resp.isNotEmpty) {
                onRespondDispute?.call(resp);
              }
            },
            child: const Text('Gửi giải trình'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandTint,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 21),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
