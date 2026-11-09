import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';

class SakuraCalendarHeader extends StatelessWidget {
  const SakuraCalendarHeader({
    super.key,
    required this.selectedDate,
    required this.currentViewMode,
    required this.onToggleDrawer,
    required this.onSelectDate,
    required this.onSelectViewMode,
    required this.onTodayPressed,
    this.onPrevious,
    this.onNext,
    this.onSearchPressed,
  });

  final DateTime selectedDate;
  final SakuraCalendarViewMode currentViewMode;
  final VoidCallback onToggleDrawer;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<SakuraCalendarViewMode> onSelectViewMode;
  final VoidCallback onTodayPressed;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSearchPressed;

  String _formatMonthYear(DateTime dt) {
    return currentViewMode == SakuraCalendarViewMode.year
        ? 'Năm ${dt.year}'
        : 'Tháng ${dt.month}, ${dt.year}';
  }

  Future<void> _pickMonthYear(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      initialDatePickerMode: currentViewMode == SakuraCalendarViewMode.year
          ? DatePickerMode.year
          : DatePickerMode.day,
      helpText: 'CHỌN NGÀY, THÁNG VÀ NĂM',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isTodaySelected =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Hamburger Menu Button
              IconButton(
                key: const Key('calendar_menu_button'),
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                tooltip: 'Mở danh mục lịch',
                onPressed: onToggleDrawer,
                padding: const EdgeInsets.all(AppSpacing.space2),
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: AppSpacing.space1),

              // 2. Month & Year Title with dropdown arrow
              Flexible(
                child: Tooltip(
                  message: 'Chọn tháng và năm',
                  child: InkWell(
                    key: const Key('calendar_month_picker_button'),
                    onTap: () => _pickMonthYear(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space1,
                        vertical: AppSpacing.space1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _formatMonthYear(selectedDate),
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space1),

              // 3. Jump to Today shortcut button
              IconButton(
                key: const Key('calendar_today_button'),
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: isTodaySelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    Positioned(
                      top: 6,
                      child: Text(
                        '${today.day}',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isTodaySelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: 'Về ngày hôm nay',
                onPressed: onTodayPressed,
                padding: const EdgeInsets.all(AppSpacing.space2),
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: AppSpacing.space2),

              // 4. View Mode Selector Dropdown / Pill
              PopupMenuButton<SakuraCalendarViewMode>(
                key: const Key('calendar_view_mode_menu'),
                initialValue: currentViewMode,
                tooltip: 'Chọn chế độ xem',
                onSelected: onSelectViewMode,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentViewMode.icon,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentViewMode.labelVi,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) {
                  return SakuraCalendarViewMode.values.map((mode) {
                    final isSelected = mode == currentViewMode;
                    return PopupMenuItem<SakuraCalendarViewMode>(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(
                            mode.icon,
                            size: 20,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Text(
                            mode.labelVi,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          if (onPrevious != null && onNext != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  key: const Key('calendar_previous_button'),
                  tooltip: 'Khoảng thời gian trước',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  currentViewMode == SakuraCalendarViewMode.year
                      ? 'Tổng quan 12 tháng'
                      : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: AppTypography.caption,
                ),
                if (onSearchPressed != null)
                  IconButton(
                    key: const Key('calendar_search_button'),
                    tooltip: 'Tìm sự kiện',
                    onPressed: onSearchPressed,
                    icon: const Icon(Icons.search, size: 20),
                  ),
                IconButton(
                  key: const Key('calendar_next_button'),
                  tooltip: 'Khoảng thời gian sau',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
