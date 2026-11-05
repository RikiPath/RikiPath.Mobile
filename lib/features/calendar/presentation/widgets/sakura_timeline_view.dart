import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';

class SakuraTimelineView extends StatefulWidget {
  const SakuraTimelineView({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    required this.events,
    required this.onSelectDate,
    required this.onSelectEvent,
    this.onPrevious,
    this.onNext,
    this.startHour = 0,
    this.endHour = 24,
    this.hourHeight = 64.0,
  });

  final DateTime selectedDate;
  final SakuraCalendarViewMode viewMode;
  final List<SakuraCalendarEvent> events;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<SakuraCalendarEvent> onSelectEvent;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int startHour;
  final int endHour;
  final double hourHeight;

  @override
  State<SakuraTimelineView> createState() => _SakuraTimelineViewState();
}

class _SakuraTimelineViewState extends State<SakuraTimelineView> {
  late final ScrollController _scrollController;

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    // Scroll to current hour or 8:00 AM initially
    final now = DateTime.now();
    final targetHour = (now.hour >= widget.startHour && now.hour <= widget.endHour)
        ? (now.hour - 1)
        : 8;
    final initialOffset = (targetHour - widget.startHour) * widget.hourHeight;
    _scrollController = ScrollController(
      initialScrollOffset: initialOffset > 0 ? initialOffset : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _calculateVisibleDays() {
    final sel = widget.selectedDate;
    switch (widget.viewMode) {
      case SakuraCalendarViewMode.day:
        return [DateTime(sel.year, sel.month, sel.day)];
      case SakuraCalendarViewMode.threeDay:
        // Center around selected date or start from selected date
        return [
          DateTime(sel.year, sel.month, sel.day),
          DateTime(sel.year, sel.month, sel.day + 1),
          DateTime(sel.year, sel.month, sel.day + 2),
        ];
      case SakuraCalendarViewMode.week:
        // Week starts on Monday
        final monday = sel.subtract(Duration(days: sel.weekday - 1));
        return List.generate(
          7,
          (i) => DateTime(monday.year, monday.month, monday.day + i),
        );
      default:
        return [DateTime(sel.year, sel.month, sel.day)];
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = _calculateVisibleDays();
    final today = DateTime.now();
    final totalHours = widget.endHour - widget.startHour;
    final contentHeight = totalHours * widget.hourHeight;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            widget.onNext?.call();
          } else if (details.primaryVelocity! > 200) {
            widget.onPrevious?.call();
          }
        }
      },
      child: Column(
        children: [
          // Top Header Row with Days
          Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Left margin placeholder for hour labels
                const SizedBox(width: 48),

                // Day columns header
                for (final day in visibleDays) ...[
                  Expanded(
                    child: _TimelineHeaderCell(
                      day: day,
                      weekdayLabel: _weekdayLabels[day.weekday - 1],
                      isToday: _isSameDay(day, today),
                      isSelected: _isSameDay(day, widget.selectedDate),
                      onTap: () => widget.onSelectDate(day),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Scrollable Time Grid
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: contentHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hour labels column
                    SizedBox(
                      width: 48,
                      child: Stack(
                        children: [
                          for (int i = 0; i < totalHours; i++) ...[
                            Positioned(
                              top: i * widget.hourHeight - 8,
                              left: 6,
                              right: 6,
                              child: Text(
                                '${(widget.startHour + i).toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Grid Columns for each visible day
                    for (int dayIndex = 0;
                        dayIndex < visibleDays.length;
                        dayIndex++) ...[
                      Expanded(
                        child: _DayTimelineColumn(
                          day: visibleDays[dayIndex],
                          isToday: _isSameDay(visibleDays[dayIndex], today),
                          startHour: widget.startHour,
                          endHour: widget.endHour,
                          hourHeight: widget.hourHeight,
                          events: widget.events
                              .where((e) => e.isSameDay(visibleDays[dayIndex]))
                              .toList(),
                          onSelectEvent: widget.onSelectEvent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineHeaderCell extends StatelessWidget {
  const _TimelineHeaderCell({
    required this.day,
    required this.weekdayLabel,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final String weekdayLabel;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              weekdayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isToday
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary
                    : isSelected
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? Colors.white
                      : isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTimelineColumn extends StatelessWidget {
  const _DayTimelineColumn({
    required this.day,
    required this.isToday,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.events,
    required this.onSelectEvent,
  });

  final DateTime day;
  final bool isToday;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final List<SakuraCalendarEvent> events;
  final ValueChanged<SakuraCalendarEvent> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    final totalHours = endHour - startHour;
    final now = DateTime.now();

    // Group overlapping events into side-by-side columns
    final positionedEvents = _layoutOverlappingEvents(events);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth;

          return Stack(
            children: [
              // Horizontal hour grid lines
              for (int i = 0; i < totalHours; i++) ...[
                Positioned(
                  top: i * hourHeight,
                  left: 0,
                  right: 0,
                  child: const Divider(
                    height: 1,
                    color: Color(0xFFECE7E2),
                  ),
                ),
              ],

              // Current-Time indicator line (if today)
              if (isToday && now.hour >= startHour && now.hour < endHour) ...[
                Positioned(
                  top: ((now.hour - startHour) + (now.minute / 60)) * hourHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Positioned Event Cards
              for (final pe in positionedEvents) ...[
                _buildEventCard(pe, columnWidth),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(_PositionedEvent pe, double totalWidth) {
    final ev = pe.event;
    final startMins = (ev.startTime.hour - startHour) * 60 + ev.startTime.minute;
    final durationMins = ev.durationMinutes;

    final top = (startMins / 60.0) * hourHeight;
    final height = (durationMins / 60.0) * hourHeight;

    // Calculate horizontal column placement
    final cardWidth = (totalWidth - 4) / pe.totalColumns;
    final left = pe.columnIndex * cardWidth + 2;

    return Positioned(
      top: top,
      left: left,
      width: cardWidth - 2,
      height: height > 24 ? height : 24,
      child: Material(
        color: ev.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onSelectEvent(ev),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ev.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: ev.primaryColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: ClipRect(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ev.title,
                          maxLines: height > 45 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ev.primaryColor,
                          ),
                        ),
                        if (height > 35) ...[
                          Text(
                            ': (p)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_PositionedEvent> _layoutOverlappingEvents(
    List<SakuraCalendarEvent> rawEvents,
  ) {
    if (rawEvents.isEmpty) return [];

    // Sort by start time, then by duration descending
    final sorted = List<SakuraCalendarEvent>.from(rawEvents)
      ..sort((a, b) {
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return b.duration.compareTo(a.duration);
      });

    // Detect collision clusters
    final clusters = <List<SakuraCalendarEvent>>[];
    List<SakuraCalendarEvent> currentCluster = [];
    DateTime? clusterEnd;

    for (final ev in sorted) {
      if (clusterEnd == null || ev.startTime.isBefore(clusterEnd)) {
        currentCluster.add(ev);
        if (clusterEnd == null || ev.endTime.isAfter(clusterEnd)) {
          clusterEnd = ev.endTime;
        }
      } else {
        clusters.add(currentCluster);
        currentCluster = [ev];
        clusterEnd = ev.endTime;
      }
    }
    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    final results = <_PositionedEvent>[];

    for (final cluster in clusters) {
      final columns = <List<SakuraCalendarEvent>>[];

      for (final ev in cluster) {
        int placedCol = -1;
        for (int c = 0; c < columns.length; c++) {
          final lastInCol = columns[c].last;
          if (!ev.startTime.isBefore(lastInCol.endTime)) {
            columns[c].add(ev);
            placedCol = c;
            break;
          }
        }
        if (placedCol == -1) {
          columns.add([ev]);
          placedCol = columns.length - 1;
        }
      }

      final numCols = columns.length;
      for (int c = 0; c < numCols; c++) {
        for (final ev in columns[c]) {
          results.add(
            _PositionedEvent(
              event: ev,
              columnIndex: c,
              totalColumns: numCols,
            ),
          );
        }
      }
    }

    return results;
  }
}

class _PositionedEvent {
  const _PositionedEvent({
    required this.event,
    required this.columnIndex,
    required this.totalColumns,
  });

  final SakuraCalendarEvent event;
  final int columnIndex;
  final int totalColumns;
}
