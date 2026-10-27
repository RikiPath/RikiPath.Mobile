// Deterministic visual capture harness for the learner Home dashboard.
//
// This file is intentionally *not* a golden assertion. It renders the real
// Home route with deterministic fixture/fake repositories and real fonts, then
// writes PNG screenshots for human before/after review.
//
// It is skipped unless the RIKI_CAPTURE_DIR environment variable is set:
//
//   $env:RIKI_CAPTURE_DIR = 'D:\path\to\output'
//   flutter test --no-pub test/visual/home_visual_capture_test.dart
//
// Fonts are loaded from the local Flutter SDK (Roboto + Material Icons) and,
// when present, from the host OS for Japanese glyph coverage. Captures are
// therefore host-dependent review aids and must not be used as goldens.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/meeting/application/upcoming_meeting_provider.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/practice_session_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../support/test_auth_session.dart';

final String? _outputDirectory = Platform.environment['RIKI_CAPTURE_DIR'];

void main() {
  final skip = _outputDirectory == null || _outputDirectory!.isEmpty;

  setUpAll(() async {
    if (skip) return;
    await _loadFonts();
  });

  const scenarios = <_Scenario>[
    _Scenario('01_normal_412x915_vi', Size(412, 915)),
    _Scenario('02_compact_360x740_vi', Size(360, 740)),
    _Scenario(
      '03_compact_360x740_textscale_1_3',
      Size(360, 740),
      textScale: 1.3,
    ),
    _Scenario(
      '04_new_learner_412x915',
      Size(412, 915),
      journey: LearnerJourneyState(),
    ),
    _Scenario('05_loading_412x915', Size(412, 915), loading: true),
    _Scenario('06_api_failure_412x915', Size(412, 915), failing: true),
    _Scenario(
      '07_japanese_412x915',
      Size(412, 915),
      locale: Locale('ja'),
    ),
    _Scenario(
      '08_long_vietnamese_name_360x740',
      Size(360, 740),
      firstName: 'Nguyễn Hoàng Phương Thảo Quỳnh',
    ),
  ];

  for (final scenario in scenarios) {
    testWidgets('capture ${scenario.name}', (tester) async {
      await _capture(tester, scenario);
    }, skip: skip);
  }
}

class _Scenario {
  const _Scenario(
    this.name,
    this.size, {
    this.textScale = 1,
    this.journey,
    this.loading = false,
    this.failing = false,
    this.locale = const Locale('vi'),
    this.firstName = 'Lan',
  });

  final String name;
  final Size size;
  final double textScale;
  final LearnerJourneyState? journey;
  final bool loading;
  final bool failing;
  final Locale locale;
  final String firstName;
}

Future<void> _capture(WidgetTester tester, _Scenario scenario) async {
  tester.view.physicalSize = scenario.size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scenario.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final journey =
      scenario.journey ??
      LearnerJourneyState(
        selectedLevel: JlptLevel.n4,
        hasSelectedLevel: true,
        lessonProgress: <String, LessonProgress>{
          FixtureLessonRepository.lesson19RouteId: LessonProgress(
            progressPercent: 60,
            resumePositionSeconds: 240,
            isCompleted: false,
          ),
        },
      );

  final container = ProviderContainer(
    overrides: [
      learnerJourneyRepositoryProvider.overrideWithValue(
        _MemoryJourneyRepository(journey, pending: scenario.loading),
      ),
      learningRepositoryProvider.overrideWithValue(
        scenario.loading
            ? const _PendingLearningRepository()
            : const FixtureLearningRepository(),
      ),
      lessonRepositoryProvider.overrideWithValue(
        const FixtureLessonRepository(),
      ),
      analyticsRepositoryProvider.overrideWithValue(
        _AnalyticsRepository(
          failing: scenario.failing,
          pending: scenario.loading,
        ),
      ),
      notificationRepositoryProvider.overrideWithValue(
        _NotificationRepository(failing: scenario.failing),
      ),
      practiceSessionRepositoryProvider.overrideWithValue(
        _PracticeSessionRepository(),
      ),
      dailyReviewRepositoryProvider.overrideWithValue(
        _DailyReviewRepository(failing: scenario.failing),
      ),
      userProfileRepositoryProvider.overrideWithValue(
        _ProfileRepository(
          firstName: scenario.firstName,
          failing: scenario.failing,
          pending: scenario.loading,
        ),
      ),
      upcomingMeetingProvider.overrideWithValue(
        const AsyncData<UpcomingMeeting?>(null),
      ),
    ],
  );
  addTearDown(container.dispose);
  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.home,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  const boundaryKey = ValueKey<String>('capture_boundary');
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: scenario.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  await _writeBoundary(tester, boundaryKey, '${scenario.name}_top');

  final scrollable = find.byType(Scrollable).first;
  if (!scenario.loading && scrollable.evaluate().isNotEmpty) {
    await tester.drag(scrollable, Offset(0, -scenario.size.height * 0.75));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _writeBoundary(tester, boundaryKey, '${scenario.name}_scrolled');
  }

  final exception = tester.takeException();
  if (exception != null) {
    File(
      '${_outputDirectory!}${Platform.pathSeparator}${scenario.name}_EXCEPTION.txt',
    ).writeAsStringSync('$exception');
  }
}

