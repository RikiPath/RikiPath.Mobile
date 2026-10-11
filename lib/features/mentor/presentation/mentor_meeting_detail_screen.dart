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
  const _DetailData({required this.meeting, required this.onJoin});

  final MentorMeetingSummary? meeting;
  final Future<void> Function(Uri uri) onJoin;

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
    return ListView(
      key: const Key('mentor_meeting_detail_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        MentorPageHeader(
          title: context.l10n.mentorMeetingDetailTitle,
          subtitle: value.learnerName ?? context.l10n.mentorLearnerUnknown,
        ),
        const SizedBox(height: AppSpacing.space5),
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
        RikiTextButton(
          label: MaterialLocalizations.of(context).backButtonTooltip,
          leadingIcon: Icons.arrow_back,
          onPressed: context.pop,
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
