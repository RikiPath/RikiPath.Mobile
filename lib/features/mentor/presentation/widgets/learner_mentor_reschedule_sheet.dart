import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';

/// Modal bottom sheet cho phép người học chọn khung giờ mới và xác nhận dời lịch hẹn tư vấn.
class LearnerMentorRescheduleSheet extends ConsumerStatefulWidget {
  const LearnerMentorRescheduleSheet({
    required this.booking,
    super.key,
  });

  final LearnerMentorBooking booking;

  static Future<bool?> show(
    BuildContext context, {
    required LearnerMentorBooking booking,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LearnerMentorRescheduleSheet(booking: booking),
    );
  }

  @override
  ConsumerState<LearnerMentorRescheduleSheet> createState() =>
      _LearnerMentorRescheduleSheetState();
}

class _LearnerMentorRescheduleSheetState
    extends ConsumerState<LearnerMentorRescheduleSheet> {
  LearnerMentorAvailability? _selectedSlot;
  bool _isSubmitting = false;

  Future<void> _handleConfirmReschedule() async {
    if (_isSubmitting || _selectedSlot == null) return;
    setState(() => _isSubmitting = true);

    try {
      final success = await ref
          .read(learnerMentorMutationControllerProvider.notifier)
          .rescheduleBooking(
            bookingId: widget.booking.id,
            newSlotId: _selectedSlot!.id,
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        ref.invalidate(learnerMentorBookingsControllerProvider);
        ref.invalidate(learnerCalendarEventsProvider);
        ref.invalidate(mentorCalendarEventsProvider);
        if (widget.booking.mentorId != null) {
          ref.invalidate(
            learnerMentorAvailabilityByMentorControllerProvider(
              widget.booking.mentorId,
            ),
          );
        }

        ref.read(rikiToastServiceProvider.notifier).success(
          title: 'Dời lịch hẹn thành công',
          description: 'Lịch tư vấn đã được chuyển sang khung giờ mới.',
        );
        Navigator.of(context).pop(true);
      } else {
        final mutationState = ref.read(learnerMentorMutationControllerProvider);
        final errorMessage = mutationState.error?.toString() ??
            'Khung giờ mới có thể đã bị đặt hoặc xung đột thời gian nghỉ. Vui lòng chọn khung giờ khác.';
        ref.read(rikiToastServiceProvider.notifier).error(
          title: 'Không thể dời lịch',
          description: errorMessage,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Lỗi dời lịch',
        description: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorId = widget.booking.mentorId;
    final state = mentorId != null
        ? ref.watch(learnerMentorAvailabilityByMentorControllerProvider(mentorId))
        : ref.watch(learnerMentorAvailabilityControllerProvider);

    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', locale);
    final timeFormat = DateFormat('HH:mm', locale);

    final nowUtc = DateTime.now().toUtc();
    final minLeadTime = nowUtc.add(const Duration(hours: 24));

    // Old scheduled times
    final oldStart = widget.booking.scheduledAt?.value.toLocal();
    final oldEnd = oldStart?.add(const Duration(minutes: 90));

    return Container(
      key: const Key('learner_mentor_reschedule_sheet'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space5,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.edit_calendar_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dời lịch hẹn tư vấn',
                      style: AppTypography.sectionTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Chọn khung giờ mới với ${widget.booking.mentorName ?? "Cố vấn"}',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Comparison Card: Current Schedule vs New Schedule
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.cardWarmWhite,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.borderSubtlePink),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch hiện tại:',
                            style: AppTypography.metadata.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            oldStart != null
                                ? '${dateFormat.format(oldStart)} (${timeFormat.format(oldStart)} - ${timeFormat.format(oldEnd!)})'
                                : 'Chưa xác định',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_selectedSlot != null) ...[
                  const Divider(height: AppSpacing.space3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.brandPrimary),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khung giờ mới đã chọn:',
                              style: AppTypography.metadata.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            Text(
                              '${dateFormat.format(_selectedSlot!.startTime.displayValue)} (${timeFormat.format(_selectedSlot!.startTime.displayValue)} - ${timeFormat.format(_selectedSlot!.endTime.displayValue)})',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Policy notice banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.brandPrimary),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    'Dời lịch trước ≥ 24 giờ hoàn toàn miễn phí. Khung giờ cũ sẽ được giải phóng ngay lập tức.',
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.brandPrimary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          Text(
            'Chọn khung giờ khả dụng tiếp theo (90 phút):',
            style: AppTypography.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Slots List
          Expanded(
            child: switch (state) {
              AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
              AsyncError(:final error) => Center(
                child: Text(
                  'Không thể tải danh sách khung giờ: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              AsyncData(:final value) => _buildSlotsList(
                value: value,
                currentSlotId: widget.booking.mentorAvailabilityId,
                minLeadTime: minLeadTime,
                dateFormat: dateFormat,
                timeFormat: timeFormat,
              ),
            },
          ),
          const SizedBox(height: AppSpacing.space3),

          // Confirm Action Button
          RikiPrimaryButton(
            key: const Key('confirm_reschedule_button'),
            label: _isSubmitting
                ? 'Đang dời lịch...'
                : (_selectedSlot != null
                    ? 'Xác nhận dời lịch sang giờ này'
                    : 'Vui lòng chọn khung giờ mới'),
            leadingIcon: Icons.check,
            onPressed: (_isSubmitting || _selectedSlot == null)
                ? null
                : _handleConfirmReschedule,
          ),
          const SizedBox(height: AppSpacing.space2),

          RikiTextButton(
            label: 'Đóng',
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList({
    required List<LearnerMentorAvailability> value,
    required int? currentSlotId,
    required DateTime minLeadTime,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
  }) {
    // Filter eligible future slots of this mentor:
    // 1. Not the current slot
    // 2. Not already booked
    // 3. At least 24h from now
    final eligibleSlots = value.where((slot) {
      if (slot.id == currentSlotId) return false;
      if (slot.isBooked) return false;
      final startUtc = slot.startTime.value.toUtc();
      return startUtc.isAfter(minLeadTime);
    }).toList();

    // Sort chronologically
    eligibleSlots.sort((a, b) => a.startTime.value.compareTo(b.startTime.value));

    if (eligibleSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Hiện chưa có khung giờ trống nào khác sau 24 giờ tới cho cố vấn này.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: eligibleSlots.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space2),
      itemBuilder: (context, index) {
        final slot = eligibleSlots[index];
        final isSelected = _selectedSlot?.id == slot.id;
        final start = slot.startTime.displayValue;
        final end = slot.endTime.displayValue;

        return InkWell(
          key: Key('reschedule_slot_tile_${slot.id}'),
          onTap: () => setState(() => _selectedSlot = slot),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer.withValues(alpha: 0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isSelected ? AppColors.brandPrimary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: AppSpacing.space2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.brandPrimary : AppColors.border,
                      width: isSelected ? 6 : 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(start),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${timeFormat.format(start)} - ${timeFormat.format(end)} (90 phút)',
                        style: AppTypography.metadata.copyWith(
                          color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
