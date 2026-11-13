import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/application/sakura_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_header.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_drawer.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_month_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_agenda_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_timeline_view.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_empty_state.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_event_detail_sheet.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

Widget createTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SakuraCalendarEvent Domain Model Tests', () {
    test('Calculates 90-minute booking duration accurately', () {
      final start = DateTime(2026, 11, 10, 9, 0);
      final end = DateTime(2026, 11, 10, 10, 30);
      final event = SakuraCalendarEvent(
        id: 'evt-1',
        title: 'Tham vấn JLPT N2 (90 phút)',
        startTime: start,
        endTime: end,
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Thầy Kenji Sato',
        jlptLevel: 'N2',
      );

      expect(event.durationMinutes, 90);
      expect(event.isAllDay, isFalse);
      expect(event.isSameDay(DateTime(2026, 11, 10)), isTrue);
      expect(event.isSameDay(DateTime(2026, 11, 11)), isFalse);
    });

    test('IntersectsWith detection works accurately', () {
      final evt1 = SakuraCalendarEvent(
        id: 'evt-1',
        title: 'Event 1',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.consultation,
      );

      // Overlapping query range: 10:00 - 11:00
      expect(
        evt1.intersectsWith(DateTime(2026, 11, 10, 10, 0), DateTime(2026, 11, 10, 11, 0)),
        isTrue,
      );

      // Non-overlapping query range: 10:30 - 11:30
      expect(
        evt1.intersectsWith(DateTime(2026, 11, 10, 10, 30), DateTime(2026, 11, 10, 11, 30)),
        isFalse,
      );
    });

    test('Color scheme mapping for statuses', () {
      final confirmed = SakuraCalendarEvent(
        id: 'evt-c',
        title: 'Confirmed Booking',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
      );
      expect(confirmed.primaryColor, const Color(0xFF3B82F6));
      expect(confirmed.backgroundColor, const Color(0xFFEEF6FF));
      expect(confirmed.borderColor, const Color(0xFFBFDBFE));
      expect(confirmed.statusBadgeBgColor, const Color(0xFFDBEAFE));
      expect(confirmed.statusBadgeTextColor, const Color(0xFF2563EB));
      expect(confirmed.statusBadgeBorderColor, const Color(0xFFBFDBFE));
      expect(confirmed.statusBadgeIcon, Icons.check);
      expect(confirmed.levelChipBgColor, const Color(0xFFEFF6FF));
      expect(confirmed.levelChipBorderColor, const Color(0xFF93C5FD));
      expect(confirmed.levelChipTextColor, const Color(0xFF2563EB));

      final completed = SakuraCalendarEvent(
        id: 'evt-comp',
        title: 'Completed Booking',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.completed,
      );
      expect(completed.primaryColor, const Color(0xFF22C55E));
      expect(completed.backgroundColor, const Color(0xFFECFDF5));
      expect(completed.borderColor, const Color(0xFFA7E5C4));
      expect(completed.statusBadgeBgColor, const Color(0xFFD1FAE5));
      expect(completed.statusBadgeTextColor, const Color(0xFF059669));
      expect(completed.statusBadgeBorderColor, const Color(0xFFA7E5C4));
      expect(completed.statusBadgeIcon, Icons.check);
      expect(completed.levelChipBgColor, const Color(0xFFECFDF5));
      expect(completed.levelChipBorderColor, const Color(0xFF86EFAC));
      expect(completed.levelChipTextColor, const Color(0xFF059669));

      final cancelled = SakuraCalendarEvent(
        id: 'evt-x',
        title: 'Cancelled Booking',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.cancelled,
      );
      expect(cancelled.primaryColor, const Color(0xFFF43F5E));
      expect(cancelled.backgroundColor, const Color(0xFFFFF1F2));
      expect(cancelled.borderColor, const Color(0xFFFECDD3));
      expect(cancelled.statusBadgeBgColor, const Color(0xFFFFE4E6));
      expect(cancelled.statusBadgeTextColor, const Color(0xFFBE123C));
      expect(cancelled.statusBadgeBorderColor, const Color(0xFFFECDD3));
      expect(cancelled.statusBadgeIcon, Icons.close);
      expect(cancelled.levelChipBgColor, const Color(0xFFFFF1F2));
      expect(cancelled.levelChipBorderColor, const Color(0xFFFDA4AF));
      expect(cancelled.levelChipTextColor, const Color(0xFFBE123C));

      final slot = SakuraCalendarEvent(
        id: 'evt-s',
        title: 'Available Slot',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.availableSlot,
      );
      expect(slot.primaryColor, const Color(0xFF94A3B8));
      expect(slot.backgroundColor, const Color(0xFFF8FAFC));
      expect(slot.borderColor, const Color(0xFFE2E8F0));
      expect(slot.statusBadgeBgColor, const Color(0xFFE2E8F0));
      expect(slot.statusBadgeTextColor, const Color(0xFF475569));
      expect(slot.statusBadgeIcon, isNull);
      expect(slot.levelChipBgColor, const Color(0xFFF8FAFC));
      expect(slot.levelChipBorderColor, const Color(0xFFCBD5E1));
      expect(slot.levelChipTextColor, const Color(0xFF475569));

      final srs = SakuraCalendarEvent(
        id: 'evt-srs',
        title: 'SRS Review',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.srsReview,
      );
      expect(srs.primaryColor, const Color(0xFFF59E0B));
      expect(srs.backgroundColor, const Color(0xFFFFFBEB));
      expect(srs.borderColor, const Color(0xFFFDE68A));
      expect(srs.statusBadgeBgColor, const Color(0xFFFEF3C7));
      expect(srs.statusBadgeTextColor, const Color(0xFF92400E));
      expect(srs.levelChipBgColor, const Color(0xFFFFFBEB));
      expect(srs.levelChipBorderColor, const Color(0xFFFDE68A));
      expect(srs.levelChipTextColor, const Color(0xFF92400E));

      final learning = SakuraCalendarEvent(
        id: 'evt-learn',
        title: 'Completed Lesson',
        startTime: DateTime(2026, 11, 10, 9, 0),
        endTime: DateTime(2026, 11, 10, 10, 30),
        type: SakuraCalendarEventType.learningPlan,
      );
      expect(learning.primaryColor, const Color(0xFF22C55E));
      expect(learning.backgroundColor, const Color(0xFFECFDF5));
      expect(learning.borderColor, const Color(0xFFA7E5C4));
      expect(learning.statusBadgeBgColor, const Color(0xFFD1FAE5));
      expect(learning.statusBadgeTextColor, const Color(0xFF059669));
      expect(learning.statusBadgeBorderColor, const Color(0xFFA7E5C4));
    });
  });

  group('SakuraCalendarController Unit Tests', () {
    test('Initializes with default view and handles operations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(sakuraCalendarControllerProvider.notifier);
      final initialState = container.read(sakuraCalendarControllerProvider);

      expect(initialState.viewMode, SakuraCalendarViewMode.month);
      expect(initialState.visibleEventTypes.contains(SakuraCalendarEventType.consultation), isTrue);

      // Switch view modes
      controller.setViewMode(SakuraCalendarViewMode.week);
      expect(container.read(sakuraCalendarControllerProvider).viewMode, SakuraCalendarViewMode.week);

      controller.setViewMode(SakuraCalendarViewMode.day);
      expect(container.read(sakuraCalendarControllerProvider).viewMode, SakuraCalendarViewMode.day);

      controller.setViewMode(SakuraCalendarViewMode.agenda);
      expect(container.read(sakuraCalendarControllerProvider).viewMode, SakuraCalendarViewMode.agenda);

      // Select date
      final targetDate = DateTime(2026, 12, 15);
      controller.setSelectedDate(targetDate);
      expect(container.read(sakuraCalendarControllerProvider).selectedDate.year, 2026);
      expect(container.read(sakuraCalendarControllerProvider).selectedDate.month, 12);
      expect(container.read(sakuraCalendarControllerProvider).selectedDate.day, 15);

      // Toggle event filter
      controller.toggleEventType(SakuraCalendarEventType.availableSlot);
      expect(
        container.read(sakuraCalendarControllerProvider).visibleEventTypes.contains(SakuraCalendarEventType.availableSlot),
        isFalse,
      );
      controller.toggleEventType(SakuraCalendarEventType.availableSlot);
      expect(
        container.read(sakuraCalendarControllerProvider).visibleEventTypes.contains(SakuraCalendarEventType.availableSlot),
        isTrue,
      );

      // Jump to today
      controller.goToToday();
      final today = DateTime.now();
      final stateNow = container.read(sakuraCalendarControllerProvider);
      expect(stateNow.selectedDate.year, today.year);
      expect(stateNow.selectedDate.month, today.month);
      expect(stateNow.selectedDate.day, today.day);
    });
  });

  group('Sakura Calendar Widget Tests', () {
    testWidgets('SakuraCalendarHeader displays title and handles clicks', (tester) async {
      final testDate = DateTime(2026, 11, 5);
      bool drawerOpened = false;
      bool todayPressed = false;

      await tester.pumpWidget(
        createTestApp(
          SakuraCalendarHeader(
            selectedDate: testDate,
            currentViewMode: SakuraCalendarViewMode.month,
            onToggleDrawer: () => drawerOpened = true,
            onTodayPressed: () => todayPressed = true,
            onSelectDate: (_) {},
            onSelectViewMode: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check month title
      expect(find.text('Tháng 11, 2026'), findsOneWidget);

      // Tap drawer button
      await tester.tap(find.byKey(const Key('calendar_menu_button')));
      expect(drawerOpened, isTrue);

      // Tap today button
      await tester.tap(find.byKey(const Key('calendar_today_button')));
      expect(todayPressed, isTrue);
    });

    testWidgets('SakuraCalendarDrawer renders 5 views and filters', (tester) async {
      SakuraCalendarViewMode? selectedView;
      bool layerToggled = false;

      await tester.pumpWidget(
        createTestApp(
          SizedBox(
            width: 320,
            child: SakuraCalendarDrawer(
              currentMode: SakuraCalendarViewMode.month,
              visibleEventTypes: {SakuraCalendarEventType.consultation},
              onSelectMode: (mode) => selectedView = mode,
              onToggleEventType: (_) => layerToggled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check brand and title
      expect(find.text('Lịch học'), findsOneWidget);

      // Check view options
      expect(find.text('Lịch biểu'), findsOneWidget);
      expect(find.text('Ngày'), findsOneWidget);
      expect(find.text('3 ngày'), findsNothing);
      expect(find.text('Tuần'), findsOneWidget);

      // Toggle layer via CheckboxListTile
      await tester.tap(find.byKey(const Key('drawer_layer_consultation')));
      await tester.pump();
      expect(layerToggled, isTrue);

      // Tap Week mode
      await tester.tap(find.text('Tuần'));
      await tester.pump();
      expect(selectedView, SakuraCalendarViewMode.week);
    });

    testWidgets('SakuraMonthView renders 7 weekday columns and handles date tap', (tester) async {
      final selectedDate = DateTime(2026, 11, 5);

      final testEvent = SakuraCalendarEvent(
        id: 'test-1',
        title: 'Cố vấn JLPT 90p',
        startTime: DateTime(2026, 11, 5, 9, 0),
        endTime: DateTime(2026, 11, 5, 10, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        statusLabel: 'Đã xác nhận',
        jlptLevel: 'N5',
      );

      await tester.pumpWidget(
        createTestApp(
          SakuraMonthView(
            selectedDate: selectedDate,
            events: [testEvent],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check 7 Vietnamese weekday headers
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('T3'), findsOneWidget);
      expect(find.text('T4'), findsOneWidget);
      expect(find.text('T5'), findsOneWidget);
      expect(find.text('T6'), findsOneWidget);
      expect(find.text('T7'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);

      // Check event preview shown below month grid
      expect(find.text('Cố vấn JLPT 90p'), findsWidgets);
      expect(find.text('Đã xác nhận'), findsWidgets);
      expect(find.byType(JlptBadge), findsNothing);
    });

    testWidgets('SakuraAgendaView renders grouped dates and event cards', (tester) async {
      final testEvent = SakuraCalendarEvent(
        id: 'test-1',
        title: 'Buổi luyện đề N2',
        startTime: DateTime(2026, 11, 10, 14, 0),
        endTime: DateTime(2026, 11, 10, 15, 30),
        type: SakuraCalendarEventType.consultation,
        participantName: 'Sensei Tanaka',
        status: MentorMeetingStatus.accepted,
        statusLabel: 'Đã xác nhận',
        jlptLevel: 'N5',
      );

      await tester.pumpWidget(
        createTestApp(
          SakuraAgendaView(
            selectedDate: DateTime(2026, 11, 10),
            events: [testEvent],
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buổi luyện đề N2'), findsOneWidget);
      expect(find.text('14:00 – 15:30 (90 phút)'), findsOneWidget);
      expect(find.textContaining('Sensei Tanaka'), findsOneWidget);
      expect(find.text('Đã xác nhận'), findsWidgets);
      expect(find.byType(JlptBadge), findsNothing);
    });

    testWidgets('SakuraCalendarEmptyState renders mascot emblem and message', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SakuraCalendarEmptyState(
            title: 'Chưa có lịch nào',
            message: 'Hãy đặt lịch cùng Cố vấn để bắt đầu lộ trình JLPT!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có lịch nào'), findsOneWidget);
      expect(find.text('Hãy đặt lịch cùng Cố vấn để bắt đầu lộ trình JLPT!'), findsOneWidget);
    });

    testWidgets('SakuraTimelineView renders Day, Week, and overlapping events', (tester) async {
      final selectedDate = DateTime(2026, 11, 5);

      final evt1 = SakuraCalendarEvent(
        id: 'evt-1',
        title: 'Cố vấn JLPT 1-1',
        startTime: DateTime(2026, 11, 5, 9, 0),
        endTime: DateTime(2026, 11, 5, 10, 30),
        type: SakuraCalendarEventType.consultation,
      );

      final evt2Overlapping = SakuraCalendarEvent(
        id: 'evt-2',
        title: 'Luyện đề Bunpou',
        startTime: DateTime(2026, 11, 5, 9, 30),
        endTime: DateTime(2026, 11, 5, 11, 0),
        type: SakuraCalendarEventType.studySession,
      );

      // 1. Day View
      await tester.pumpWidget(
        createTestApp(
          SakuraTimelineView(
            selectedDate: selectedDate,
            viewMode: SakuraCalendarViewMode.day,
            events: [evt1, evt2Overlapping],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cố vấn JLPT 1-1'), findsOneWidget);
      expect(find.text('Luyện đề Bunpou'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);

      // 2. Week View
      await tester.pumpWidget(
        createTestApp(
          SakuraTimelineView(
            selectedDate: selectedDate,
            viewMode: SakuraCalendarViewMode.week,
            events: [evt1],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Week view shows 7 headers
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('T3'), findsOneWidget);
      expect(find.text('T4'), findsOneWidget);
      expect(find.text('T5'), findsOneWidget);
      expect(find.text('T6'), findsOneWidget);
      expect(find.text('T7'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
    });

    testWidgets('SakuraEventDetailSheet renders 90-minute badge and details', (tester) async {
      final testEvent = SakuraCalendarEvent(
        id: 'test-1',
        title: 'Tham vấn Lộ trình JLPT N2',
        startTime: DateTime(2026, 11, 10, 19, 0),
        endTime: DateTime(2026, 11, 10, 20, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Nguyễn Văn Minh',
        jlptLevel: 'N2',
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        notes: 'Chuẩn bị từ vựng Choukai bài 5',
      );

      await tester.pumpWidget(
        createTestApp(
          SakuraEventDetailSheet(event: testEvent),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham vấn Lộ trình JLPT N2'), findsOneWidget);
      expect(find.text('19:00 – 20:30 (90 phút)'), findsOneWidget);
      expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
      expect(find.text('Tham gia phòng học'), findsOneWidget);
      expect(find.text('Chuẩn bị từ vựng Choukai bài 5'), findsOneWidget);
    });
    test('SakuraCalendarEvent validates supported consultation levels strictly', () {
      expect(SakuraCalendarEvent.isSupportedConsultationLevel('N5'), isTrue);
      expect(SakuraCalendarEvent.isSupportedConsultationLevel('N4'), isTrue);
      expect(SakuraCalendarEvent.isSupportedConsultationLevel('N3'), isTrue);
      expect(SakuraCalendarEvent.isSupportedConsultationLevel('N2'), isTrue);
      // N1 is strictly disallowed for 1-1 mentor consultations
      expect(SakuraCalendarEvent.isSupportedConsultationLevel('N1'), isFalse);
      expect(SakuraCalendarEvent.isSupportedConsultationLevel('JLPT N1'), isFalse);

      expect(SakuraCalendarEvent.normalizeConsultationLevel('JLPT N2'), 'N2');
      expect(SakuraCalendarEvent.normalizeConsultationLevel('N1'), isNull);
    });

    testWidgets('SakuraTimelineView covers full 24h range (00:00 - 24:00) without clipping', (tester) async {
      final earlyMorningEvent = SakuraCalendarEvent(
        id: 'early-1',
        title: 'Buổi học sớm 05:00',
        startTime: DateTime(2026, 11, 5, 5, 0),
        endTime: DateTime(2026, 11, 5, 6, 30),
        type: SakuraCalendarEventType.studySession,
      );
      final lateNightEvent = SakuraCalendarEvent(
        id: 'late-1',
        title: 'Luyện đề đêm 23:00',
        startTime: DateTime(2026, 11, 5, 23, 0),
        endTime: DateTime(2026, 11, 5, 23, 45),
        type: SakuraCalendarEventType.studySession,
      );

      await tester.pumpWidget(
        createTestApp(
          SakuraTimelineView(
            selectedDate: DateTime(2026, 11, 5),
            viewMode: SakuraCalendarViewMode.day,
            events: [earlyMorningEvent, lateNightEvent],
            onSelectDate: (_) {},
            onSelectEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buổi học sớm 05:00'), findsOneWidget);
      expect(find.text('Luyện đề đêm 23:00'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('23:00'), findsOneWidget);
    });

    testWidgets('SakuraEventDetailSheet displays cancellation button and opens confirmation dialog', (tester) async {
      final activeBooking = SakuraCalendarEvent(
        id: 'active-1',
        bookingId: 9901,
        title: 'Tư vấn JLPT N2 với Sensei',
        startTime: DateTime(2026, 11, 10, 14, 0),
        endTime: DateTime(2026, 11, 10, 15, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.accepted,
        participantName: 'Sensei Tanaka',
        meetingLink: 'https://meet.google.com/test-room',
      );

      await tester.pumpWidget(
        createTestApp(
          SakuraEventDetailSheet(event: activeBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tham gia phòng học'), findsOneWidget);
      expect(find.text('Dời lịch hẹn'), findsOneWidget);
      expect(find.text('Hủy buổi tư vấn này'), findsOneWidget);

      final joinButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Tham gia phòng học'));
      expect(joinButton.style?.backgroundColor?.resolve({}), const Color(0xFFE5577F));

      final rescheduleButton = tester.widget<OutlinedButton>(find.byKey(const Key('sakura_event_reschedule_button')));
      expect(rescheduleButton.style?.backgroundColor?.resolve({}), const Color(0xFFEAF6FF));
      expect(rescheduleButton.style?.foregroundColor?.resolve({}), const Color(0xFF0284C7));

      final cancelButton = tester.widget<OutlinedButton>(find.byKey(const Key('sakura_event_cancel_button')));
      expect(cancelButton.style?.foregroundColor?.resolve({}), const Color(0xFFDC3545));

      await tester.tap(find.text('Hủy buổi tư vấn này'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận hủy buổi tư vấn?'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.text('Xác nhận hủy'), findsOneWidget);
    });

    testWidgets('SakuraEventDetailSheet renders cancelled state when meeting is cancelled', (tester) async {
      final cancelledEvent = SakuraCalendarEvent(
        id: 'canc-1',
        bookingId: 9902,
        title: 'Tư vấn JLPT N3 đã hủy',
        startTime: DateTime(2026, 11, 10, 14, 0),
        endTime: DateTime(2026, 11, 10, 15, 30),
        type: SakuraCalendarEventType.consultation,
        status: MentorMeetingStatus.cancelled,
        meetingLink: 'https://meet.google.com/test-room',
      );

      await tester.pumpWidget(
        createTestApp(
          SakuraEventDetailSheet(event: cancelledEvent),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buổi tư vấn đã bị hủy'), findsOneWidget);
      expect(find.text('Tham gia phòng học'), findsNothing);
      expect(find.text('Hủy buổi tư vấn này'), findsNothing);
    });
  });
}
