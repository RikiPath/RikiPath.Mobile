import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/learner_calendar_screen.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

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
          learnerCalendarSrsEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerCalendarLearningEventsProvider.overrideWith(
            (ref) async => const [],
          ),
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
          learnerCalendarSrsEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerCalendarLearningEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerMyCoursesProvider.overrideWith(
            () => _TestCoursesController(() async {
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
          home: LearnerCalendarScreen(
            initialDate: DateTime.utc(2026, 11, 10, 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SakuraCalendarShell), findsOneWidget);
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

    expect(find.byType(SakuraCalendarShell), findsOneWidget);
    expect(find.text('Tháng 12, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hanging cohort courses request becomes a retryable timeout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerCalendarSrsEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerCalendarLearningEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerMyCoursesProvider.overrideWith(
            _PendingCoursesController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: LearnerCalendarScreen(
            initialDate: DateTime.utc(2026, 11, 10, 9),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Đang tải lịch học...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(
      find.textContaining('Kết nối lịch quá thời gian. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(SakuraCalendarShell), findsOneWidget);
  });

  testWidgets('failed refresh preserves previously loaded cohort sessions', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerCalendarSrsEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerCalendarLearningEventsProvider.overrideWith(
            (ref) async => const [],
          ),
          learnerMyCoursesProvider.overrideWith(
            () => _TestCoursesController(() async {
              requests++;
              if (requests > 1) throw StateError('offline');
              return [
                LearnerStudyCourseDetail(
                  id: 17,
                  name: 'Lớp N3 Tối',
                  planId: 1,
                  cohortId: 10,
                  sessionType: 'Group',
                  level: 'N3',
                  mentorId: 5,
                  mentorName: 'Cố vấn An',
                  durationMonths: 2,
                  sessionsPerWeek: 3,
                  totalSessions: 30,
                  sessionMinutes: 90,
                  amount: 2000000,
                  paymentStatus: 'Paid',
                  status: 'Active',
                  startsAt: DateTime.utc(2026, 11, 10, 9),
                  endsAt: DateTime.utc(2027, 1, 19, 9),
                  completedAt: null,
                  eligibility: const CourseEligibilitySummary(
                    canClaim: false,
                    passedOnTimeHomework: 0,
                    requiredHomework: 0,
                    absentSessions: 0,
                    countedSessions: 0,
                    reasons: [],
                  ),
                  sessions: [
                    CourseSessionItem(
                      id: 101,
                      number: 1,
                      attempt: 1,
                      scheduledAt: DateTime.utc(2026, 11, 10, 9),
                      status: 'Scheduled',
                    ),
                  ],
                  requests: const [],
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
          home: LearnerCalendarScreen(
            initialDate: DateTime.utc(2026, 11, 10, 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Lớp N3 Tối'), findsWidgets);

    final context = tester.element(find.byType(LearnerCalendarScreen));
    ProviderScope.containerOf(context).invalidate(learnerMyCoursesProvider);
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.byType(SakuraCalendarShell), findsOneWidget);
    expect(find.textContaining('Lớp N3 Tối'), findsWidgets);
    expect(find.textContaining('Chưa đồng bộ được lịch lớp nhóm'), findsOneWidget);
  });

  testWidgets('expired session never displays cached learner events', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerCalendarEventsProvider.overrideWith(
            (ref) async => throw const UnauthorizedError(),
          ),
          learnerCalendarSrsEventsProvider.overrideWith(
            (ref) async => [
              SakuraCalendarEvent(
                id: 'cached_srs',
                title: 'Ôn tập đã lưu tạm',
                startTime: DateTime.now(),
                endTime: DateTime.now().add(const Duration(hours: 1)),
                type: SakuraCalendarEventType.srsReview,
              ),
            ],
          ),
          learnerCalendarLearningEventsProvider.overrideWith(
            (ref) async => const [],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: LearnerCalendarScreen(
            initialDate: DateTime.utc(2026, 11, 10, 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Phiên đăng nhập đã hết hạn'), findsOneWidget);
    expect(find.textContaining('Ôn tập đã lưu tạm'), findsNothing);
  });
}

class _PendingCoursesController extends LearnerMyCoursesController {
  @override
  Future<List<LearnerStudyCourseDetail>> build() =>
      Completer<List<LearnerStudyCourseDetail>>().future;
}

class _TestCoursesController extends LearnerMyCoursesController {
  _TestCoursesController(this.load);

  final Future<List<LearnerStudyCourseDetail>> Function() load;

  @override
  Future<List<LearnerStudyCourseDetail>> build() => load();
}
