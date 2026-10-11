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
    return ListView(
      key: const Key('learner_mentor_booking_detail_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: AppColors.border,
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
                value: mentorStatusLabel(value.status, context),
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
        const SizedBox(height: AppSpacing.space4),
        RikiSecondaryButton(
          key: const Key('learner_mentor_purchase_status_button'),
          label: context.l10n.learnerMentorPurchaseStatus,
          leadingIcon: Icons.receipt_long_outlined,
          onPressed: () => context.push(
            AppRoutes.learnerMentorPurchaseStatus(value.userSubscriptionId),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (!canJoin)
          RikiInfoBanner(
            key: const Key('learner_mentor_join_unavailable'),
            message: context.l10n.learnerMentorJoinUnavailable,
          )
        else
          RikiPrimaryButton(
            key: const Key('learner_mentor_join_button'),
            label: context.l10n.learnerMentorJoin,
            leadingIcon: Icons.videocam_outlined,
            onPressed: () => onJoin(value),
          ),
      ],
    );
  }
}
