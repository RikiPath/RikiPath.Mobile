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
    this.onBackPressed,
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
  final VoidCallback? onBackPressed;

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
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
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
              // 1. Left Back Button (38x38 rounded container)
              InkWell(
                key: const Key('calendar_back_button'),
                onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space2),

              // 2. Month & Year Title with dropdown arrow + Today quick-jump
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: 'Chọn tháng và năm',
                        child: InkWell(
                          key: const Key('calendar_month_picker_button'),
                          onTap: () => _pickMonthYear(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
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
                                      fontSize: 16.5,
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
                    const SizedBox(width: 2),
                    // Quick Jump to Today Button
                    IconButton(
                      key: const Key('calendar_today_button'),
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: isTodaySelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          Positioned(
                            top: 5,
                            child: Text(
                              '${today.day}',
                              style: TextStyle(
                                fontSize: 7.5,
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.space2),

              // 3. View Mode Selector Dropdown Pill
              PopupMenuButton<SakuraCalendarViewMode>(
                key: const Key('calendar_view_mode_menu'),
                initialValue: currentViewMode,
                tooltip: 'Chọn chế độ xem',
                onSelected: onSelectViewMode,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
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

              const SizedBox(width: AppSpacing.space2),

              // 4. Hamburger Menu Button (Right side, opens endDrawer)
              InkWell(
                key: const Key('calendar_menu_button'),
                onTap: onToggleDrawer,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (onPrevious != null && onNext != null)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('calendar_previous_button'),
                    tooltip: 'Khoảng thời gian trước',
                    onPressed: onPrevious,
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  Flexible(
                    child: Text(
                      currentViewMode == SakuraCalendarViewMode.year
                          ? 'Tổng quan 12 tháng'
                          : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onSearchPressed != null)
                        IconButton(
                          key: const Key('calendar_search_button'),
                          tooltip: 'Tìm sự kiện',
                          onPressed: onSearchPressed,
                          icon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      IconButton(
                        key: const Key('calendar_next_button'),
                        tooltip: 'Khoảng thời gian sau',
                        onPressed: onNext,
                        icon: const Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
