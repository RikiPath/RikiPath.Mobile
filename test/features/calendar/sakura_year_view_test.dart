import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/calendar/application/sakura_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_year_view.dart';

void main() {
  test(
    'year and month navigation clamp leap-day rather than skipping a month',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        sakuraCalendarControllerProvider.notifier,
      );
      controller.setSelectedDate(DateTime(2028, 2, 29));
      controller.setViewMode(SakuraCalendarViewMode.year);
      controller.previous();
      expect(
        container.read(sakuraCalendarControllerProvider).selectedDate,
        DateTime(2027, 2, 28),
      );
      controller.next();
      expect(
        container.read(sakuraCalendarControllerProvider).selectedDate,
        DateTime(2028, 2, 28),
      );
      controller.setSelectedDate(DateTime(2026, 1, 31));
      controller.setViewMode(SakuraCalendarViewMode.month);
      controller.next();
      expect(
        container.read(sakuraCalendarControllerProvider).selectedDate,
        DateTime(2026, 2, 28),
      );
    },
  );

  testWidgets('year shows real event indicator and opens month and day', (
    tester,
  ) async {
    final event = SakuraCalendarEvent(
      id: 'booking_17',
      title: 'Tư vấn JLPT',
      startTime: DateTime(2028, 2, 29, 9),
      endTime: DateTime(2028, 2, 29, 10, 30),
      type: SakuraCalendarEventType.consultation,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: SakuraCalendarShell(
            roleName: 'Học viên',
            events: [event],
            initialMode: SakuraCalendarViewMode.year,
            initialDate: DateTime(2028, 2, 29),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SakuraYearView), findsOneWidget);
    expect(find.text('Năm 2028'), findsOneWidget);
    expect(find.byKey(const Key('year_day_2_29')), findsOneWidget);

    await tester.tap(find.byKey(const Key('year_month_2')));
    await tester.pumpAndSettle();
    expect(find.byType(SakuraYearView), findsNothing);
    expect(find.text('Tháng 2, 2028'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar_view_mode_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Năm').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('year_day_2_29')));
    await tester.pumpAndSettle();
    expect(find.text('Ngày'), findsOneWidget);
  });

  testWidgets('year navigation advances exactly one year', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SakuraCalendarShell(
            roleName: 'Học viên',
            events: [],
            initialMode: SakuraCalendarViewMode.year,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final year = DateTime.now().year;
    await tester.tap(find.byKey(const Key('calendar_next_button')));
    await tester.pumpAndSettle();
    expect(find.text('Năm ${year + 1}'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar_previous_button')));
    await tester.pumpAndSettle();
    expect(find.text('Năm $year'), findsOneWidget);
  });

  testWidgets('search and category filter use only loaded events', (
    tester,
  ) async {
    final date = DateTime(2028, 2, 29, 9);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: SakuraCalendarShell(
            roleName: 'Học viên',
            initialDate: date,
            events: [
              SakuraCalendarEvent(
                id: 'mentor',
                title: 'Tư vấn cùng An',
                startTime: date,
                endTime: date.add(const Duration(minutes: 90)),
                type: SakuraCalendarEventType.consultation,
              ),
              SakuraCalendarEvent(
                id: 'study',
                title: 'Ôn tập ngữ pháp',
                startTime: date,
                endTime: date.add(const Duration(minutes: 30)),
                type: SakuraCalendarEventType.studySession,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tư vấn cùng An'), findsWidgets);
    expect(find.text('Ôn tập ngữ pháp'), findsWidgets);

    await tester.tap(find.byKey(const Key('calendar_search_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('calendar_event_search')),
      'An',
    );
    await tester.pumpAndSettle();
    expect(find.text('Tư vấn cùng An'), findsWidgets);
    expect(find.text('Ôn tập ngữ pháp'), findsNothing);

    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SakuraCalendarShell));
    ProviderScope.containerOf(context)
        .read(sakuraCalendarControllerProvider.notifier)
        .toggleEventType(SakuraCalendarEventType.studySession);
    await tester.pumpAndSettle();
    expect(find.text('Ôn tập ngữ pháp'), findsNothing);
    expect(find.text('Tư vấn cùng An'), findsWidgets);
  });
}