Future<void> _writeBoundary(
  WidgetTester tester,
  Key boundaryKey,
  String fileName,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(_outputDirectory!)..createSync(recursive: true);
    File(
      '${directory.path}${Platform.pathSeparator}$fileName.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final sdkFonts = flutterRoot == null
      ? null
      : '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var added = false;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      added = true;
    }
    if (added) await loader.load();
  }

  if (sdkFonts != null) {
    final roboto = <String>[
      '$sdkFonts/roboto-regular.ttf',
      '$sdkFonts/roboto-medium.ttf',
      '$sdkFonts/roboto-bold.ttf',
      '$sdkFonts/roboto-black.ttf',
    ];
    await load('Roboto', roboto);
    // Styles without an explicit family resolve to the test default family.
    await load('FlutterTest', roboto);
    await load('MaterialIcons', <String>['$sdkFonts/materialicons-regular.otf']);
  }
  // Host Japanese font registered under the theme fallback family name.
  await load('Noto Sans JP', <String>[
    r'C:\Windows\Fonts\YuGothM.ttc',
    r'C:\Windows\Fonts\msgothic.ttc',
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
  ]);
}

class _MemoryJourneyRepository implements LearnerJourneyRepository {
  _MemoryJourneyRepository(this.state, {this.pending = false});

  LearnerJourneyState state;
  final bool pending;

  @override
  Future<LearnerJourneyState> load() {
    if (pending) return Completer<LearnerJourneyState>().future;
    return Future<LearnerJourneyState>.value(state);
  }

  @override
  Future<void> save(LearnerJourneyState state) async => this.state = state;

  @override
  Future<void> reset() async => state = const LearnerJourneyState();
}

class _PendingLearningRepository implements LearningRepository {
  const _PendingLearningRepository();

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) => Completer<LearningSnapshot>().future;
}

class _AnalyticsRepository implements AnalyticsRepository {
  const _AnalyticsRepository({this.failing = false, this.pending = false});

  final bool failing;
  final bool pending;

  @override
  Future<LearnerAnalytics> loadLearnerAnalytics() async {
    if (pending) return Completer<LearnerAnalytics>().future;
    if (failing) throw StateError('offline');
    return const LearnerAnalytics(
      streakDays: 7,
      completedLessons: 36,
      totalLessons: 150,
      skills: <SkillBreakdown>[
        SkillBreakdown(skill: 'Kanji', averageScore: 72, attemptCount: 10),
      ],
    );
  }
}

class _NotificationRepository implements NotificationRepository {
  const _NotificationRepository({this.failing = false});

  final bool failing;

  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => const <AppNotification>[];

  @override
  Future<int> loadUnreadCount() async {
    if (failing) throw StateError('offline');
    return 2;
  }

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

class _PracticeSessionRepository implements PracticeSessionRepository {
  DemoPracticeSessions? _sessions;

  @override
  Future<DemoPracticeSessions?> load({
    required List<DemoReviewCard> reviewCards,
    required DemoMockTest mockTest,
  }) async {
    return _sessions ??
        DemoPracticeSessions(
          reviewSession: DemoReviewSession(cards: reviewCards),
        );
  }

  @override
  Future<void> reset() async => _sessions = null;

  @override
  Future<void> save(DemoPracticeSessions sessions) async => _sessions = sessions;
}

class _DailyReviewRepository implements DailyReviewRepository {
  const _DailyReviewRepository({this.failing = false});

  final bool failing;

  @override
  Future<DailyReviewQueue> loadDailyQueue() async {
    if (failing) throw StateError('offline');
    return const DailyReviewQueue(totalDue: 0, items: <DailyReviewCard>[]);
  }

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) => throw UnimplementedError();
}

class _ProfileRepository implements UserProfileRepository {
  const _ProfileRepository({
    required this.firstName,
    this.failing = false,
    this.pending = false,
  });

  final String firstName;
  final bool failing;
  final bool pending;

  @override
  Future<UserProfile> loadProfile() async {
    if (pending) return Completer<UserProfile>().future;
    if (failing) throw StateError('offline');
    return UserProfile(
      userId: 42,
      email: 'learner@example.test',
      firstName: firstName,
      lastName: 'Nguyễn',
      avatarUrl: null,
      role: 'Learner',
      isEmailVerified: true,
      targetJlptLevelId: 4,
      targetJlptLevelName: 'N4',
      currentStudyLevelId: 5,
      currentStudyLevelName: 'N5',
      dailyStudyMinutes: 30,
      emailNotificationsEnabled: true,
      systemNotificationsEnabled: true,
    );
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) =>
      throw UnimplementedError();
}
