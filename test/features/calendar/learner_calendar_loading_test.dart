import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/learner_calendar_screen.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  Future<void> pumpCalendar(
    WidgetTester tester,
    Future<List<SakuraCalendarEvent>> Function() load, {
    DateTime? initialDate,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerCalendarEventsProvider.overrideWith((ref) => load()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: LearnerCalendarScreen(initialDate: initialDate),
        ),
      ),
    );
  }

  testWidgets(
    'loading keeps the calendar visible, then renders an empty result',
    (tester) async {
      final pending = Completer<List<SakuraCalendarEvent>>();
      await pumpCalendar(tester, () => pending.future);
      await tester.pump();

      expect(find.byType(SakuraCalendarShell), findsOneWidget);
      expect(find.text('Đang tải lịch học...'), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();

      expect(find.byType(SakuraCalendarShell), findsOneWidget);
      expect(find.text('Đang tải lịch học...'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('error shows Retry and retry can reach data', (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerMentorBookingsControllerProvider.overrideWith(
            () => _TestBookingsController(() async {
              requests++;
              if (requests == 1) throw StateError('offline');
              return const [];
            }),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const LearnerCalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SakuraCalendarShell), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Thử lại'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected route date initializes the shared calendar state', (
    tester,
  ) async {
    await pumpCalendar(
      tester,
      () async => const [],
      initialDate: DateTime(2026, 12, 31),
    );
    await tester.pumpAndSettle();

    // The date is visible in the shared Sakura calendar, not another screen.
    expect(find.byType(SakuraCalendarShell), findsOneWidget);
    expect(find.text('Tháng 12, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hanging bookings request becomes a retryable timeout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerMentorBookingsControllerProvider.overrideWith(
            _PendingBookingsController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const LearnerCalendarScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Đang tải lịch học...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(
      find.text('Kết nối lịch quá thời gian. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(SakuraCalendarShell), findsNothing);
  });

  testWidgets('failed refresh preserves previously loaded bookings', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerMentorBookingsControllerProvider.overrideWith(
            () => _TestBookingsController(() async {
              requests++;
              if (requests > 1) throw StateError('offline');
              return [
                LearnerMentorBooking(
                  id: 17,
                  userSubscriptionId: 1,
                  status: MentorMeetingStatus.accepted,
                  scheduledAt: MentorTimestamp.parse('2026-11-10T09:00:00Z'),
                  mentorName: 'Cố vấn An',
                ),
              ];
            }),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const LearnerCalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Tư vấn JLPT với Cố vấn An'), findsWidgets);

    final context = tester.element(find.byType(LearnerCalendarScreen));
    ProviderScope.containerOf(
      context,
    ).invalidate(learnerMentorBookingsControllerProvider);
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.byType(SakuraCalendarShell), findsOneWidget);
    expect(find.textContaining('Tư vấn JLPT với Cố vấn An'), findsWidgets);
    expect(find.textContaining('Chưa đồng bộ được lịch mới'), findsOneWidget);
  });
}

class _PendingBookingsController extends LearnerMentorBookingsController {
  @override
  Future<List<LearnerMentorBooking>> build() =>
      Completer<List<LearnerMentorBooking>>().future;
}

class _TestBookingsController extends LearnerMentorBookingsController {
  _TestBookingsController(this.load);

  final Future<List<LearnerMentorBooking>> Function() load;

  @override
  Future<List<LearnerMentorBooking>> build() => load();
}
