import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

String learnerMentorPaymentStatusLabel(
  MentorPaymentStatus? status,
  BuildContext context,
) => switch (status) {
  MentorPaymentStatus.pending => context.l10n.learnerMentorPaymentPending,
  MentorPaymentStatus.paid => context.l10n.learnerMentorPaymentPaid,
  MentorPaymentStatus.failed => context.l10n.learnerMentorPaymentFailed,
  MentorPaymentStatus.refunded => context.l10n.learnerMentorPaymentRefunded,
  MentorPaymentStatus.unknown ||
  null => context.l10n.learnerMentorPaymentUnknown,
};

String learnerMentorDateLabel(MentorTimestamp timestamp, BuildContext context) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMMd(locale).format(timestamp.displayValue);
}

String learnerMentorTimeRangeLabel(
  LearnerMentorAvailability slot,
  BuildContext context,
) {
  final format = DateFormat('HH:mm');
  return context.l10n.learnerMentorSlotTime(
    format.format(slot.startTime.displayValue),
    format.format(slot.endTime.displayValue),
  );
}

String learnerMentorPriceLabel(double price, BuildContext context) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.currency(
    locale: locale,
    symbol: '₫',
    decimalDigits: 0,
  ).format(price);
}

class LearnerMentorPlanCard extends StatelessWidget {
  const LearnerMentorPlanCard({
    required this.plan,
    required this.onTap,
    super.key,
  });

  final MentorMeetingPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: AppShadows.cardSoft,
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AccentIcon(icon: Icons.support_agent_outlined),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      learnerMentorPriceLabel(plan.price, context),
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.description case final description?) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _MetaPill(
                icon: Icons.calendar_month_outlined,
                label: context.l10n.learnerMentorPlanDuration(
                  plan.durationDays,
                ),
              ),
              _MetaPill(
                icon: Icons.video_call_outlined,
                label: context.l10n.learnerMentorPlanSessions(
                  plan.meetingSessionCount,
                ),
              ),
            ],
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            for (final feature in plan.features) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(feature.name, style: AppTypography.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),
            ],
          ],
          const SizedBox(height: AppSpacing.space3),
          RikiPrimaryButton(
            label: context.l10n.learnerMentorChoosePlan,
            trailingIcon: Icons.arrow_forward,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class LearnerMentorAvailabilityCard extends StatelessWidget {
  const LearnerMentorAvailabilityCard({
    required this.slot,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LearnerMentorAvailability slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RikiSelectionCard(
      title: slot.mentorName,
      description: learnerMentorTimeRangeLabel(slot, context),
      leading: _AccentIcon(
        icon: Icons.schedule_outlined,
        color: selected ? AppColors.brandPrimary : AppColors.success,
        backgroundColor: selected
            ? AppColors.brandTint
            : AppColors.successBackground,
      ),
      selected: selected,
      onPressed: onTap,
    );
  }
}

class LearnerMentorBookingCard extends StatelessWidget {
  const LearnerMentorBookingCard({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final LearnerMentorBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mentorName = booking.mentorName?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: AppColors.border,
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              const _AccentIcon(icon: Icons.video_call_outlined),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentorName == null || mentorName.isEmpty
                          ? context.l10n.learnerMentorUnknownMentor
                          : mentorName,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      mentorTimeLabel(booking.scheduledAt, context),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      children: [
                        _MetaPill(
                          icon: Icons.verified_outlined,
                          label: mentorStatusLabel(booking.status, context),
                        ),
                        _MetaPill(
                          icon: Icons.payments_outlined,
                          label: learnerMentorPaymentStatusLabel(
                            booking.paymentStatus,
                            context,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class LearnerMentorDetailRow extends StatelessWidget {
  const LearnerMentorDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccentIcon(icon: icon),
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

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({
    required this.icon,
    this.color = AppColors.brandPrimary,
    this.backgroundColor = AppColors.brandTint,
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
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.badgeText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
