import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';

/// Twelve-month overview built only from events already loaded for this user.
class SakuraYearView extends StatelessWidget {
  const SakuraYearView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onSelectMonth,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final List<SakuraCalendarEvent> events;
  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final eventsByDay = <DateTime, List<SakuraCalendarEvent>>{};
    for (final event in events) {
      if (event.startTime.year != selectedDate.year) continue;
      final date = DateUtils.dateOnly(event.startTime);
      eventsByDay.putIfAbsent(date, () => []).add(event);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - 24 - (columns - 1) * 10) / columns;
        final tileHeight = (tileWidth - 16) / 7 / 0.95 * 6 + 66;
        return GridView.builder(
          key: const Key('calendar_year_grid'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: tileHeight.clamp(224, 360),
          ),
          itemCount: 12,
          itemBuilder: (context, index) => _YearMonth(
            year: selectedDate.year,
            month: index + 1,
            selectedDate: selectedDate,
            eventsByDay: eventsByDay,
            onSelectMonth: onSelectMonth,
            onSelectDate: onSelectDate,
          ),
        );
      },
    );
  }
}

class _YearMonth extends StatelessWidget {
  const _YearMonth({
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.eventsByDay,
    required this.onSelectMonth,
    required this.onSelectDate,
  });

  final int year;
  final int month;
  final DateTime selectedDate;
  final Map<DateTime, List<SakuraCalendarEvent>> eventsByDay;
  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = first.weekday - 1;
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(selectedDate);
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              InkWell(
                key: Key('year_month_$month'),
                onTap: () => onSelectMonth(DateTime(year, month, 1)),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tháng $month',
                          style: TextStyle(
                            color: selectedDate.month == month
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final weekday in weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekday,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: (weekday == 'CN' || weekday == 'T7')
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: (weekday == 'CN' || weekday == 'T7')
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: leading + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leading) return const SizedBox.shrink();
                    final day = DateTime(year, month, index - leading + 1);
                    final dayEvents =
                        eventsByDay[day] ?? const <SakuraCalendarEvent>[];
                    final isToday = day == today;
                    final isSelected = day == selected;
                    return Semantics(
                      button: true,
                      label:
                          '${day.day} tháng $month năm $year, ${dayEvents.length} sự kiện',
                      child: InkWell(
                        key: Key('year_day_${month}_${day.day}'),
                        onTap: () => onSelectDate(day),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 21,
                              height: 21,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? AppColors.primary
                                    : (isSelected
                                        ? const Color(0xFFFFF1F2)
                                        : null),
                                border: isSelected && !isToday
                                    ? Border.all(color: AppColors.primary, width: 1.2)
                                    : null,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday
                                      ? Colors.white
                                      : (isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary),
                                ),
                              ),
                            ),
                            if (dayEvents.isNotEmpty)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dayEvents.first.primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
