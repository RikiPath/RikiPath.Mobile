import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/data/fixture_home_repository.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/meeting/application/upcoming_meeting_provider.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';

import '../../support/test_auth_session.dart';

void main() {
  group('SakuraNavigationCard Unit & Widget Tests', () {
    testWidgets('renders 3D icon, title, description, and chevron with full card tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SakuraNavigationCard(
              key: const ValueKey('nav_card'),
              icon3d: Sakura3DIconType.notebook,
              title: 'Sổ từ cá nhân',
              description: 'Xem lại từ vựng đã lưu',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Sổ từ cá nhân'), findsOneWidget);
      expect(find.text('Xem lại từ vựng đã lưu'), findsOneWidget);
      expect(find.byType(Sakura3DIcon), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav_card')));
      expect(tapped, isTrue);
    });

    testWidgets('renders contextual badge when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SakuraNavigationCard(
              icon3d: Sakura3DIconType.flashcards,
              title: 'Ôn tập hôm nay',
              description: 'Ôn lại thẻ ghi nhớ',
              badge: const Text('Tiếp tục'),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ôn tập hôm nay'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('provides accessible button semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SakuraNavigationCard(
              icon3d: Sakura3DIconType.mockExam,
              title: 'Luyện đề',
              description: 'Đề thi thử JLPT',
              semanticLabel: 'Đi tới màn hình Luyện đề',
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(SakuraNavigationCard));
      expect(semantics.label, contains('Đi tới màn hình Luyện đề'));
    });

    testWidgets('SakuraCategoryShortcut renders enlarged 64x64 container and 46px 3D icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SakuraCategoryShortcut(
              label: 'Từ vựng',
              icon: Icons.book,
              icon3d: Sakura3DIconType.vocabulary,
              backgroundColor: AppColors.pastelGreenBg,
              foregroundColor: AppColors.pastelGreenFg,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SakuraCategoryShortcut),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.minWidth, 64);
      expect(container.constraints?.minHeight, 64);

      final icon3d = tester.widget<Sakura3DIcon>(find.byType(Sakura3DIcon));
      expect(icon3d.size, 46);
    });
  });

  group('Home UI Refinements Integration', () {
    testWidgets('greeting shows dynamic JLPT level', (tester) async {
      await _pumpHomeHarness(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home_greeting')), findsOneWidget);
      expect(
        find.text('Bạn đang học JLPT N4 · Cùng tiến bộ mỗi ngày!'),
        findsOneWidget,
      );
    });

    testWidgets('compact continue learning card renders [3D icon] [Lesson title] [JLPT level] on top row', (tester) async {
      await _pumpHomeHarness(tester);
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('home_continue_learning_card'));
      expect(card, findsOneWidget);

      // Lesson title on row 1
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('home_current_lesson_title')),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Bài 19: Thể quá khứ & Liệt kê hành động'), findsOneWidget);

      // N4 level pill
      expect(find.text('N4'), findsWidgets);

      // Progress bar and percentage
      expect(find.text('40%'), findsOneWidget);

      // CTA button
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('home_continue_learning_button')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('compact continue learning card does not duplicate prefix when lesson.title is already Bài 1: Chào hỏi & Hán tự', (tester) async {
      final customRepo = _CustomLessonLearningRepo(
        const CurrentLessonSummary(
          routeId: 'lesson-1',
          chapterNumber: 1,
          lessonNumber: 1,
          title: 'Bài 1: Chào hỏi & Hán tự',
          category: 'Từ vựng',
          pattern: 'Chào hỏi',
          durationMinutes: 20,
          progress: 0.0,
        ),
      );
      await _pumpHomeHarness(tester, learningRepository: customRepo);
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('home_continue_learning_card'));
      expect(card, findsOneWidget);

      final titleWidget = find.descendant(
        of: card,
        matching: find.byKey(const ValueKey('home_current_lesson_title')),
      );
      expect(titleWidget, findsOneWidget);

      // Must be exactly "Bài 1: Chào hỏi & Hán tự", never "Bài 1: Bài 1: Chào hỏi & Hán tự"
      expect(find.text('Bài 1: Chào hỏi & Hán tự'), findsOneWidget);
      expect(find.textContaining('Bài 1: Bài 1:'), findsNothing);

      // Icon must be deduplicated: resolved to conversation and never roadmap
      final cardIcon = find.descendant(
        of: card,
        matching: find.byType(Sakura3DIcon),
      );
      expect(cardIcon, findsOneWidget);
      expect(
        tester.widget<Sakura3DIcon>(cardIcon).type,
        Sakura3DIconType.conversation,
      );
      expect(
        tester.widget<Sakura3DIcon>(cardIcon).type,
        isNot(Sakura3DIconType.roadmap),
      );
    });

    testWidgets('4 navigation cards use unified SakuraNavigationCard pattern', (tester) async {
      final router = await _pumpHomeHarness(tester);
      await tester.pumpAndSettle();

      // 1. Ôn tập hôm nay
      final reviewCard = find.byKey(const ValueKey('home_daily_review_card'));
      await tester.scrollUntilVisible(reviewCard, 200);
      await tester.pumpAndSettle();
      expect(reviewCard, findsOneWidget);

      // 2. Luyện đề
      final practiceCard = find.byKey(const ValueKey('home_start_practice_card'));
      await tester.scrollUntilVisible(practiceCard, 200);
      await tester.pumpAndSettle();
      expect(practiceCard, findsOneWidget);

      // 3. Phòng họp fallback
      final meetingCard = find.byKey(const ValueKey('home_meeting_fallback_card'));
      await tester.scrollUntilVisible(meetingCard, 200);
      await tester.pumpAndSettle();
      expect(meetingCard, findsOneWidget);

      // 4. Sổ từ cá nhân
      final notebookCard = find.byKey(const ValueKey('home_notebook_shortcut'));
      await tester.scrollUntilVisible(notebookCard, 200);
      await tester.pumpAndSettle();
      expect(notebookCard, findsOneWidget);

      // Tap notebook card routes to notebook
      await tester.tap(notebookCard);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.notebook);
    });
  });
}

