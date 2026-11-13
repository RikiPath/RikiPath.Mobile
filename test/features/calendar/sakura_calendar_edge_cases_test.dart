import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_drawer.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_header.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_event_detail_sheet.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_month_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_timeline_view.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

Widget buildResponsiveApp({
  required Widget child,
  double width = 393,
  double height = 852,
  double textScale = 1.0,
  Locale locale = const Locale('vi'),
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('Sakura Calendar Timeline Edge Cases Tests', () {
    testWidgets('Renders early-morning event (05:00 - 06:30) correctly', (tester) async {
      final date = DateTime(2026, 11, 10);
      final earlyEvent = SakuraCalendarEvent(
        id: 'early-1',
        title: 'Ôn tập sớm',
        startTime: DateTime(2026, 11, 10, 5, 0),
        endTime: DateTime(2026, 11, 10, 6, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Thầy Kenji',
        jlptLevel: 'N3',
      );

      await tester.pumpWidget(
        buildResponsiveApp(
          child: SakuraTimelineView(
            selectedDate: date,
            viewMode: SakuraCalendarViewMode.day,
            events: [earlyEvent],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ôn tập sớm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders late-night event (22:30 - 24:00) clamped safely', (tester) async {
      final date = DateTime(2026, 11, 10);
      final lateEvent = SakuraCalendarEvent(
        id: 'late-1',
        title: 'Tư vấn khuya',
        startTime: DateTime(2026, 11, 10, 22, 30),
        endTime: DateTime(2026, 11, 10, 24, 0),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Cô Yuka',
        jlptLevel: 'N2',
      );

      await tester.pumpWidget(
        buildResponsiveApp(
          child: SakuraTimelineView(
            selectedDate: date,
            viewMode: SakuraCalendarViewMode.day,
            events: [lateEvent],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tư vấn khuya'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Handles cross-midnight boundary without RenderFlex overflow', (tester) async {
      final date = DateTime(2026, 11, 10);
      final midnightCrossEvent = SakuraCalendarEvent(
        id: 'midnight-1',
        title: 'Xuyên đêm',
        startTime: DateTime(2026, 11, 10, 23, 30),
        endTime: DateTime(2026, 11, 11, 1, 0),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Thầy Kenji',
        jlptLevel: 'N2',
      );

      await tester.pumpWidget(
        buildResponsiveApp(
          child: SakuraTimelineView(
            selectedDate: date,
            viewMode: SakuraCalendarViewMode.day,
            events: [midnightCrossEvent],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xuyên đêm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders back-to-back non-overlapping 90-minute events cleanly', (tester) async {
      final date = DateTime(2026, 11, 10);
      final event1 = SakuraCalendarEvent(
        id: 'b2b-1',
        title: 'Slot 1: Thầy Kenji',
        startTime: DateTime(2026, 11, 10, 10, 0),
        endTime: DateTime(2026, 11, 10, 11, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Thầy Kenji',
      );
      final event2 = SakuraCalendarEvent(
        id: 'b2b-2',
        title: 'Slot 2: Cô Yuka',
        startTime: DateTime(2026, 11, 10, 11, 30),
        endTime: DateTime(2026, 11, 10, 13, 0),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Cô Yuka',
      );

      await tester.pumpWidget(
        buildResponsiveApp(
          child: SakuraTimelineView(
            selectedDate: date,
            viewMode: SakuraCalendarViewMode.day,
            events: [event1, event2],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Slot 1: Thầy Kenji'), findsOneWidget);
      expect(find.text('Slot 2: Cô Yuka'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Partitions colliding / overlapping events side-by-side', (tester) async {
      final date = DateTime(2026, 11, 10);
      final event1 = SakuraCalendarEvent(
        id: 'col-1',
        title: 'Tư vấn Thầy Kenji',
        startTime: DateTime(2026, 11, 10, 14, 0),
        endTime: DateTime(2026, 11, 10, 15, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Thầy Kenji',
      );
      final event2 = SakuraCalendarEvent(
        id: 'col-2',
        title: 'Slot còn chỗ: Cô Yuka',
        startTime: DateTime(2026, 11, 10, 14, 30),
        endTime: DateTime(2026, 11, 10, 16, 0),
        type: SakuraCalendarEventType.availableSlot,
        statusLabel: 'Có thể đặt',
        participantName: 'Cô Yuka',
      );

      await tester.pumpWidget(
        buildResponsiveApp(
          child: SakuraTimelineView(
            selectedDate: date,
            viewMode: SakuraCalendarViewMode.day,
            events: [event1, event2],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tư vấn Thầy Kenji'), findsOneWidget);
      expect(find.text('Slot còn chỗ: Cô Yuka'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sakura Calendar Responsiveness & Accessibility Tests', () {
    for (final width in [360.0, 393.0, 412.0]) {
      testWidgets('Month view fits on width ${width}dp without overflow', (tester) async {
        final date = DateTime(2026, 11, 10);
        await tester.pumpWidget(
          buildResponsiveApp(
            width: width,
            child: SakuraMonthView(
              selectedDate: date,
              events: const [],
              onSelectDate: (_) {},
              onSelectEvent: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.3, 2.0]) {
      testWidgets('Event Detail Sheet renders with text scale ${scale}x without overflow', (tester) async {
        final event = SakuraCalendarEvent(
          id: 'scale-test',
          title: 'Tư vấn JLPT với Mentor One',
          startTime: DateTime(2026, 11, 10, 9, 0),
          endTime: DateTime(2026, 11, 10, 10, 30),
          type: SakuraCalendarEventType.consultation,
          status: MentorMeetingStatus.accepted,
          statusLabel: 'Đã xác nhận',
          participantName: 'Mentor One',
          participantRole: 'Cố vấn chuyên môn',
          jlptLevel: 'JLPT N5',
          meetingLink: 'http://meet.google.com/abc-xyz',
          notes: 'Vui lòng vào phòng học đúng giờ.',
        );

        await tester.pumpWidget(
          buildResponsiveApp(
            textScale: scale,
            child: SakuraEventDetailSheet(
              event: event,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tư vấn JLPT với Mentor One'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Header and Drawer render correctly in Japanese (ja) locale', (tester) async {
      await tester.pumpWidget(
        buildResponsiveApp(
          locale: const Locale('ja'),
          child: Column(
            children: [
              SakuraCalendarHeader(
                selectedDate: DateTime(2026, 11, 10),
                currentViewMode: SakuraCalendarViewMode.month,
                onSelectViewMode: (_) {},
                onTodayPressed: () {},
                onPrevious: () {},
                onNext: () {},
                onSelectDate: (_) {},
                onToggleDrawer: () {},
              ),
              Expanded(
                child: SakuraCalendarDrawer(
                  currentMode: SakuraCalendarViewMode.month,
                  onSelectMode: (_) {},
                  visibleEventTypes: const {
                    SakuraCalendarEventType.consultation,
                    SakuraCalendarEventType.availableSlot,
                    SakuraCalendarEventType.srsReview,
                    SakuraCalendarEventType.studySession,
                  },
                  onToggleEventType: (_) {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
