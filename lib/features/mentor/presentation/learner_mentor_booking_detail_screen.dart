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
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.booking, required this.onJoin});

  final LearnerMentorBooking? booking;
  final Future<void> Function(LearnerMentorBooking booking) onJoin;

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

        // 2. Sakura Stepper 3 bước (Screen 11 vs Screen 12)
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
        if (!canJoin)
          RikiInfoBanner(
            key: const Key('learner_mentor_join_unavailable'),
            message: isAssigned
                ? 'Nút vào phòng học sẽ sẵn sàng sau khi Mentor xác nhận buổi học.'
                : context.l10n.learnerMentorJoinUnavailable,
          )
        else
          RikiPrimaryButton(
            key: const Key('learner_mentor_join_button'),
            label: context.l10n.learnerMentorJoin,
            leadingIcon: Icons.videocam_outlined,
            onPressed: () => onJoin(value),
          ),

        // 5. Checklist chuẩn bị (khi đã Accepted)
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
                    const Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.brandPrimary),
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
                _buildChecklistItem('Kiểm tra micro và camera thiết bị hoạt động tốt'),
                const SizedBox(height: AppSpacing.space1),
                _buildChecklistItem('Nên sử dụng tai nghe để có âm thanh tốt nhất'),
                const SizedBox(height: AppSpacing.space1),
                _buildChecklistItem('Chuẩn bị sẵn mục tiêu hoặc câu hỏi về JLPT'),
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
          Expanded(child: _buildStepChip('2. Xác nhận', isAccepted || isCompleted, isAssigned)),
          const Icon(Icons.arrow_forward_ios, size: 8, color: AppColors.border),
          Expanded(child: _buildStepChip('3. Vào học', isCompleted, isAccepted)),
        ],
      ),
    );
  }

  Widget _buildStepChip(String label, bool isDone, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isDone ? Icons.check_circle : (isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked),
          size: 13,
          color: isDone || isActive ? AppColors.brandPrimary : AppColors.textDisabled,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.normal,
              color: isDone || isActive ? AppColors.textPrimary : AppColors.textMuted,
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
