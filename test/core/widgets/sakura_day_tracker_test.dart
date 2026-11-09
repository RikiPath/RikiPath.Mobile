import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/sakura_day_tracker.dart';

void main() {
  Widget app({
    required DateTime today,
    Map<String, LearningDayStatus> statuses = const {},
    ValueChanged<DateTime>? onDateSelected,
  }) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 360,
        child: SakuraDayTracker(
          today: today,
          statusesByDate: statuses,
          onDateSelected: onDateSelected,
        ),
      ),
    ),
  );

  Finder day(String date) => find.byKey(ValueKey('learning_day_$date'));
  Finder icon(String date, IconData value) =>
      find.descendant(of: day(date), matching: find.byIcon(value));

  testWidgets('uses explicit daily statuses and leaves unknown days neutral', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        today: DateTime(2026, 11, 5),
        statuses: {
          '2026-11-02': LearningDayStatus.completed,
          '2026-11-03': LearningDayStatus.inProgress,
          '2026-11-04': LearningDayStatus.missed,
          // Even incorrect future data cannot show a completed checkmark.
          '2026-11-06': LearningDayStatus.completed,
        },
      ),
    );

    expect(icon('2026-11-02', Icons.check_rounded), findsOneWidget);
    expect(icon('2026-11-03', Icons.access_time_rounded), findsOneWidget);
    expect(icon('2026-11-04', Icons.close_rounded), findsOneWidget);
    expect(icon('2026-11-05', Icons.circle_outlined), findsOneWidget);
    expect(icon('2026-11-06', Icons.circle_outlined), findsOneWidget);
    expect(
      find.byKey(const ValueKey('learning_day_2026-11-08')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected day is the real local date across a year boundary', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      app(
        today: DateTime(2027, 1, 1),
        onDateSelected: (date) => selected = date,
      ),
    );

    expect(day('2026-12-28'), findsOneWidget);
    expect(day('2027-01-03'), findsOneWidget);
    await tester.tap(day('2026-12-31'));
    expect(selected, DateTime(2026, 12, 31));
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: day('2027-01-01'), matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, contains('Chưa có dữ liệu'));
  });
}
