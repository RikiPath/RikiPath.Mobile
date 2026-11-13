import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/features/calendar/application/sakura_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_agenda_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_drawer.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_header.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_event_detail_sheet.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_month_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_timeline_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_year_view.dart';

class SakuraCalendarShell extends ConsumerStatefulWidget {
  const SakuraCalendarShell({
    super.key,
    required this.events,
    required this.roleName,
    this.isMentor = false,
    this.fabLabel,
    this.fabIcon = Icons.add,
    this.onFabPressed,
    this.onEventSelected,
    this.initialMode = SakuraCalendarViewMode.month,
    this.initialDate,
  });

  final List<SakuraCalendarEvent> events;
  final String roleName;
  final bool isMentor;
  final String? fabLabel;
  final IconData fabIcon;
  final VoidCallback? onFabPressed;
  final ValueChanged<SakuraCalendarEvent>? onEventSelected;
  final SakuraCalendarViewMode initialMode;
  final DateTime? initialDate;

  @override
  ConsumerState<SakuraCalendarShell> createState() =>
      _SakuraCalendarShellState();
}

class _SakuraCalendarShellState extends ConsumerState<SakuraCalendarShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(sakuraCalendarControllerProvider.notifier)
          .setViewMode(widget.initialMode);
      if (widget.initialDate != null) {
        ref
            .read(sakuraCalendarControllerProvider.notifier)
            .setSelectedDate(widget.initialDate!);
      }
    });
  }

  void _onEventSelected(SakuraCalendarEvent event) {
    if (widget.onEventSelected != null) {
      widget.onEventSelected!(event);
    } else {
      SakuraEventDetailSheet.show(context, event: event);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(sakuraCalendarControllerProvider);
    final controller = ref.read(sakuraCalendarControllerProvider.notifier);

    // Filter events by selected visible layers
    final query = _searchController.text.trim().toLowerCase();
    final filteredEvents = widget.events
        .where((e) => calendarState.visibleEventTypes.contains(e.type))
        .where((e) {
          if (query.isEmpty) return true;
          final searchable = [
            e.title,
            e.subtitle ?? '',
            e.type.labelVi,
            e.participantName ?? '',
            e.jlptLevel ?? '',
            '${e.startTime.day}/${e.startTime.month}/${e.startTime.year}',
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList();
    final upcoming =
        filteredEvents
            .where(
              (e) =>
                  e.startTime.isAfter(DateTime.now()) &&
                  e.status?.name != 'cancelled' &&
                  e.status?.name != 'completed',
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: SakuraCalendarDrawer(
        currentMode: calendarState.viewMode,
        visibleEventTypes: calendarState.visibleEventTypes,
        roleName: widget.roleName,
        isMentor: widget.isMentor,
        onSelectMode: (mode) => controller.setViewMode(mode),
        onToggleEventType: (type) => controller.toggleEventType(type),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Header Toolbar
            SakuraCalendarHeader(
              selectedDate: calendarState.selectedDate,
              currentViewMode: calendarState.viewMode,
              onToggleDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
              onSelectDate: (d) => controller.setSelectedDate(d),
              onSelectViewMode: (m) => controller.setViewMode(m),
              onTodayPressed: () => controller.goToToday(),
              onPrevious: () => controller.previous(),
              onNext: () => controller.next(),
              onSearchPressed: () => setState(() => _searchOpen = !_searchOpen),
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: TextField(
                  key: const Key('calendar_event_search'),
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Tìm sự kiện, Cố vấn, ngày...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () => setState(_searchController.clear),
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            if (upcoming.isNotEmpty && query.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: InkWell(
                  key: const Key('calendar_next_event'),
                  onTap: () {
                    controller.setSelectedDate(upcoming.first.startTime);
                    controller.setViewMode(SakuraCalendarViewMode.day);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE4E6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sắp tới: ${upcoming.first.title} · '
                            '${upcoming.first.startTime.day}/${upcoming.first.startTime.month}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),

            // Active Calendar View
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (calendarState.viewMode) {
                  SakuraCalendarViewMode.year => SakuraYearView(
                    key: ValueKey('year_${calendarState.selectedDate.year}'),
                    selectedDate: calendarState.selectedDate,
                    events: filteredEvents,
                    onSelectMonth: (date) {
                      controller.setSelectedDate(date);
                      controller.setViewMode(SakuraCalendarViewMode.month);
                    },
                    onSelectDate: (date) {
                      controller.setSelectedDate(date);
                      controller.setViewMode(SakuraCalendarViewMode.day);
                    },
                  ),
                  SakuraCalendarViewMode.month => SakuraMonthView(
                    key: ValueKey('month_${calendarState.selectedDate.month}'),
                    selectedDate: calendarState.selectedDate,
                    events: filteredEvents,
                    onSelectDate: (d) => controller.setSelectedDate(d),
                    onSelectEvent: _onEventSelected,
                    onPreviousMonth: () => controller.previous(),
                    onNextMonth: () => controller.next(),
                  ),
                  SakuraCalendarViewMode.agenda => SakuraAgendaView(
                    key: const ValueKey('agenda_view'),
                    selectedDate: calendarState.selectedDate,
                    events: filteredEvents,
                    onSelectEvent: _onEventSelected,
                    onAddEventAction: widget.onFabPressed,
                  ),
                  SakuraCalendarViewMode.day ||
                  SakuraCalendarViewMode.week => SakuraTimelineView(
                    key: ValueKey(
                      'timeline_${calendarState.viewMode.id}_${calendarState.selectedDate.toIso8601String()}',
                    ),
                    selectedDate: calendarState.selectedDate,
                    viewMode: calendarState.viewMode,
                    events: filteredEvents,
                    onSelectDate: (d) => controller.setSelectedDate(d),
                    onSelectEvent: _onEventSelected,
                    onPrevious: () => controller.previous(),
                    onNext: () => controller.next(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          (widget.fabLabel != null && widget.onFabPressed != null)
          ? FloatingActionButton.extended(
              key: const Key('calendar_fab_action'),
              onPressed: widget.onFabPressed,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: Icon(widget.fabIcon, size: 20),
              label: Text(
                widget.fabLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}
