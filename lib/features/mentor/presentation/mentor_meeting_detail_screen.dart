import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';

class MentorMeetingDetailScreen extends ConsumerWidget {
  const MentorMeetingDetailScreen({required this.meetingId, super.key});

  final int? meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorMeetingsControllerProvider);
    final hasGoRouter = GoRouter.maybeOf(context) != null;
    final canPopRoute =
        GoRouter.maybeOf(context)?.canPop() ??
        (ModalRoute.of(context)?.canPop ?? true);
    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          popOrGo(context, AppRoutes.mentorMeetings);
        }
      },
      child: Scaffold(
        key: const Key('mentor_meeting_detail_screen'),
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          leading: hasGoRouter
              ? BackButton(
                  onPressed: () => popOrGo(context, AppRoutes.mentorMeetings),
                )
              : null,
          title: Text(context.l10n.mentorMeetingDetailTitle),
        ),
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
                    if (!context.mounted) return;
                    final success = await runWithAppLoadingOverlay<bool>(
                      context,
                      title: context.l10n.loadingOverlayProcessingTitle,
                      subtitle: context.l10n.loadingOverlayUpdatingSubtitle,
                      action: () => ref
                          .read(mentorMeetingsControllerProvider.notifier)
                          .cancelMeeting(meetingId!, reason),
                    );
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
                    if (!context.mounted) return;
                    final l10n = context.l10n;
                    int? resolvedReviewId;
                    try {
                      resolvedReviewId = await _resolveReviewIdForBooking(
                        ref,
                        meetingId!,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ref.read(rikiToastServiceProvider.notifier).error(
                        title: l10n.toastActionFailedTitle,
                        description: appErrorMessage(error, l10n),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    if (resolvedReviewId == null) {
                      ref.read(rikiToastServiceProvider.notifier).error(
                        title: l10n.toastActionFailedTitle,
                        description: l10n.mentorMeetingReviewNotFound,
                      );
                      return;
                    }
                    final success = await runWithAppLoadingOverlay<bool>(
                      context,
                      title: l10n.loadingOverlaySubmittingTitle,
                      subtitle: l10n.loadingOverlayCompletingSubtitle,
                      action: () => ref
                          .read(mentorReviewsControllerProvider.notifier)
                          .replyToReview(
                            reviewId: resolvedReviewId!,
                            reply: reply,
                          ),
                    );
                    if (!context.mounted) return;
                    if (success) {
                      ref.invalidate(mentorMeetingsControllerProvider);
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
                    if (!context.mounted) return;
                    final l10n = context.l10n;
                    int? resolvedDisputeId;
                    try {
                      resolvedDisputeId = await _resolveDisputeIdForBooking(
                        ref,
                        meetingId!,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ref.read(rikiToastServiceProvider.notifier).error(
                        title: l10n.toastActionFailedTitle,
                        description: appErrorMessage(error, l10n),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    if (resolvedDisputeId == null) {
                      ref.read(rikiToastServiceProvider.notifier).error(
                        title: l10n.toastActionFailedTitle,
                        description: l10n.mentorMeetingDisputeNotFound,
                      );
                      return;
                    }
                    final success = await runWithAppLoadingOverlay<bool>(
                      context,
                      title: l10n.loadingOverlaySubmittingTitle,
                      subtitle: l10n.loadingOverlayCompletingSubtitle,
                      action: () => ref
                          .read(mentorMeetingsControllerProvider.notifier)
                          .respondDispute(resolvedDisputeId!, responseText),
                    );
                    if (!context.mounted) return;
                    if (success) {
                      ref.invalidate(mentorDisputesControllerProvider);
                      ref.invalidate(
                        mentorDisputeDetailProvider(resolvedDisputeId),
                      );
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

class _DetailData extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    final bookingDetailAsync = ref.watch(mentorBookingDetailProvider(value.id));
    final cancellationAsync = ref.watch(
      mentorCancellationEligibilityProvider(value.id),
    );
    final attendanceAsync = ref.watch(mentorBookingAttendanceProvider(value.id));
    final reviewsAsync = ref.watch(mentorReviewsControllerProvider);
    final disputesAsync = ref.watch(mentorDisputesControllerProvider);

    final detail = bookingDetailAsync.asData?.value;
    final cancellation = cancellationAsync.asData?.value;
    final attendanceRecords = attendanceAsync.asData?.value;
    final matchingReview = reviewsAsync.asData?.value.reviews
        .where((r) => r.mentorBookingId == value.id)
        .firstOrNull;
    final matchingDispute = disputesAsync.asData?.value
        .where((d) => d.mentorBookingId == value.id)
        .firstOrNull;

    final effectiveRating = matchingReview?.rating ?? value.reviewRating;
    final effectiveComment = matchingReview?.comment ?? value.reviewComment;
    final effectiveReply = matchingReview?.mentorReply ?? value.reviewReply;
    final effectiveDisputeReason = matchingDispute?.reason ?? value.disputeReason;
    final effectiveDisputeResponse =
        matchingDispute?.mentorResponse ?? value.disputeResponse;

    final meetingUri =
        value.safeMeetingUri ?? parseSafeExternalHttpUri(detail?.meetingLink);
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
              if (detail?.jlptLevel ?? value.jlptLevel case final jlpt?) ...[
                const Divider(),
                _DetailRow(
                  icon: Icons.school_outlined,
                  label: context.l10n.mentorMeetingJlptLevel,
                  value: jlpt,
                ),
              ],
              if (detail?.endsAt ?? value.endsAt case final endsAt?) ...[
                const Divider(),
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: context.l10n.mentorEndTimeLabel,
                  value: mentorTimeLabel(endsAt, context),
                ),
              ],
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

        // Mentor Cancel button for upcoming assigned or accepted meetings
        if ((value.status == MentorMeetingStatus.assigned ||
                value.status == MentorMeetingStatus.accepted) &&
            onCancel != null &&
            (value.scheduledAt == null ||
                DateTime.now().toUtc().isBefore(
                  value.scheduledAt!.value.toUtc(),
                )) &&
            (cancellation == null || cancellation.canCancel)) ...[
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
            effectiveRating != null) ...[
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
                    Expanded(
                      child: Text(
                        'Đánh giá từ học viên',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (effectiveRating != null) ...[
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '⭐ $effectiveRating/5',
                        style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ],
                  ],
                ),
                if (effectiveComment != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    effectiveComment,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
                const SizedBox(height: AppSpacing.space2),
                if (effectiveReply != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Phản hồi của bạn: $effectiveReply',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.brandPrimary),
                    ),
                  )
                else if (onReplyReview != null && effectiveRating != null)
                  RikiTextButton(
                    key: const Key('mentor_reply_review_button'),
                    label: 'Gửi phản hồi cho đánh giá',
                    leadingIcon: Icons.reply,
                    onPressed: () => _showReplyReviewDialog(context),
                  )
                else if (effectiveRating == null && effectiveComment == null)
                  Text(
                    'Học viên chưa để lại đánh giá.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Dispute section
        if (value.hasDispute || matchingDispute != null) ...[
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
                    Expanded(
                      child: Text(
                        'Khiếu nại từ học viên',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ),
                    if (matchingDispute != null)
                      MentorStatusBadge(
                        label: mentorDisputeStatusLabel(matchingDispute.status),
                        color: mentorDisputeStatusColor(matchingDispute.status),
                      ),
                  ],
                ),
                if (effectiveDisputeReason != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Lý do khiếu nại: $effectiveDisputeReason',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
                const SizedBox(height: AppSpacing.space2),
                if (effectiveDisputeResponse != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Giải trình của bạn: $effectiveDisputeResponse',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.brandPrimary),
                    ),
                  )
                else if (onRespondDispute != null &&
                    (matchingDispute == null || matchingDispute.canSubmitResponse))
                  RikiTextButton(
                    key: const Key('mentor_respond_dispute_button'),
                    label: 'Gửi bản giải trình khiếu nại',
                    leadingIcon: Icons.description_outlined,
                    onPressed: () => _showRespondDisputeDialog(context),
                  ),
                if (matchingDispute != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(
                        AppRoutes.mentorDisputeDetail(matchingDispute.id),
                      ),
                      child: Text(context.l10n.mentorMeetingOpenDisputeDetail),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Attendance telemetry & Cancellation eligibility (only when loaded)
        if (cancellation != null) ...[
          RikiInfoBanner(
            message:
                '${context.l10n.mentorMeetingCancellationPolicyTitle}: ${cancellation.message}',
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        if (attendanceRecords != null) ...[
          MentorAttendanceListCard(records: attendanceRecords),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Quick navigation actions: Chat 1-1 & Session Prep
        Row(
          children: [
            Expanded(
              child: RikiSecondaryButton(
                label: context.l10n.mentorMeetingOpenChat,
                leadingIcon: Icons.chat_bubble_outline_rounded,
                onPressed: () =>
                    context.push(AppRoutes.mentorChatRoom(value.id)),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: RikiSecondaryButton(
                label: context.l10n.mentorActionSessionPrep,
                leadingIcon: Icons.checklist_rtl_rounded,
                onPressed: () =>
                    context.push(AppRoutes.mentorMeetingPrep(value.id)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Câu hỏi thực tế từ học viên (từ Backend /api/mentor-bookings)
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
                  Expanded(
                    child: Text(
                      context.l10n.mentorMeetingLearnerQuestion,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                (detail?.question?.trim().isNotEmpty ?? false)
                    ? detail!.question!
                    : (value.question?.trim().isNotEmpty ?? false)
                    ? value.question!
                    : context.l10n.mentorMeetingNoQuestion,
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
          onPressed: () => popOrGo(context, AppRoutes.mentorMeetings),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _MentorPromptDialog(
        title: 'Hủy buổi dạy',
        bannerText:
            'Khi bạn hủy buổi dạy, hệ thống sẽ tự động hoàn lại 1 vé tư vấn cho học viên và giải phóng lịch rảnh của bạn.',
        inputKey: const Key('mentor_cancellation_reason_input'),
        labelText: 'Lý do hủy lịch dạy',
        hintText: 'Nhập lý do báo bận hoặc việc đột xuất...',
        confirmKey: const Key('mentor_confirm_cancel_button'),
        confirmLabel: 'Xác nhận hủy',
        isDestructive: true,
        allowEmptyFallback: 'Cố vấn báo bận',
        onSubmit: (reason) => onCancel?.call(reason),
      ),
    );
  }

  void _showReplyReviewDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _MentorPromptDialog(
        title: 'Phản hồi đánh giá',
        description:
            'Gửi phản hồi cảm ơn hoặc giải đáp thắc mắc của học viên sau buổi học:',
        inputKey: const Key('mentor_reply_review_input'),
        labelText: 'Nội dung phản hồi',
        hintText: 'Cảm ơn bạn đã tham gia buổi học...',
        maxLines: 3,
        confirmKey: const Key('mentor_confirm_reply_button'),
        confirmLabel: 'Gửi phản hồi',
        onSubmit: (reply) => onReplyReview?.call(reply),
      ),
    );
  }

  void _showRespondDisputeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _MentorPromptDialog(
        title: 'Giải trình khiếu nại',
        description:
            'Trình bày chi tiết lý do và bằng chứng từ phía bạn để Quản trị viên xem xét xử lý:',
        inputKey: const Key('mentor_dispute_response_input'),
        labelText: 'Nội dung giải trình',
        hintText: 'Tôi đã có mặt đúng giờ và hoàn thành bài giảng...',
        maxLines: 4,
        confirmKey: const Key('mentor_confirm_dispute_response_button'),
        confirmLabel: 'Gửi giải trình',
        onSubmit: (resp) => onRespondDispute?.call(resp),
      ),
    );
  }
}

Future<int?> _resolveReviewIdForBooking(WidgetRef ref, int bookingId) async {
  final bundle = await ref.read(mentorReviewsControllerProvider.future);
  final existing = bundle.reviews
      .where((r) => r.mentorBookingId == bookingId)
      .firstOrNull;
  if (existing != null) return existing.id;
  final ops = ref.read(mentorOperationsRepositoryProvider);
  for (var page = 2; page <= 5; page++) {
    final items = await ops.loadReviews(
      bundle.mentorId,
      page: page,
      pageSize: 50,
    );
    final match = items.where((r) => r.mentorBookingId == bookingId).firstOrNull;
    if (match != null) return match.id;
    if (items.length < 50) break;
  }
  return null;
}

Future<int?> _resolveDisputeIdForBooking(WidgetRef ref, int bookingId) async {
  final disputes = await ref.read(mentorDisputesControllerProvider.future);
  final existing = disputes
      .where((d) => d.mentorBookingId == bookingId)
      .firstOrNull;
  if (existing != null) return existing.id;
  final ops = ref.read(mentorOperationsRepositoryProvider);
  for (var page = 2; page <= 5; page++) {
    final items = await ops.loadDisputes(page: page, pageSize: 50);
    final match = items.where((d) => d.mentorBookingId == bookingId).firstOrNull;
    if (match != null) return match.id;
    if (items.length < 50) break;
  }
  return null;
}

class _MentorPromptDialog extends StatefulWidget {
  const _MentorPromptDialog({
    required this.title,
    required this.inputKey,
    required this.labelText,
    required this.hintText,
    required this.confirmKey,
    required this.confirmLabel,
    required this.onSubmit,
    this.bannerText,
    this.description,
    this.maxLines = 1,
    this.isDestructive = false,
    this.allowEmptyFallback,
  });

  final String title;
  final String? bannerText;
  final String? description;
  final Key inputKey;
  final String labelText;
  final String hintText;
  final int maxLines;
  final Key confirmKey;
  final String confirmLabel;
  final bool isDestructive;
  final String? allowEmptyFallback;
  final ValueChanged<String> onSubmit;

  @override
  State<_MentorPromptDialog> createState() => _MentorPromptDialogState();
}

class _MentorPromptDialogState extends State<_MentorPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.bannerText != null) ...[
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
                      widget.bannerText!,
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
          ],
          if (widget.description != null) ...[
            Text(widget.description!, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: AppSpacing.space3),
          ],
          TextField(
            key: widget.inputKey,
            controller: _controller,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.mentorCommonCancel),
        ),
        ElevatedButton(
          key: widget.confirmKey,
          style: widget.isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () {
            final text = _controller.text.trim();
            final effective = text.isEmpty ? widget.allowEmptyFallback : text;
            Navigator.of(context).pop();
            if (effective != null && effective.isNotEmpty) {
              widget.onSubmit(effective);
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
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
