import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

String mentorTimeLabel(MentorTimestamp? timestamp, BuildContext context) {
  if (timestamp == null) return context.l10n.mentorSchedulePending;
  return DateFormat('dd/MM/yyyy • HH:mm').format(timestamp.displayValue);
}

String mentorStatusLabel(MentorMeetingStatus status, BuildContext context) =>
    switch (status) {
      MentorMeetingStatus.awaitingPayment =>
        context.l10n.mentorStatusAwaitingPayment,
      MentorMeetingStatus.pendingAssignment =>
        context.l10n.mentorStatusPendingAssignment,
      MentorMeetingStatus.assigned => context.l10n.mentorStatusAssigned,
      MentorMeetingStatus.accepted => context.l10n.mentorStatusAccepted,
      MentorMeetingStatus.completed => context.l10n.mentorStatusCompleted,
      MentorMeetingStatus.cancelled => context.l10n.mentorStatusCancelled,
      MentorMeetingStatus.unknown => context.l10n.mentorStatusUnknown,
    };

class MentorPageHeader extends StatelessWidget {
  const MentorPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.compactPageTitle),
        const SizedBox(height: AppSpacing.space1),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class MentorAvailabilityCard extends StatelessWidget {
  const MentorAvailabilityCard({required this.slot, super.key});

  final MentorAvailabilitySlot slot;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: AppShadows.cardSoft,
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MentorIconTile(
            icon: slot.isBooked
                ? Icons.event_busy_outlined
                : Icons.event_available_outlined,
            color: slot.isBooked ? AppColors.textSecondary : AppColors.success,
            backgroundColor: slot.isBooked
                ? AppColors.surfaceSubtle
                : AppColors.successBackground,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.isBooked
                      ? context.l10n.mentorSlotBooked
                      : context.l10n.mentorSlotOpen,
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                _LabelValue(
                  label: context.l10n.mentorStartTimeLabel,
                  value: mentorTimeLabel(slot.startTime, context),
                ),
                const SizedBox(height: AppSpacing.space1),
                _LabelValue(
                  label: context.l10n.mentorEndTimeLabel,
                  value: mentorTimeLabel(slot.endTime, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MentorMeetingCard extends StatelessWidget {
  const MentorMeetingCard({required this.meeting, this.onTap, super.key});

  final MentorMeetingSummary meeting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: RikiCard(
            boxShadow: AppShadows.cardSoft,
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MentorIconTile(
                  icon: Icons.video_call_outlined,
                  color: AppColors.brandPrimary,
                  backgroundColor: AppColors.brandTint,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.learnerName ??
                            context.l10n.mentorLearnerUnknown,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        mentorTimeLabel(meeting.scheduledAt, context),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      _StatusPill(status: meeting.status),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MentorEmptyState extends StatelessWidget {
  const MentorEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(icon: icon, title: title, message: description);
  }
}

class MentorErrorState extends StatelessWidget {
  const MentorErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      title: context.l10n.toastActionFailedTitle,
      message: message,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
      compact: true,
    );
  }
}

class MentorListSkeleton extends StatelessWidget {
  const MentorListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const RikiSectionSkeleton(
      itemCount: 3,
      cardHeight: 118,
      showSearch: false,
      showFilters: false,
    );
  }
}

class _MentorIconTile extends StatelessWidget {
  const _MentorIconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTypography.metadata.copyWith(color: AppColors.textMuted),
          ),
          TextSpan(
            text: value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final MentorMeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == MentorMeetingStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.successBackground : AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        mentorStatusLabel(status, context),
        style: AppTypography.badgeText.copyWith(
          color: isCompleted ? AppColors.success : AppColors.brandPrimary,
        ),
      ),
    );
  }
}
