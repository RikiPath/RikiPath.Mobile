import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Shared dispute categories aligned with Backend `MentorDisputeCategory` (1..7).
const List<(int, String)> learnerMentorDisputeCategories = [
  (1, 'Cố vấn vắng mặt không báo trước'),
  (2, 'Buổi tư vấn không diễn ra'),
  (3, 'Sự cố phòng học trực tuyến / kết nối'),
  (4, 'Chất lượng tư vấn không như cam kết'),
  (5, 'Hành vi / ứng xử chưa phù hợp'),
  (6, 'Vấn đề chính sách / hoàn vé'),
  (7, 'Lý do khác'),
];

/// Shared learner booking cancellation dialog checking Backend eligibility rules.
Future<bool> showLearnerBookingCancellationDialog(
  BuildContext context,
  WidgetRef ref, {
  required int bookingId,
  DateTime? scheduledAtUtc,
  VoidCallback? onCancelled,
}) async {
  final hostContext = context;
  final now = DateTime.now().toUtc();
  bool isEligibleForRefund;
  bool canCancel = true;
  String? policyMessage;

  try {
    final eligibility = await ref
        .read(learnerMentorRepositoryProvider)
        .checkCancellationEligibility(bookingId);
    canCancel = eligibility.isEligible;
    isEligibleForRefund = eligibility.isFullRefund;
    policyMessage = eligibility.message;
  } catch (_) {
    final start = scheduledAtUtc ?? now;
    isEligibleForRefund =
        start.difference(now) >= const Duration(hours: 24);
  }

  if (!hostContext.mounted) return false;
  if (!canCancel) {
    ref.read(rikiToastServiceProvider.notifier).warning(
          title: 'Không thể hủy lịch hẹn',
          description: policyMessage?.isNotEmpty == true
              ? policyMessage!
              : 'Lịch hẹn này hiện không còn đủ điều kiện hủy.',
        );
    return false;
  }

  final reasonController = TextEditingController();
  final exceptionController = TextEditingController();
  var requestException = false;
  var didCancel = false;

  await showDialog<void>(
    context: hostContext,
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
                if (!hostContext.mounted) return;
                final l10n = hostContext.l10n;
                final mutation = ref.read(
                  learnerMentorMutationControllerProvider.notifier,
                );
                final toast = ref.read(rikiToastServiceProvider.notifier);
                final ok = await runWithAppLoadingOverlay<bool>(
                  hostContext,
                  title: l10n.loadingOverlayProcessingTitle,
                  subtitle: l10n.loadingOverlayUpdatingSubtitle,
                  action: () => mutation.cancelBooking(
                    bookingId: bookingId,
                    reason: reason,
                    requestException: requestException,
                    exceptionReason: exceptionController.text.trim(),
                  ),
                );
                if (ok) {
                  didCancel = true;
                  toast.success(
                    title: 'Hủy lịch hẹn thành công',
                    description: isEligibleForRefund
                        ? '1 vé tư vấn đã được hoàn trả.'
                        : 'Yêu cầu hủy đã được ghi nhận.',
                  );
                  ref.invalidate(learnerMentorBookingsControllerProvider);
                  ref.invalidate(learnerCalendarEventsProvider);
                  ref.invalidate(mentorCalendarEventsProvider);
                  onCancelled?.call();
                } else {
                  toast.error(
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

  reasonController.dispose();
  exceptionController.dispose();
  return didCancel;
}

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

String learnerMentorBookingStatusLabel(
  MentorMeetingStatus status,
  BuildContext context,
) => status == MentorMeetingStatus.assigned
    ? context.l10n.learnerMentorStatusAssigned
    : mentorStatusLabel(status, context);

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
              if (plan.jlptLevel != null && plan.jlptLevel!.isNotEmpty)
                _MetaPill(
                  icon: Icons.school_outlined,
                  label: plan.jlptLevel!.toUpperCase().startsWith('JLPT')
                      ? plan.jlptLevel!
                      : 'JLPT ${plan.jlptLevel}',
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
                          label: learnerMentorBookingStatusLabel(
                            booking.status,
                            context,
                          ),
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
