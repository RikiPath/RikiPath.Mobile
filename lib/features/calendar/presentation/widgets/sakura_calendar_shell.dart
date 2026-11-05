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

class SakuraCalendarShell extends ConsumerStatefulWidget {
  const SakuraCalendarShell({
    super.key,
    required this.events,
    required this.roleName,
    this.fabLabel,
    this.fabIcon = Icons.add,
    this.onFabPressed,
    this.initialMode = SakuraCalendarViewMode.month,
  });

  final List<SakuraCalendarEvent> events;
  final String roleName;
  final String? fabLabel;
  final IconData fabIcon;
  final VoidCallback? onFabPressed;
  final SakuraCalendarViewMode initialMode;

  @override
  ConsumerState<SakuraCalendarShell> createState() =>
      _SakuraCalendarShellState();
}

class _SakuraCalendarShellState extends ConsumerState<SakuraCalendarShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sakuraCalendarControllerProvider.notifier)
          .setViewMode(widget.initialMode);
    });
  }

  void _onEventSelected(SakuraCalendarEvent event) {
    SakuraEventDetailSheet.show(context, event: event);
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(sakuraCalendarControllerProvider);
    final controller = ref.read(sakuraCalendarControllerProvider.notifier);

    // Filter events by selected visible layers
    final filteredEvents = widget.events
        .where((e) => calendarState.visibleEventTypes.contains(e.type))
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: SakuraCalendarDrawer(
        currentMode: calendarState.viewMode,
        visibleEventTypes: calendarState.visibleEventTypes,
        roleName: widget.roleName,
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
              onToggleDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onSelectDate: (d) => controller.setSelectedDate(d),
              onSelectViewMode: (m) => controller.setViewMode(m),
              onTodayPressed: () => controller.goToToday(),
            ),

            // Active Calendar View
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (calendarState.viewMode) {
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
                  SakuraCalendarViewMode.threeDay ||
                  SakuraCalendarViewMode.week =>
                    SakuraTimelineView(
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
      floatingActionButton: (widget.fabLabel != null && widget.onFabPressed != null)
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
