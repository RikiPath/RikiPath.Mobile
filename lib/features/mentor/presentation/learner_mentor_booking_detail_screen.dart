import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_reschedule_sheet.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';

class LearnerMentorBookingDetailScreen extends ConsumerWidget {
  const LearnerMentorBookingDetailScreen({required this.bookingId, super.key});

  final int? bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerMentorBookingsControllerProvider);
    return Scaffold(
      key: const Key('learner_mentor_booking_detail_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.learnerMentorMeetingDetailTitle)),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_mentor_booking_detail_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              message: context.l10n.learnerMentorBookingsError,
              onRetry: ref
                  .read(learnerMentorBookingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _DetailBody(
            booking: value
                .where((booking) => booking.id == bookingId)
                .firstOrNull,
            onJoin: (booking) => _joinMeeting(ref, context, booking),
            onReschedule: (booking) =>
                LearnerMentorRescheduleSheet.show(context, booking: booking),
            onCancel: (booking) =>
                _showCancellationDialog(context, ref, booking),
            onReview: (booking) => _showReviewDialog(context, ref, booking),
            onDispute: (booking) => _showDisputeDialog(context, ref, booking),
          ),
        },
      ),
    );
  }

  Future<void> _joinMeeting(
    WidgetRef ref,
    BuildContext context,
    LearnerMentorBooking booking,
  ) async {
    final room = MeetingRoomReference.resolve(
      roomId: booking.roomId,
      webUri: booking.safeMeetingUri,
    );
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
    final uri = booking.safeMeetingUri;
    if (uri == null) return;
    final opened = await ref.read(mentorMeetingLinkLauncherProvider).open(uri);
    if (opened || !context.mounted) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: context.l10n.mentorJoinFailedTitle,
          description: context.l10n.mentorJoinFailedDescription,
        );
  }

  void _showCancellationDialog(
    BuildContext context,
    WidgetRef ref,
    LearnerMentorBooking booking,
  ) {
    final now = DateTime.now().toUtc();
    final start = booking.scheduledAt?.value ?? now;
    final hoursUntil = start.difference(now).inHours;
    final isEligibleForRefund = hoursUntil >= 24;

    final reasonController = TextEditingController();
    final exceptionController = TextEditingController();
    var requestException = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hủy lịch hẹn tư vấn'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: isEligibleForRefund
                          ? AppColors.brandTint
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEligibleForRefund
                              ? Icons.info_outline
                              : Icons.warning_amber_rounded,
                          color: isEligibleForRefund
                              ? AppColors.brandPrimary
                              : AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            isEligibleForRefund
                                ? 'Hủy trước ≥ 24 giờ: Bạn sẽ được hoàn lại 1 vé tư vấn vào tài khoản.'
                                : 'Hủy muộn (< 24 giờ): Theo chính sách, không được tự động hoàn vé tư vấn.',
                            style: AppTypography.metadata.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isEligibleForRefund
                                  ? AppColors.brandPrimary
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  TextField(
                    key: const Key('cancellation_reason_input'),
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Lý do hủy lịch',
                      hintText: 'Nhập lý do hủy buổi hẹn...',
                    ),
                  ),
                  if (!isEligibleForRefund) ...[
                    const SizedBox(height: AppSpacing.space2),
                    CheckboxListTile(
                      key: const Key('cancellation_exception_checkbox'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Yêu cầu xem xét hoàn vé ngoại lệ',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: requestException,
                      onChanged: (val) {
                        setDialogState(() => requestException = val ?? false);
                      },
                    ),
                    if (requestException)
                      TextField(
                        key: const Key('cancellation_exception_reason_input'),
                        controller: exceptionController,
                        decoration: const InputDecoration(
                          labelText: 'Lý do xem xét ngoại lệ',
                          hintText: 'Trường hợp bất khả kháng, sự cố mạng...',
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                key: const Key('confirm_cancel_booking_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(title: 'Vui lòng nhập lý do hủy lịch');
                    return;
                  }
                  Navigator.of(dialogCtx).pop();
                  final ok = await ref
                      .read(learnerMentorMutationControllerProvider.notifier)
                      .cancelBooking(
                        bookingId: booking.id,
                        reason: reason,
                        requestException: requestException,
                        exceptionReason: exceptionController.text.trim(),
                      );
                  if (ok) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .success(
                          title: 'Hủy lịch hẹn thành công',
                          description: isEligibleForRefund
                              ? '1 vé tư vấn đã được hoàn trả.'
                              : 'Yêu cầu hủy đã được ghi nhận.',
                        );
                    ref.invalidate(learnerMentorBookingsControllerProvider);
                  } else {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(
                          title: 'Không thể hủy lịch hẹn',
                          description: 'Vui lòng thử lại sau.',
                        );
                  }
                },
                child: const Text('Xác nhận hủy'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    LearnerMentorBooking booking,
  ) {
    var rating = 5;
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Đánh giá buổi tư vấn'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = star);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('review_comment_input'),
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nhận xét về cố vấn',
                      hintText:
                          'Chia sẻ trải nghiệm của bạn về buổi hướng dẫn...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                key: const Key('submit_review_button'),
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final res = await ref
                      .read(learnerMentorMutationControllerProvider.notifier)
                      .createReview(
                        bookingId: booking.id,
                        rating: rating,
                        comment: commentController.text.trim(),
                      );
                  if (res != null) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .success(
                          title: 'Gửi đánh giá thành công',
                          description:
                              'Cảm ơn bạn đã phản hồi chất lượng buổi học.',
                        );
                  } else {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(
                          title: 'Không thể gửi đánh giá',
                          description: 'Vui lòng thử lại sau.',
                        );
                  }
                },
                child: const Text('Gửi đánh giá'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDisputeDialog(
    BuildContext context,
    WidgetRef ref,
    LearnerMentorBooking booking,
  ) {
    var selectedCategory = 1;
    final reasonController = TextEditingController();
    final evidenceController = TextEditingController();

    final categories = [
      (1, 'Chất lượng tư vấn không như cam kết'),
      (2, 'Cố vấn vắng mặt không báo trước'),
      (3, 'Sự cố kết nối kỹ thuật phòng học'),
      (4, 'Vấn đề ứng xử của cố vấn'),
      (5, 'Lý do khác'),
    ];

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Khiếu nại buổi học'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Text(
                      'Lưu ý: Thời hạn gửi khiếu nại trong vòng 48 giờ sau khi buổi học kết thúc. Ban quản trị sẽ đối chiếu bản ghi và phản hồi.',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục khiếu nại',
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.$1,
                            child: Text(
                              c.$2,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('dispute_reason_input'),
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Lý do khiếu nại',
                      hintText: 'Mô tả chi tiết vấn đề phát sinh...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('dispute_evidence_input'),
                    controller: evidenceController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú bổ sung (tùy chọn)',
                      hintText: 'Ảnh chụp màn hình, mô tả thời điểm...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                key: const Key('submit_dispute_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(title: 'Vui lòng nhập lý do khiếu nại');
                    return;
                  }
                  Navigator.of(dialogCtx).pop();
                  final res = await ref
                      .read(learnerMentorMutationControllerProvider.notifier)
                      .createDispute(
                        bookingId: booking.id,
                        category: selectedCategory,
                        reason: reason,
                        evidenceNotes: evidenceController.text.trim(),
                      );
                  if (res != null) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .success(
                          title: 'Gửi khiếu nại thành công',
                          description:
                              'Ban quản trị đã tiếp nhận và sẽ xử lý sớm nhất.',
                        );
                  } else {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(
                          title: 'Không thể gửi khiếu nại',
                          description: 'Vui lòng thử lại sau.',
                        );
                  }
                },
                child: const Text('Gửi khiếu nại'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.booking,
    required this.onJoin,
    this.onReschedule,
    required this.onCancel,
    required this.onReview,
    required this.onDispute,
  });

  final LearnerMentorBooking? booking;
  final Future<void> Function(LearnerMentorBooking booking) onJoin;
  final void Function(LearnerMentorBooking booking)? onReschedule;
  final void Function(LearnerMentorBooking booking) onCancel;
  final void Function(LearnerMentorBooking booking) onReview;
  final void Function(LearnerMentorBooking booking) onDispute;

  @override
  Widget build(BuildContext context) {
    final value = booking;
    if (value == null) {
      return MentorEmptyState(
        key: const Key('learner_mentor_booking_detail_missing'),
        icon: Icons.event_busy_outlined,
        title: context.l10n.learnerMentorMeetingDetailTitle,
        description: context.l10n.learnerMentorMeetingNotFound,
      );
    }
    final mentorName = value.mentorName?.trim();
    final meetingUri = value.safeMeetingUri;
    final nativeRoom = MeetingRoomReference.resolve(
      roomId: value.roomId,
      webUri: meetingUri,
    );
    final canJoin = MeetingNativeRollout.isEnabled
        ? nativeRoom != null
        : meetingUri != null;
    final isAccepted = value.status == MentorMeetingStatus.accepted;
    final isAssigned = value.status == MentorMeetingStatus.assigned;
    final isCompleted = value.status == MentorMeetingStatus.completed;
    final isCancelled = value.status == MentorMeetingStatus.cancelled;

    return ListView(
      key: const Key('learner_mentor_booking_detail_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        // 1. Thông tin chi tiết buổi học (Top Card)
        RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: isAccepted
              ? AppColors.brandPrimary.withValues(alpha: 0.35)
              : AppColors.border,
          child: Column(
            children: [
              LearnerMentorDetailRow(
                icon: Icons.support_agent_outlined,
                label: context.l10n.learnerMentorMentorLabel,
                value: mentorName == null || mentorName.isEmpty
                    ? context.l10n.learnerMentorUnknownMentor
                    : mentorName,
              ),
              const Divider(),
              LearnerMentorDetailRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.mentorScheduleLabel,
                value: mentorTimeLabel(value.scheduledAt, context),
              ),
              const Divider(),
              LearnerMentorDetailRow(
                icon: Icons.verified_outlined,
                label: context.l10n.mentorStatusLabel,
                value: learnerMentorBookingStatusLabel(value.status, context),
              ),
              const Divider(),
              LearnerMentorDetailRow(
                icon: Icons.payments_outlined,
                label: context.l10n.learnerMentorPaymentLabel,
                value: learnerMentorPaymentStatusLabel(
                  value.paymentStatus,
                  context,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // 2. Sakura Stepper 3 bước
        _buildTimeline(context, value.status),
        const SizedBox(height: AppSpacing.space4),

        // 3. Nút xem biên nhận / trạng thái thanh toán
        RikiSecondaryButton(
          key: const Key('learner_mentor_purchase_status_button'),
          label: context.l10n.learnerMentorPurchaseStatus,
          leadingIcon: Icons.receipt_long_outlined,
          onPressed: () => context.push(
            AppRoutes.learnerMentorPurchaseStatus(value.userSubscriptionId),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // 4. Nút vào phòng học hoặc thông báo trạng thái
        if (isCancelled)
          const RikiInfoBanner(
            key: Key('learner_mentor_booking_cancelled_banner'),
            message: 'Buổi tư vấn này đã bị hủy.',
          )
        else if (isCompleted) ...[
          Row(
            children: [
              Expanded(
                child: RikiPrimaryButton(
                  key: const Key('learner_mentor_review_action_button'),
                  label: 'Đánh giá',
                  leadingIcon: Icons.star_outline,
                  onPressed: () => onReview(value),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: RikiSecondaryButton(
                  key: const Key('learner_mentor_dispute_action_button'),
                  label: 'Khiếu nại',
                  leadingIcon: Icons.report_problem_outlined,
                  onPressed: () => onDispute(value),
                ),
              ),
            ],
          ),
        ] else if (!canJoin)
          RikiInfoBanner(
            key: const Key('learner_mentor_join_unavailable'),
            message: isAssigned
                ? 'Bạn có thể vào phòng tư vấn sau khi cố vấn xác nhận lịch hẹn.'
                : context.l10n.learnerMentorJoinUnavailable,
          )
        else
          RikiPrimaryButton(
            key: const Key('learner_mentor_join_button'),
            label: context.l10n.learnerMentorJoin,
            leadingIcon: Icons.videocam_outlined,
            onPressed: () => onJoin(value),
          ),

        // 5. Nút Dời lịch hẹn & Hủy lịch hẹn cho Learner khi buổi học chưa diễn ra
        if (isAssigned || isAccepted) ...[
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('learner_mentor_reschedule_button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Dời lịch hẹn'),
                  onPressed: () => onReschedule?.call(value),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('learner_mentor_cancel_booking_button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Hủy lịch hẹn'),
                  onPressed: () => onCancel(value),
                ),
              ),
            ],
          ),
        ],

        // 6. Checklist chuẩn bị (khi đã Accepted)
        if (isAccepted) ...[
          const SizedBox(height: AppSpacing.space4),
          RikiCard(
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        'Chuẩn bị trước buổi học',
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                _buildChecklistItem(
                  'Kiểm tra micro và camera thiết bị hoạt động tốt',
                ),
                const SizedBox(height: AppSpacing.space1),
                _buildChecklistItem(
                  'Nên sử dụng tai nghe để có âm thanh tốt nhất',
                ),
                const SizedBox(height: AppSpacing.space1),
                _buildChecklistItem(
                  'Chuẩn bị sẵn mục tiêu hoặc câu hỏi về JLPT',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, MentorMeetingStatus status) {
    final isAssigned = status == MentorMeetingStatus.assigned;
    final isAccepted = status == MentorMeetingStatus.accepted;
    final isCompleted = status == MentorMeetingStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStepChip('1. Đặt lịch', true, false)),
          const Icon(Icons.arrow_forward_ios, size: 8, color: AppColors.border),
          Expanded(
            child: _buildStepChip(
              '2. Xác nhận',
              isAccepted || isCompleted,
              isAssigned,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 8, color: AppColors.border),
          Expanded(
            child: _buildStepChip('3. Vào học', isCompleted, isAccepted),
          ),
        ],
      ),
    );
  }

  Widget _buildStepChip(String label, bool isDone, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isDone
              ? Icons.check_circle
              : (isActive
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
          size: 13,
          color: isDone || isActive
              ? AppColors.brandPrimary
              : AppColors.textDisabled,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isDone || isActive
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isDone || isActive
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, size: 14, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.space1),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
