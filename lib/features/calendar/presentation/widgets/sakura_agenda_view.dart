import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_empty_state.dart';

class SakuraAgendaView extends StatelessWidget {
  const SakuraAgendaView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onSelectEvent,
    this.onAddEventAction,
  });

  final DateTime selectedDate;
  final List<SakuraCalendarEvent> events;
  final ValueChanged<SakuraCalendarEvent> onSelectEvent;
  final VoidCallback? onAddEventAction;

  String _formatWeekday(DateTime dt) {
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return weekdays[dt.weekday - 1];
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return SakuraCalendarEmptyState(
        title: 'Chưa có lịch hẹn nào',
        message: 'Bạn chưa có buổi tư vấn hoặc khung giờ học nào được lên lịch.',
        actionLabel: onAddEventAction != null ? 'Đặt lịch ngay' : null,
        onAction: onAddEventAction,
      );
    }

    final today = DateTime.now();

    // Group events by date (ignoring time)
    final groupedEvents = <DateTime, List<SakuraCalendarEvent>>{};
    for (final ev in events) {
      final dateKey = DateTime(ev.startTime.year, ev.startTime.month, ev.startTime.day);
      groupedEvents.putIfAbsent(dateKey, () => []).add(ev);
    }

    final sortedDates = groupedEvents.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEvents = groupedEvents[date]!;
        final isToday = _isSameDay(date, today);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge Column (Google Calendar style)
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(
                      _formatWeekday(date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday
                            ? null
                            : Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.space2),

              // Events list for this day
              Expanded(
                child: Column(
                  children: dayEvents.map((ev) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: Material(
                        color: ev.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => onSelectEvent(ev),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.space3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: ev.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: ev.primaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.space2),
                                    Expanded(
                                      child: Text(
                                        ev.title,
                                        style: AppTypography.cardTitle.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (ev.statusLabel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.space2,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: ev.borderColor,
                                          ),
                                        ),
                                        child: Text(
                                          ev.statusLabel!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: ev.primaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.space2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${_formatTime(ev.startTime)} – ${_formatTime(ev.endTime)} (${ev.durationMinutes} phút)',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (ev.jlptLevel != null) ...[
                                      const SizedBox(width: 6),
                                      JlptBadge(JlptLevel.tryParse(ev.jlptLevel?.replaceAll('JLPT ', '') ?? 'N3') ?? JlptLevel.n3),
                                    ],
                                  ],
                                ),
                                if (ev.participantName != null) ...[
                                  const SizedBox(height: AppSpacing.space1),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${ev.participantRole ?? "Người tham gia"}: ${ev.participantName}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
