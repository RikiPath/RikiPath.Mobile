import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

class MeetingHomeSection extends StatelessWidget {
  const MeetingHomeSection({
    required this.state,
    required this.onOpenMeeting,
    required this.onOpenDetail,
    required this.onJoin,
    super.key,
  });

  final AsyncValue<UpcomingMeeting?> state;
  final VoidCallback onOpenMeeting;
  final ValueChanged<int> onOpenDetail;
  final ValueChanged<Uri> onJoin;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const RikiSkeleton(
        key: ValueKey<String>('home_meeting_loading'),
        height: 132,
        borderRadius: AppRadius.card,
      );
    }
    final meeting = state.value;
    if (state.hasError || meeting == null) {
      return _MeetingShortcut(onPressed: onOpenMeeting);
    }

    final scheduled = meeting.scheduledAt.displayValue;
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(scheduled);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(scheduled),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final mentor = meeting.mentorName?.trim();
    final status = meeting.status == MentorMeetingStatus.accepted
        ? context.l10n.mentorStatusAccepted
        : context.l10n.mentorStatusAssigned;

    return RikiCard(
      key: const ValueKey<String>('home_upcoming_meeting_card'),
      boxShadow: AppShadows.cardSoft,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MeetingIcon(),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeUpcomingMeetingTitle,
                      style: AppTypography.cardTitle,
                    ),
                    if (mentor != null && mentor.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(mentor, style: AppTypography.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      context.l10n.homeMeetingSchedule(date, time),
                      style: AppTypography.metadata,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      status,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              TextButton(
                key: const ValueKey<String>('home_meeting_detail_button'),
                onPressed: () => onOpenDetail(meeting.bookingId),
                child: Text(context.l10n.meetingDetailsAction),
              ),
              FilledButton.icon(
                key: const ValueKey<String>('home_meeting_join_button'),
                onPressed: () => onJoin(meeting.meetingUri),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(context.l10n.meetingEnterRoom),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeetingShortcut extends StatelessWidget {
  const _MeetingShortcut({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      key: const ValueKey<String>('home_meeting_fallback_card'),
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Row(
        children: [
          const _MeetingIcon(),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeMeetingFallbackTitle,
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  context.l10n.homeMeetingFallbackDescription,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey<String>('home_meeting_shortcut_button'),
            tooltip: context.l10n.meetingJoinAction,
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class _MeetingIcon extends StatelessWidget {
  const _MeetingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: const Icon(Icons.videocam_outlined, color: AppColors.brandPrimary),
    );
  }
}