Future<GoRouter> _pumpHomeHarness(
  WidgetTester tester, {
  LearningRepository? learningRepository,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.home,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(const FixtureHomeRepository()),
        learnerJourneyRepositoryProvider.overrideWithValue(
          const _SimpleJourneyRepo(
            LearnerJourneyState(hasSelectedLevel: true, selectedLevel: JlptLevel.n4),
          ),
        ),
        learningRepositoryProvider.overrideWithValue(
          learningRepository ?? const FixtureLearningRepository(),
        ),
        analyticsRepositoryProvider.overrideWithValue(const _DummyAnalyticsRepository()),
        notificationRepositoryProvider.overrideWithValue(const _DummyNotificationRepository()),
        upcomingMeetingProvider.overrideWithValue(const AsyncData<UpcomingMeeting?>(null)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  return router;
}

class _CustomLessonLearningRepo implements LearningRepository {
  const _CustomLessonLearningRepo(this.lesson);
  final CurrentLessonSummary lesson;

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) async {
    const s = FixtureLearningRepository.snapshot;
    return LearningSnapshot(
      initials: s.initials,
      jlptTarget: s.jlptTarget,
      streakDays: s.streakDays,
      hasUnreadNotifications: s.hasUnreadNotifications,
      examDateLabel: s.examDateLabel,
      overallProgress: s.overallProgress,
      completedLessons: s.completedLessons,
      totalLessons: s.totalLessons,
      completedChapters: s.completedChapters,
      totalChapters: s.totalChapters,
      metrics: s.metrics,
      currentLesson: lesson,
      sections: s.sections,
      chapters: s.chapters,
      skillProgress: s.skillProgress,
      certificateLevelId: 1,
      hasSelectedLevel: true,
      hasCurrentLesson: true,
    );
  }
}

class _SimpleJourneyRepo implements LearnerJourneyRepository {
  const _SimpleJourneyRepo(this.state);
  final LearnerJourneyState state;

  @override
  Future<LearnerJourneyState> load() async => state;

  @override
  Future<void> save(LearnerJourneyState state) async {}

  @override
  Future<void> reset() async {}
}

class _DummyAnalyticsRepository implements AnalyticsRepository {
  const _DummyAnalyticsRepository();

  @override
  Future<LearnerAnalytics> loadLearnerAnalytics() async {
    return const LearnerAnalytics(
      streakDays: 5,
      completedLessons: 6,
      totalLessons: 18,
      skills: [],
    );
  }
}

class _DummyNotificationRepository implements NotificationRepository {
  const _DummyNotificationRepository();

  @override
  Future<List<AppNotification>> loadNotifications({bool unreadOnly = false}) async => const [];

  @override
  Future<int> loadUnreadCount() async => 0;

  @override
  Future<void> markRead(int notificationId) async {}

  @override
  Future<void> markAllRead() async {}
}
