import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/availability_conflicts.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_order_confirmation_sheet.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình chọn ngày học (Lịch tháng) và khung giờ học khả dụng với Mentor (Screen 04 & 05).
class LearnerMentorAvailabilityScreen extends ConsumerStatefulWidget {
  const LearnerMentorAvailabilityScreen({
    required this.planId,
    this.subscriptionId,
    this.mentorId,
    this.initialDate,
    this.initialAvailabilityId,
    super.key,
  });

  final int? planId;
  final int? subscriptionId;
  final int? mentorId;
  final DateTime? initialDate;
  final int? initialAvailabilityId;

  @override
  ConsumerState<LearnerMentorAvailabilityScreen> createState() =>
      _LearnerMentorAvailabilityScreenState();
}

class _LearnerMentorAvailabilityScreenState
    extends ConsumerState<LearnerMentorAvailabilityScreen> {
  DateTime? _selectedDate;
  int? _selectedSlotId;
  bool _checkingSlot = false;
  late DateTime _displayedMonth;
  late DateTime _dateStripStart;
  String? _selectedJlptLevel;
  _SlotTimeFilter _timeFilter = _SlotTimeFilter.all;

  Future<void> _pickFinderDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final last = today.add(const Duration(days: 89));
    final selectedDate = _selectedDate ?? today;
    final initial = selectedDate.isBefore(today)
        ? today
        : selectedDate.isAfter(last)
        ? last
        : selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
        _selectedSlotId = null;
        _dateStripStart = _selectedDate!;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDate == null
        ? (widget.planId == null ? DateUtils.dateOnly(now) : null)
        : DateUtils.dateOnly(widget.initialDate!);
    _selectedSlotId = widget.initialAvailabilityId;
    final displayedDate = _selectedDate ?? now;
    _displayedMonth = DateTime(displayedDate.year, displayedDate.month);
    final stripAnchor = DateUtils.dateOnly(
      displayedDate,
    ).subtract(const Duration(days: 2));
    final today = DateUtils.dateOnly(now);
    _dateStripStart = stripAnchor.isBefore(today) ? today : stripAnchor;
  }

  @override
  Widget build(BuildContext context) {
    final credit = widget.planId == null
        ? ref.watch(learnerCreditBalanceControllerProvider).value
        : null;
    final grantLevels =
        credit?.activeGrants
            .where(
              (grant) =>
                  grant.availableQuantity > 0 &&
                  isSupportedConsultationJlptLevel(grant.jlptLevel),
            )
            .map((grant) => normalizeConsultationJlptLevel(grant.jlptLevel))
            .toSet() ??
        <String>{};
    final level =
        _selectedJlptLevel ??
        (grantLevels.length == 1 ? grantLevels.single : null);
    final query = (
      day: _selectedDate ?? DateUtils.dateOnly(DateTime.now()),
      mentorId: widget.mentorId,
      jlptLevel: level,
    );
    final AsyncValue<List<LearnerMentorAvailability>> state =
        widget.planId == null
        ? ref.watch(learnerMentorSlotsForDayProvider(query))
        : widget.mentorId != null
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
        title: Text(
          widget.planId == null
              ? context.l10n.mentorFinderTitle
              : 'Chọn ngày học',
        ),
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
                if (widget.planId == null) {
                  ref.invalidate(learnerMentorSlotsForDayProvider(query));
                } else if (widget.mentorId != null) {
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
          AsyncData(:final value) =>
            widget.planId == null
                ? _buildFinderContent(value, level)
                : _buildContent(value),
        },
      ),
      bottomNavigationBar: state is AsyncData<List<LearnerMentorAvailability>>
          ? widget.planId == null
                ? _buildFinderBottomBar(state.value, level)
                : _buildBottomBar(context, state.value)
          : null,
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    List<LearnerMentorAvailability> allSlots,
  ) {
    final conflictView = AvailabilityConflictView(allSlots);
    final availableSlots = conflictView.slots
        .where(conflictView.canBook)
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
              onPressed: selectedSlot == null || _checkingSlot
                  ? null
                  : () => _openConfirmation(selectedSlot, currentPlan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinderContent(
    List<LearnerMentorAvailability> slots,
    String? level,
  ) {
    final selectedDate = _selectedDate ?? DateUtils.dateOnly(DateTime.now());
    final now = DateTime.now();
    final conflicts = AvailabilityConflictView(slots);
    final available = conflicts.slots
        .where((slot) {
          final start = slot.startTime.displayValue;
          final minutes = slot.endTime.value
              .difference(slot.startTime.value)
              .inMinutes;
          return conflicts.canBook(slot) &&
              !slot.isBooked &&
              start.isAfter(now) &&
              minutes == 90 &&
              DateUtils.isSameDay(start, selectedDate) &&
              _timeFilter.includes(start.hour);
        })
        .toList(growable: false);
    final mentors =
        ref.watch(learnerMentorListControllerProvider).value ??
        const <BookableMentor>[];
    final grouped = <int, List<LearnerMentorAvailability>>{};
    for (final slot in available) {
      grouped.putIfAbsent(slot.mentorId, () => []).add(slot);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          learnerMentorSlotsForDayProvider((
            day: selectedDate,
            mentorId: widget.mentorId,
            jlptLevel: level,
          )),
        );
        await ref.read(
          learnerMentorSlotsForDayProvider((
            day: selectedDate,
            mentorId: widget.mentorId,
            jlptLevel: level,
          )).future,
        );
      },
      child: ListView(
        key: const Key('learner_mentor_availability_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text(
            context.l10n.mentorFinderChooseDate,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = _dateStripStart.add(Duration(days: index));
                      final selected = DateUtils.isSameDay(day, selectedDate);
                      return ChoiceChip(
                        key: ValueKey<String>(
                          'learner_mentor_date_${day.toIso8601String()}',
                        ),
                        selected: selected,
                        selectedColor: AppColors.brandTint,
                        side: BorderSide(
                          color: selected
                              ? AppColors.brandPrimary
                              : AppColors.border,
                        ),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.E(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(day),
                            ),
                            Text('${day.day}', style: AppTypography.cardTitle),
                          ],
                        ),
                        onSelected: (_) => setState(() {
                          _selectedDate = day;
                          _selectedSlotId = null;
                        }),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.mentorFinderPickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: _pickFinderDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.mentorFinderJlptLevel,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const ['N5', 'N4', 'N3', 'N2'])
                ChoiceChip(
                  key: ValueKey<String>('finder_level_$option'),
                  label: Text(option),
                  selected: level == option,
                  selectedColor: AppColors.brandTint,
                  onSelected: (_) => setState(() {
                    _selectedJlptLevel = option;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in _SlotTimeFilter.values) ...[
                  ChoiceChip(
                    key: ValueKey<String>('finder_time_${filter.name}'),
                    label: Text(filter.label(context)),
                    selected: _timeFilter == filter,
                    selectedColor: AppColors.brandTint,
                    onSelected: (_) => setState(() {
                      _timeFilter = filter;
                      _selectedSlotId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (level == null) Text(context.l10n.mentorFinderChooseLevel),
          if (level != null && available.isEmpty) ...[
            MentorEmptyState(
              key: const Key('learner_mentor_availability_empty'),
              icon: Icons.event_busy_outlined,
              title: context.l10n.mentorFinderNoSlotsTitle,
              description: context.l10n.mentorFinderNoSlotsDescription,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFinderDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(context.l10n.mentorFinderChooseAnotherDate),
            ),
          ],
          if (level != null)
            for (final entry in grouped.entries) ...[
              Builder(
                builder: (context) {
                  final profile = mentors
                      .where((m) => m.id == entry.key)
                      .firstOrNull;
                  final name = profile?.name ?? entry.value.first.mentorName;
                  final avatarUri = safeExternalHttpUri(profile?.avatarUrl);
                  return RikiCard(
                    key: ValueKey<String>('finder_mentor_${entry.key}'),
                    boxShadow: AppShadows.cardSoft,
                    borderColor: AppColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.brandTint,
                              foregroundImage: avatarUri == null
                                  ? null
                                  : NetworkImage(avatarUri.toString()),
                              child: Text(
                                name.isEmpty ? '?' : name.characters.first,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.cardTitle,
                                  ),
                                  if (profile?.headline?.trim().isNotEmpty ==
                                      true)
                                    Text(
                                      profile!.headline!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.mentorFinderAvailableSlots,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final slot in entry.value)
                              ChoiceChip(
                                key: ValueKey<String>(
                                  'learner_mentor_slot_${slot.id}',
                                ),
                                label: Text(
                                  DateFormat.Hm(
                                    Localizations.localeOf(
                                      context,
                                    ).toLanguageTag(),
                                  ).format(slot.startTime.displayValue),
                                ),
                                selected: _selectedSlotId == slot.id,
                                selectedColor: AppColors.brandTint,
                                backgroundColor:
                                    AppColors.featureBlueBackground,
                                side: BorderSide(
                                  color: _selectedSlotId == slot.id
                                      ? AppColors.brandPrimary
                                      : AppColors.featureBlueBorder,
                                ),
                                labelStyle: TextStyle(
                                  color: _selectedSlotId == slot.id
                                      ? AppColors.brandPrimary
                                      : AppColors.featureBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedSlotId = slot.id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildFinderBottomBar(
    List<LearnerMentorAvailability> slots,
    String? level,
  ) {
    final conflictView = AvailabilityConflictView(slots);
    final selected = conflictView.slots
        .where(
          (slot) =>
              slot.id == _selectedSlotId &&
              conflictView.canBook(slot) &&
              !slot.isBooked &&
              slot.startTime.displayValue.isAfter(DateTime.now()) &&
              slot.endTime.value.difference(slot.startTime.value).inMinutes ==
                  90,
        )
        .firstOrNull;
    final creditState = ref.watch(learnerCreditBalanceControllerProvider);
    final credit = creditState.value;
    final availableTickets = level == null
        ? 0
        : credit?.availableForLevel(level) ?? 0;
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selected != null)
              Text(
                '${selected.mentorName} · ${DateFormat('dd/MM/yyyy HH:mm').format(selected.startTime.displayValue)}–${DateFormat.Hm().format(selected.endTime.displayValue)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall,
              ),
            if (creditState.hasError)
              Text(context.l10n.mentorFinderCreditError),
            if (credit != null && level != null)
              Text(
                availableTickets > 0
                    ? context.l10n.mentorFinderAvailableTickets(
                        availableTickets,
                        level,
                      )
                    : context.l10n.mentorFinderNeedCredit(level),
              ),
            const SizedBox(height: 8),
            RikiPrimaryButton(
              key: const Key('learner_mentor_purchase_button'),
              label: selected == null
                  ? context.l10n.mentorFinderChooseSlot
                  : availableTickets > 0
                  ? context.l10n.mentorFinderReviewBooking
                  : context.l10n.mentorFinderChoosePlan,
              onPressed:
                  selected == null ||
                      level == null ||
                      credit == null ||
                      _checkingSlot
                  ? null
                  : () => availableTickets > 0
                        ? _openConfirmation(selected, null, jlptLevel: level)
                        : _choosePlan(selected, level),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePlan(LearnerMentorAvailability slot, String level) async {
    List<MentorMeetingPlan> plans;
    try {
      plans = (await ref.read(learnerMentorPlansControllerProvider.future))
          .where(
            (plan) => normalizeConsultationJlptLevel(plan.jlptLevel) == level,
          )
          .toList(growable: false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mentorFinderPlansError)),
      );
      return;
    }
    if (!mounted) return;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.mentorFinderNoPlans)));
      ref.invalidate(learnerMentorPlansControllerProvider);
      return;
    }
    final plan = await showModalBottomSheet<MentorMeetingPlan>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(context.l10n.mentorFinderChoosePlan)),
            for (final item in plans)
              ListTile(
                title: Text(item.name),
                subtitle: Text(
                  context.l10n.mentorFinderPlanSummary(
                    item.meetingSessionCount,
                    item.durationDays,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(item),
              ),
          ],
        ),
      ),
    );
    if (plan != null && mounted) {
      await _openConfirmation(slot, plan, jlptLevel: level);
    }
  }

  Widget _buildContent(List<LearnerMentorAvailability> allSlots) {
    final conflictView = AvailabilityConflictView(allSlots);
    final availableSlots = conflictView.displaySlots
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

    // Giữ ngày người học chọn từ Lịch học, kể cả khi ngày đó hết chỗ.
    final activeDate = _selectedDate ?? dates.firstOrNull;

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
        'Cố vấn RikiPath';

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
                          '90 phút/buổi',
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
                'Cố vấn này chưa có khung giờ trống trong ngày đã chọn. Vui lòng chọn ngày khác trên lịch.',
          )
        else
          ..._buildTimeSlotGroups(visibleSlots, conflictView.conflictingIds),

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

  List<Widget> _buildTimeSlotGroups(
    List<LearnerMentorAvailability> slots,
    Set<int> conflictingIds,
  ) {
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
        final conflicting = conflictingIds.contains(slot.id);
        final isSelected = _selectedSlotId == slot.id;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LearnerMentorAvailabilityCard(
                  key: ValueKey<String>('learner_mentor_slot_${slot.id}'),
                  slot: slot,
                  selected: isSelected && !conflicting,
                  onTap: conflicting
                      ? null
                      : () => setState(() => _selectedSlotId = slot.id),
                ),
                if (conflicting)
                  const Text('Lịch trùng hoặc chồng lấn; hiện chưa thể đặt.'),
              ],
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

  Future<void> _openConfirmation(
    LearnerMentorAvailability slot,
    MentorMeetingPlan? plan, {
    String? jlptLevel,
  }) async {
    setState(() => _checkingSlot = true);
    try {
      final selectedDay = slot.startTime.displayValue;
      final from = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      final to = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day + 1,
      );
      final fresh = await ref
          .read(learnerMentorRepositoryProvider)
          .loadAvailability(
            from: from.toUtc(),
            to: to.toUtc(),
            mentorId: widget.mentorId ?? slot.mentorId,
            jlptLevel: jlptLevel ?? plan?.jlptLevel,
          );
      if (!mounted) return;
      final view = AvailabilityConflictView(fresh);
      final current = view.slots
          .where((item) => item.id == slot.id)
          .firstOrNull;
      if (current == null ||
          !view.canBook(current) ||
          current.startTime.value != slot.startTime.value ||
          current.endTime.value != slot.endTime.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lịch đã thay đổi hoặc bị trùng. Vui lòng chọn lại.'),
          ),
        );
        setState(() => _selectedSlotId = null);
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kiểm tra lịch mới nhất. Vui lòng thử lại.'),
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _checkingSlot = false);
    }
    if (!mounted) return;
    final effectivePlanId = widget.planId ?? plan?.id;
    final booking = await LearnerMentorOrderConfirmationSheet.show(
      context,
      planId: effectivePlanId,
      slot: slot,
      plan: plan,
      subscriptionId: widget.subscriptionId,
      requestedJlptLevel: jlptLevel,
    );
    if (!mounted) return;
    ref.invalidate(
      learnerMentorSlotsForDayProvider((
        day: _selectedDate ?? DateUtils.dateOnly(DateTime.now()),
        mentorId: widget.mentorId,
        jlptLevel: jlptLevel ?? _selectedJlptLevel,
      )),
    );
    ref.invalidate(learnerMentorBookingsControllerProvider);
    ref.invalidate(learnerCreditBalanceControllerProvider);
    if (booking != null) {
      final selectedDay =
          _selectedDate ?? DateUtils.dateOnly(slot.startTime.displayValue);
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.learnerMentorBookingSuccess,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  '${booking.mentorName ?? slot.mentorName} · '
                  '${DateFormat('dd/MM/yyyy HH:mm').format(slot.startTime.displayValue)}–'
                  '${DateFormat.Hm().format(slot.endTime.displayValue)}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  learnerMentorBookingStatusLabel(booking.status, context),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        booking.status == MentorMeetingStatus.accepted ||
                            booking.status == MentorMeetingStatus.assigned
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                RikiPrimaryButton(
                  label: context.l10n.mentorFinderViewMyBookings,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.learnerMentorBookings);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(AppRoutes.calendarOn(selectedDay));
                  },
                  child: Text(context.l10n.mentorFinderBackToCalendar),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

enum _SlotTimeFilter {
  all,
  morning,
  afternoon,
  evening;

  String label(BuildContext context) => switch (this) {
    _SlotTimeFilter.all => context.l10n.mentorFinderTimeAll,
    _SlotTimeFilter.morning => context.l10n.mentorFinderTimeMorning,
    _SlotTimeFilter.afternoon => context.l10n.mentorFinderTimeAfternoon,
    _SlotTimeFilter.evening => context.l10n.mentorFinderTimeEvening,
  };

  bool includes(int hour) => switch (this) {
    _SlotTimeFilter.all => true,
    _SlotTimeFilter.morning => hour < 12,
    _SlotTimeFilter.afternoon => hour >= 12 && hour < 18,
    _SlotTimeFilter.evening => hour >= 18,
  };
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
