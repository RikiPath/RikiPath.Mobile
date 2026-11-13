import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';

class SakuraMonthView extends StatefulWidget {
  const SakuraMonthView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onSelectDate,
    required this.onSelectEvent,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  final DateTime selectedDate;
  final List<SakuraCalendarEvent> events;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<SakuraCalendarEvent> onSelectEvent;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  @override
  State<SakuraMonthView> createState() => _SakuraMonthViewState();
}

class _SakuraMonthViewState extends State<SakuraMonthView> {
  static const _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  List<DateTime> _buildMonthDays(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    final int leadingDays = firstDayOfMonth.weekday - 1;

    final days = <DateTime>[];

    for (int i = leadingDays; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }

    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(firstDayOfMonth.add(Duration(days: i)));
    }

    final totalCells = (days.length <= 35) ? 35 : 42;
    final int trailingDays = totalCells - days.length;
    for (int i = 1; i <= trailingDays; i++) {
      days.add(lastDayOfMonth.add(Duration(days: i)));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<SakuraCalendarEvent> _eventsForDay(DateTime day) {
    return widget.events.where((e) => e.isSameDay(day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildMonthDays(widget.selectedDate);
    final today = DateTime.now();
    final selectedDayEvents = _eventsForDay(widget.selectedDate);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            widget.onNextMonth?.call();
          } else if (details.primaryVelocity! > 200) {
            widget.onPreviousMonth?.call();
          }
        }
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // Weekday Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: _weekDays.map((label) {
                final isWeekend = label == 'CN' || label == 'T7';
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isWeekend
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 7-Column Grid
          Container(
            color: Colors.white,
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height:
                    (days.length ~/ 7) *
                    (constraints.maxWidth / 7).clamp(46.0, 64.0),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: (constraints.maxWidth / 7).clamp(46.0, 64.0),
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth = day.month == widget.selectedDate.month;
                    final isToday = _isSameDay(day, today);
                    final isSelected = _isSameDay(day, widget.selectedDate);
                    final dayEvents = _eventsForDay(day);

                    return _MonthDayCell(
                      day: day,
                      isCurrentMonth: isCurrentMonth,
                      isToday: isToday,
                      isSelected: isSelected,
                      events: dayEvents,
                      onTap: () => widget.onSelectDate(day),
                    );
                  },
                ),
              ),
            ),
          ),

          // Selected Day Event Preview Section
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space2,
              AppSpacing.space4,
              AppSpacing.space4,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle at top center
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '${widget.selectedDate.day} tháng ${widget.selectedDate.month} — ${selectedDayEvents.length} sự kiện',
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                if (selectedDayEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Chưa có hoạt động nào trong ngày này.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  for (final event in selectedDayEvents) ...[
                    const SizedBox(height: AppSpacing.space2),
                    _MonthDayPreviewCard(
                      event: event,
                      onTap: () => widget.onSelectEvent(event),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<SakuraCalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = !isCurrentMonth
        ? AppColors.textTertiary
        : isToday
        ? Colors.white
        : isSelected
        ? AppColors.primary
        : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.35),
            width: 0.4,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day Number badge (Solid pink circle if today, rounded rect border if selected, plain text otherwise)
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary
                      : (isSelected
                          ? const Color(0xFFFFF1F2)
                          : Colors.transparent),
                  borderRadius: isToday ? null : BorderRadius.circular(7),
                  shape: isToday ? BoxShape.circle : BoxShape.rectangle,
                  border: isSelected && !isToday
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: (isToday || isSelected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),

              // Activity dots
              if (events.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final type
                        in events.map((e) => e.type).toSet().take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: events
                                .firstWhere((e) => e.type == type)
                                .primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthDayPreviewCard extends StatelessWidget {
  const _MonthDayPreviewCard({required this.event, required this.onTap});

  final SakuraCalendarEvent event;
  final VoidCallback onTap;

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: event.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: event.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: event.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Icon(event.type.icon, size: 20, color: event.primaryColor),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.isAllDay
                          ? 'Trong ngày · ${event.type.labelVi}'
                          : '${_formatTime(event.startTime)} – ${_formatTime(event.endTime)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (event.statusLabel != null) ...[
                const SizedBox(width: AppSpacing.space2),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: event.statusBadgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: event.statusBadgeBorderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.statusBadgeIcon != null) ...[
                            Icon(
                              event.statusBadgeIcon,
                              size: 11,
                              color: event.statusBadgeTextColor,
                            ),
                            const SizedBox(width: 3.5),
                          ],
                          Text(
                            event.statusLabel!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: event.statusBadgeTextColor,
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
      ),
    );
  }
}
