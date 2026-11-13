import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';

@immutable
class SakuraCalendarState {
  const SakuraCalendarState({
    required this.selectedDate,
    required this.viewMode,
    required this.visibleEventTypes,
    this.selectedEvent,
  });

  final DateTime selectedDate;
  final SakuraCalendarViewMode viewMode;
  final Set<SakuraCalendarEventType> visibleEventTypes;
  final SakuraCalendarEvent? selectedEvent;

  SakuraCalendarState copyWith({
    DateTime? selectedDate,
    SakuraCalendarViewMode? viewMode,
    Set<SakuraCalendarEventType>? visibleEventTypes,
    SakuraCalendarEvent? selectedEvent,
    bool clearSelectedEvent = false,
  }) {
    return SakuraCalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      visibleEventTypes: visibleEventTypes ?? this.visibleEventTypes,
      selectedEvent: clearSelectedEvent
          ? null
          : (selectedEvent ?? this.selectedEvent),
    );
  }
}

class SakuraCalendarController extends Notifier<SakuraCalendarState> {
  DateTime _shiftMonth(DateTime date, int offset) {
    final first = DateTime(date.year, date.month + offset);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, date.day.clamp(1, lastDay));
  }

  DateTime _shiftYear(DateTime date, int offset) {
    final year = date.year + offset;
    final lastDay = DateTime(year, date.month + 1, 0).day;
    return DateTime(year, date.month, date.day.clamp(1, lastDay));
  }

  @override
  SakuraCalendarState build() {
    return SakuraCalendarState(
      selectedDate: DateTime.now(),
      viewMode: SakuraCalendarViewMode.month,
      visibleEventTypes: SakuraCalendarEventType.values.toSet(),
    );
  }

  void setViewMode(SakuraCalendarViewMode mode) {
    if (state.viewMode == mode) return;
    state = state.copyWith(viewMode: mode);
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void goToToday() {
    state = state.copyWith(selectedDate: DateTime.now());
  }

  void selectEvent(SakuraCalendarEvent? event) {
    state = state.copyWith(
      selectedEvent: event,
      clearSelectedEvent: event == null,
    );
  }

  void previous() {
    final cur = state.selectedDate;
    switch (state.viewMode) {
      case SakuraCalendarViewMode.day:
        state = state.copyWith(
          selectedDate: cur.subtract(const Duration(days: 1)),
        );
      case SakuraCalendarViewMode.week:
        state = state.copyWith(
          selectedDate: cur.subtract(const Duration(days: 7)),
        );
      case SakuraCalendarViewMode.month:
        state = state.copyWith(selectedDate: _shiftMonth(cur, -1));
      case SakuraCalendarViewMode.year:
        state = state.copyWith(selectedDate: _shiftYear(cur, -1));
      case SakuraCalendarViewMode.agenda:
        state = state.copyWith(
          selectedDate: cur.subtract(const Duration(days: 7)),
        );
    }
  }

  void next() {
    final cur = state.selectedDate;
    switch (state.viewMode) {
      case SakuraCalendarViewMode.day:
        state = state.copyWith(selectedDate: cur.add(const Duration(days: 1)));
      case SakuraCalendarViewMode.week:
        state = state.copyWith(selectedDate: cur.add(const Duration(days: 7)));
      case SakuraCalendarViewMode.month:
        state = state.copyWith(selectedDate: _shiftMonth(cur, 1));
      case SakuraCalendarViewMode.year:
        state = state.copyWith(selectedDate: _shiftYear(cur, 1));
      case SakuraCalendarViewMode.agenda:
        state = state.copyWith(selectedDate: cur.add(const Duration(days: 7)));
    }
  }

  void toggleEventType(SakuraCalendarEventType type) {
    final nextTypes = Set<SakuraCalendarEventType>.from(
      state.visibleEventTypes,
    );
    if (nextTypes.contains(type)) {
      if (nextTypes.length > 1) {
        nextTypes.remove(type);
      }
    } else {
      nextTypes.add(type);
    }
    state = state.copyWith(visibleEventTypes: nextTypes);
  }
}

final sakuraCalendarControllerProvider =
    NotifierProvider.autoDispose<SakuraCalendarController, SakuraCalendarState>(
      SakuraCalendarController.new,
    );
