import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_order_confirmation_sheet.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình chọn ngày học (Lịch tháng) và khung giờ học khả dụng với Mentor (Screen 04 & 05).
class LearnerMentorAvailabilityScreen extends ConsumerStatefulWidget {
  const LearnerMentorAvailabilityScreen({
    required this.planId,
    this.subscriptionId,
    this.mentorId,
    super.key,
  });

  final int? planId;
  final int? subscriptionId;
  final int? mentorId;

  @override
  ConsumerState<LearnerMentorAvailabilityScreen> createState() =>
      _LearnerMentorAvailabilityScreenState();
}

class _LearnerMentorAvailabilityScreenState
    extends ConsumerState<LearnerMentorAvailabilityScreen> {
  DateTime? _selectedDate;
  int? _selectedSlotId;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    // Nếu có mentorId thì ưu tiên load theo mentorId, ngược lại fallback load toàn bộ
    final state = widget.mentorId != null
        ? ref.watch(
            learnerMentorAvailabilityByMentorControllerProvider(
              widget.mentorId,
            ),
          )
        : ref.watch(learnerMentorAvailabilityControllerProvider);

    return Scaffold(
      key: const Key('learner_mentor_availability_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Chọn ngày học'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.space3),
            child: RikiLanguageSwitcher(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_mentor_availability_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('learner_mentor_availability_error'),
              message: context.l10n.learnerMentorAvailabilityError,
              onRetry: () {
                if (widget.mentorId != null) {
                  ref
                      .read(
                        learnerMentorAvailabilityByMentorControllerProvider(
                          widget.mentorId,
                        ).notifier,
                      )
                      .retry();
                } else {
                  ref
                      .read(
                        learnerMentorAvailabilityControllerProvider.notifier,
                      )
                      .retry();
                }
              },
            ),
          ),
          AsyncData(:final value) => _buildContent(value),
        },
      ),
      bottomNavigationBar: state is AsyncData<List<LearnerMentorAvailability>>
          ? _buildBottomBar(context, state.value)
          : null,
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    List<LearnerMentorAvailability> allSlots,
  ) {
    final availableSlots = allSlots
        .where((slot) => !slot.isBooked)
        .toList(growable: false);
    final selectedSlot = availableSlots
        .where((slot) => slot.id == _selectedSlotId)
        .firstOrNull;
    final plansState = ref.watch(learnerMentorPlansControllerProvider);
    final currentPlan = plansState.value
        ?.where((plan) => plan.id == widget.planId)
        .firstOrNull;
    final isExistingSubscription =
        widget.subscriptionId != null && widget.subscriptionId! > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: AppShadows.cardSoft,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.space2,
        AppSpacing.screenHorizontal,
        AppSpacing.space3,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedSlot != null) ...[
              RikiCard(
                key: const Key('learner_mentor_selected_slot_card'),
                borderColor: AppColors.brandPrimary.withValues(alpha: 0.35),
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.04),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color: AppColors.brandPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedSlot.mentorName} • ${_formatSlotTime(selectedSlot, context)}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isExistingSubscription
                                ? context.l10n.learnerMentorIncludedSession
                                : 'Nhấn tiếp tục để xem tóm tắt đơn và thanh toán',
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
              const SizedBox(height: AppSpacing.space2),
            ],
            RikiPrimaryButton(
              key: const Key('learner_mentor_purchase_button'),
              label: selectedSlot == null
                  ? 'Chọn giờ học'
                  : (isExistingSubscription
                        ? 'Xác nhận đặt lịch'
                        : 'Tiếp tục thanh toán'),
              leadingIcon: selectedSlot == null
                  ? Icons.touch_app_outlined
                  : (isExistingSubscription
                        ? Icons.calendar_month_outlined
                        : Icons.arrow_forward),
              onPressed: selectedSlot == null
                  ? null
                  : () => _openConfirmation(context, selectedSlot, currentPlan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<LearnerMentorAvailability> allSlots) {
    final availableSlots = allSlots
        .where((slot) => !slot.isBooked)
        .toList(growable: false);

    final dates = <DateTime>[];
    for (final slot in availableSlots) {
      final date = DateUtils.dateOnly(slot.startTime.displayValue);
      if (!dates.any((value) => DateUtils.isSameDay(value, date))) {
        dates.add(date);
      }
    }
    dates.sort();

    final activeDate =
        dates.any((date) => DateUtils.isSameDay(date, _selectedDate))
        ? _selectedDate
        : dates.firstOrNull;

    // Cập nhật tháng hiển thị theo ngày có slot đầu tiên nếu chưa chọn tháng
    if (_selectedDate == null && activeDate != null) {
      _displayedMonth = DateTime(activeDate.year, activeDate.month);
    }

    final visibleSlots = activeDate == null
        ? const <LearnerMentorAvailability>[]
        : availableSlots
              .where(
                (slot) => DateUtils.isSameDay(
                  slot.startTime.displayValue,
                  activeDate,
                ),
              )
              .toList(growable: false);

    final selectedSlot = visibleSlots
        .where((slot) => slot.id == _selectedSlotId)
        .firstOrNull;

    // Lấy thông tin gói tương ứng từ read model
    final plansState = ref.watch(learnerMentorPlansControllerProvider);
    final currentPlan = plansState.value
        ?.where((plan) => plan.id == widget.planId)
        .firstOrNull;

    // Thông tin Mentor được chọn
    final mentorName =
        selectedSlot?.mentorName ??
        visibleSlots.firstOrNull?.mentorName ??
        'Mentor RikiPath';

    return ListView(
      key: const Key('learner_mentor_availability_list'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        // 1. Mentor Context Strip (Screen 04 Top tactile card)
        RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: AppColors.border,
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brandTint,
                child: Text(
                  mentorName.isNotEmpty
                      ? mentorName.substring(0, 1).toUpperCase()
                      : 'M',
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mentorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '50 phút/buổi',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (currentPlan != null) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  learnerMentorPriceLabel(currentPlan.price, context),
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // 2. Neo-Japoniste Monthly Calendar (Monday-first)
        RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: AppColors.border,
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header tháng & nút chuyển tháng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHỌN NGÀY HỌC',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'MMMM, yyyy',
                            'vi_VN',
                          ).format(_displayedMonth),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sectionTitle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            _displayedMonth = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month - 1,
                            );
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            _displayedMonth = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),

              // Dòng thứ trong tuần: T2, T3, T4, T5, T6, T7, CN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _WeekdayLabel('T2'),
                  _WeekdayLabel('T3'),
                  _WeekdayLabel('T4'),
                  _WeekdayLabel('T5'),
                  _WeekdayLabel('T6'),
                  _WeekdayLabel('T7', isWeekend: true),
                  _WeekdayLabel('CN', isWeekend: true),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              // Lưới ô ngày của tháng
              _buildMonthGrid(activeDate, dates),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Quick date selector chips (giúp thao tác nhanh giữa các ngày có slot)
        if (dates.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final date in dates) ...[
                  ChoiceChip(
                    key: ValueKey<String>(
                      'learner_mentor_date_${date.toIso8601String()}',
                    ),
                    label: Text(
                      DateFormat.MMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(date),
                    ),
                    selected: DateUtils.isSameDay(date, activeDate),
                    selectedColor: AppColors.brandTint,
                    labelStyle: TextStyle(
                      color: DateUtils.isSameDay(date, activeDate)
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary,
                      fontWeight: DateUtils.isSameDay(date, activeDate)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: DateUtils.isSameDay(date, activeDate)
                          ? AppColors.brandPrimary
                          : AppColors.border,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedDate = date;
                        _selectedSlotId = null;
                        _displayedMonth = DateTime(date.year, date.month);
                      });
                    },
                  ),
                  const SizedBox(width: AppSpacing.space2),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.space4),

        // 3. Khung giờ trống (Screen 05: Phân chia Sáng / Chiều / Tối)
        Text(
          'KHUNG GIỜ CÒN TRỐNG',
          style: AppTypography.metadata.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        if (visibleSlots.isEmpty)
          MentorEmptyState(
            key: const Key('learner_mentor_availability_empty'),
            icon: Icons.event_busy_outlined,
            title: 'Chưa có lịch trống',
            description:
                'Mentor này chưa có lịch trống trong ngày đã chọn. Vui lòng chọn một ngày khác có chấm hồng trên lịch.',
          )
        else
          ..._buildTimeSlotGroups(visibleSlots),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildMonthGrid(DateTime? activeDate, List<DateTime> datesWithSlots) {
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    // Monday is 1, Sunday is 7. Offset = firstDayOfMonth.weekday - 1
    final leadingEmptyCells = firstDayOfMonth.weekday - 1;

    final today = DateUtils.dateOnly(DateTime.now());

    final totalCells = leadingEmptyCells + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: [
        for (int row = 0; row < rowCount; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int col = 0; col < 7; col++) ...[
                () {
                  final cellIndex = row * 7 + col;
                  final dayNumber = cellIndex - leadingEmptyCells + 1;
                  if (cellIndex < leadingEmptyCells ||
                      dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final cellDate = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month,
                    dayNumber,
                  );
                  final isPast = cellDate.isBefore(today);
                  final hasSlots = datesWithSlots.any(
                    (d) => DateUtils.isSameDay(d, cellDate),
                  );
                  final isSelected =
                      activeDate != null &&
                      DateUtils.isSameDay(cellDate, activeDate);

                  return Expanded(
                    child: Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: isPast
                            ? null
                            : () {
                                setState(() {
                                  _selectedDate = cellDate;
                                  _selectedSlotId = null;
                                });
                              },
                        child: Container(
                          width: 32,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: isSelected
                              ? const BoxDecoration(
                                  color: AppColors.brandPrimary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isPast
                                            ? AppColors.textDisabled
                                            : (hasSlots
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary)),
                                ),
                              ),
                              if (hasSlots) ...[
                                const SizedBox(height: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.brandPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ] else
                                const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
              ],
            ],
          ),
      ],
    );
  }

  List<Widget> _buildTimeSlotGroups(List<LearnerMentorAvailability> slots) {
    final morningSlots = <LearnerMentorAvailability>[];
    final afternoonSlots = <LearnerMentorAvailability>[];
    final eveningSlots = <LearnerMentorAvailability>[];

    for (final slot in slots) {
      final hour = slot.startTime.displayValue.hour;
      if (hour < 12) {
        morningSlots.add(slot);
      } else if (hour < 18) {
        afternoonSlots.add(slot);
      } else {
        eveningSlots.add(slot);
      }
    }

    final widgets = <Widget>[];

    void addGroup(
      String title,
      IconData icon,
      List<LearnerMentorAvailability> groupSlots,
    ) {
      if (groupSlots.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space3,
            bottom: AppSpacing.space2,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.brandPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (var i = 0; i < groupSlots.length; i++) {
        final slot = groupSlots[i];
        final isSelected = _selectedSlotId == slot.id;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: LearnerMentorAvailabilityCard(
              key: ValueKey<String>('learner_mentor_slot_${slot.id}'),
              slot: slot,
              selected: isSelected,
              onTap: () => setState(() => _selectedSlotId = slot.id),
            ),
          ),
        );
      }
    }

    addGroup(
      'Buổi sáng (08:00 - 12:00)',
      Icons.wb_sunny_outlined,
      morningSlots,
    );
    addGroup(
      'Buổi chiều (12:00 - 18:00)',
      Icons.wb_twilight_outlined,
      afternoonSlots,
    );
    addGroup(
      'Buổi tối (18:00 - 22:00)',
      Icons.nightlight_outlined,
      eveningSlots,
    );

    return widgets;
  }

  String _formatSlotTime(LearnerMentorAvailability slot, BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = DateFormat(
      'HH:mm',
      locale,
    ).format(slot.startTime.displayValue);
    final end = DateFormat('HH:mm', locale).format(slot.endTime.displayValue);
    return '$start - $end';
  }

  void _openConfirmation(
    BuildContext context,
    LearnerMentorAvailability slot,
    MentorMeetingPlan? plan,
  ) {
    final effectivePlanId = widget.planId ?? plan?.id ?? 1;
    LearnerMentorOrderConfirmationSheet.show(
      context,
      planId: effectivePlanId,
      slot: slot,
      plan: plan,
      subscriptionId: widget.subscriptionId,
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text, {this.isWeekend = false});

  final String text;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isWeekend ? AppColors.brandPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
