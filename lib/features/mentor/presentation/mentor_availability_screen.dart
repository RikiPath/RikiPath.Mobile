import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorAvailabilityScreen extends ConsumerWidget {
  const MentorAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorAvailabilityControllerProvider);
    return Scaffold(
      key: const Key('mentor_availability_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.mentorAvailabilityTitle),
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
            key: Key('mentor_availability_loading'),
          ),
          AsyncError() => _RefreshableAvailabilityBody(
            key: const Key('mentor_availability_error'),
            onRefresh: ref
                .read(mentorAvailabilityControllerProvider.notifier)
                .retry,
            child: MentorErrorState(
              message: context.l10n.mentorAvailabilityError,
              onRetry: ref
                  .read(mentorAvailabilityControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _AvailabilityList(
            slots: value,
            onRefresh: () async {
              await ref
                  .read(mentorAvailabilityControllerProvider.notifier)
                  .retry();
              await ref
                  .read(mentorWeeklyScheduleControllerProvider.notifier)
                  .loadSchedule();
            },
          ),
        },
      ),
    );
  }
}

class _AvailabilityList extends ConsumerWidget {
  const _AvailabilityList({required this.slots, required this.onRefresh});

  final List<MentorAvailabilitySlot> slots;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyState = ref.watch(mentorWeeklyScheduleControllerProvider);
    final weeklyNotifier = ref.read(
      mentorWeeklyScheduleControllerProvider.notifier,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('mentor_availability_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          MentorPageHeader(
            title: context.l10n.mentorAvailabilityTitle,
            subtitle: context.l10n.mentorAvailabilityDescription,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 1. Published 50-minute slots Section
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              const Expanded(
                child: Text(
                  'Lịch đã công bố',
                  style: AppTypography.sectionTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${slots.length} tiết',
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          const Text(
            'Các tiết học Admin đã xếp từ các buổi rảnh và công bố cho học viên đặt.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space3),

          if (slots.isEmpty)
            MentorEmptyState(
              key: const Key('mentor_availability_empty'),
              icon: Icons.event_available_outlined,
              title: context.l10n.mentorAvailabilityTitle,
              description: context.l10n.mentorAvailabilityEmpty,
            )
          else
            for (var index = 0; index < slots.length; index++) ...[
              MentorAvailabilityCard(
                key: ValueKey<String>('mentor_availability_$index'),
                slot: slots[index],
              ),
              if (index < slots.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],

          const SizedBox(height: AppSpacing.space6),

          // 2. Weekly Schedule Registration Box
          _WeeklyScheduleCard(state: weeklyState, notifier: weeklyNotifier),
        ],
      ),
    );
  }
}

class _WeeklyScheduleCard extends StatelessWidget {
  const _WeeklyScheduleCard({required this.state, required this.notifier});

  final MentorWeeklyScheduleState state;
  final MentorWeeklyScheduleController notifier;

  @override
  Widget build(BuildContext context) {
    final start = state.selectedWeekMonday;
    final end = start.add(const Duration(days: 6));
    final dateFormat = DateFormat('dd/MM');
    final weekRangeText =
        '${dateFormat.format(start)} – ${dateFormat.format(end)}';

    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const dayFullNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];

    final periodCount = state.registeredPeriods.length;

    return RikiCard(
      borderColor: AppColors.brandPrimary.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Switcher Header
          Row(
            children: [
              IconButton(
                key: const Key('mentor_prev_week_button'),
                icon: const Icon(Icons.chevron_left),
                onPressed: state.isSaving ? null : notifier.previousWeek,
                tooltip: 'Tuần trước',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Tuần: $weekRangeText',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    if (state.isNextWeek)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: state.isRegistrationOpen
                              ? AppColors.brandPrimary.withValues(alpha: 0.12)
                              : AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          state.isRegistrationOpen
                              ? '🌸 Tuần sau — Mở đăng ký'
                              : '⚠️ Đã hết hạn đăng ký tuần sau',
                          style: AppTypography.metadata.copyWith(
                            color: state.isRegistrationOpen
                                ? AppColors.brandPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (state.isCurrentWeek)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tuần hiện tại (Lịch cố định)',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('mentor_next_week_button'),
                icon: const Icon(Icons.chevron_right),
                onPressed: state.isSaving ? null : notifier.nextWeek,
                tooltip: 'Tuần sau',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Registration Rule Note
          if (state.isNextWeek && state.isRegistrationOpen)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9FA),
                borderRadius: BorderRadius.circular(AppRadius.compact),
                border: Border.all(color: const Color(0xFFFFD5E0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      'Hạn chót đăng ký: Trước 18:00 Thứ Sáu (Giờ VN). Tối thiểu 3 buổi rảnh mỗi tuần.',
                      style: AppTypography.metadata.copyWith(
                        color: const Color(0xFF8B2346),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.space4),

          // 7-day shift grid
          for (var i = 0; i < 7; i++) ...[
            _DayShiftRow(
              dayName: dayNames[i],
              fullDayName: dayFullNames[i],
              date: days[i],
              state: state,
              onTogglePeriod: (p) => notifier.togglePeriod(days[i], p),
            ),
            if (i < 6) const SizedBox(height: AppSpacing.space2),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Counter & Validation Info
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.compact),
            ),
            child: Row(
              children: [
                Icon(
                  periodCount >= 3
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 20,
                  color: periodCount >= 3
                      ? const Color(0xFF2E7D32)
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    'Đã chọn: $periodCount buổi rảnh (Tối thiểu 3 buổi/tuần)',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: periodCount >= 3
                          ? AppColors.textPrimary
                          : AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(AppRadius.compact),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: AppTypography.metadata.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (state.successMessage != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(AppRadius.compact),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: AppTypography.metadata.copyWith(
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: RikiPrimaryButton(
              key: const Key('mentor_save_schedule_button'),
              label: state.isSaving
                  ? 'Đang lưu đăng ký...'
                  : 'Lưu đăng ký lịch dạy',
              onPressed:
                  (!state.isRegistrationOpen ||
                      periodCount < 3 ||
                      state.isSaving)
                  ? null
                  : () async {
                      final ok = await notifier.saveSchedule();
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã lưu đăng ký lịch dạy thành công! Chờ Admin xếp tiết.',
                            ),
                            backgroundColor: Color(0xFF2E7D32),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayShiftRow extends StatelessWidget {
  const _DayShiftRow({
    required this.dayName,
    required this.fullDayName,
    required this.date,
    required this.state,
    required this.onTogglePeriod,
  });

  final String dayName;
  final String fullDayName;
  final DateTime date;
  final MentorWeeklyScheduleState state;
  final void Function(String period) onTogglePeriod;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isMorning = state.registeredPeriods.any(
      (p) => p.key == '$dateStr#Morning',
    );
    final isAfternoon = state.registeredPeriods.any(
      (p) => p.key == '$dateStr#Afternoon',
    );
    final isEvening = state.registeredPeriods.any(
      (p) => p.key == '$dateStr#Evening',
    );

    final canToggle = state.isRegistrationOpen && !state.isSaving;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.compact),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$fullDayName, ${DateFormat('dd/MM').format(date)}',
                style: AppTypography.metadata.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                dayName,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ShiftChip(
                  label: 'Sáng (8-12h)',
                  isSelected: isMorning,
                  onTap: canToggle ? () => onTogglePeriod('Morning') : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ShiftChip(
                  label: 'Chiều (13-17h)',
                  isSelected: isAfternoon,
                  onTap: canToggle ? () => onTogglePeriod('Afternoon') : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ShiftChip(
                  label: 'Tối (18-22h)',
                  isSelected: isEvening,
                  onTap: canToggle ? () => onTogglePeriod('Evening') : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimary.withValues(alpha: 0.12)
                : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.brandPrimary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.metadata.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshableAvailabilityBody extends StatelessWidget {
  const _RefreshableAvailabilityBody({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}
