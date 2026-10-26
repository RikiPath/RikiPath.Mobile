import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/analytics/presentation/learner_analytics_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/session_demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/review_quality.dart';
import 'package:rikipath_mobile/features/practice/domain/practice_session_repository.dart';

import '../../support/test_auth_session.dart';

void main() {
  group('R4 Home learning composition', () {
    test('1. Home restores the selected JLPT level', () async {
      final harness = _providerHarness(
        journey: const LearnerJourneyState(
          selectedLevel: JlptLevel.n3,
          hasSelectedLevel: true,
        ),
      );
      addTearDown(harness.dispose);
      final journey = await harness.container.read(
        learnerJourneyControllerProvider.future,
      );
      expect(journey.selectedLevel, JlptLevel.n3);
      expect(journey.hasSelectedLevel, isTrue);
    });

    testWidgets('2. Home displays local learning progress', (tester) async {
      final harness = await _pumpHome(
        tester,
        journey: _journeyWithFirstLessonCompleted(),
      );
      await _pumpFrames(tester);
      expect(
        find.byKey(const ValueKey<String>('home_local_progress_value')),
        findsOneWidget,
      );
      expect(find.textContaining('19/30'), findsOneWidget);
      harness.dispose();
    });

    test('3. Current lesson advances after local completion', () async {
      final harness = _providerHarness(journey: _selectedJourney());
      addTearDown(harness.dispose);
      final first = await harness.container.read(
        learningControllerProvider.future,
      );
      expect(
        first.currentLesson.routeId,
        FixtureLessonRepository.lesson19RouteId,
      );
      await harness.container
          .read(learnerJourneyControllerProvider.notifier)
          .recordLessonProgress(
            FixtureLessonRepository.lesson19RouteId,
            _completedProgress(),
          );
      await _waitFor(
        () =>
            harness.container
                .read(learningControllerProvider)
                .value
                ?.currentLesson
                .routeId ==
            FixtureLessonRepository.lesson20RouteId,
      );
      expect(
        harness.container
            .read(learningControllerProvider)
            .requireValue
            .currentLesson
            .routeId,
        FixtureLessonRepository.lesson20RouteId,
      );
    });

    testWidgets('4. Continue Learning opens the derived lesson route', (
      tester,
    ) async {
      final harness = await _pumpHome(tester, journey: _selectedJourney());
      await _pumpFrames(tester);
      await _scrollTo(
        tester,
        const ValueKey<String>('home_continue_learning_button'),
      );
      tester
          .widget<RikiPrimaryButton>(
            find.byKey(const ValueKey<String>('home_continue_learning_button')),
          )
          .onPressed!();
      await _pumpFrames(tester);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.lesson(FixtureLessonRepository.lesson19RouteId),
      );
      harness.dispose();
    });

    testWidgets('5. Missing explicit JLPT selection opens level selection', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: const LearnerJourneyState(),
      );
      await _pumpFrames(tester);
      expect(
        find.byKey(const ValueKey<String>('home_choose_jlpt_card')),
        findsOneWidget,
      );
      await tester.tap(find.text('Chọn mục tiêu'));
      await _pumpFrames(tester);
      expect(harness.router.routeInformationProvider.value.uri.path, '/learn');
      harness.dispose();
    });

    testWidgets('Completed fixture catalog opens the selected roadmap', (
      tester,
    ) async {
      final completedProgress = <String, LessonProgress>{
        for (final routeId in FixtureLessonRepository.orderedRouteIdsFor(
          JlptLevel.n4,
        ))
          routeId: _completedProgress(),
      };
      final harness = await _pumpHome(
        tester,
        journey: LearnerJourneyState(
          selectedLevel: JlptLevel.n4,
          hasSelectedLevel: true,
          lessonProgress: completedProgress,
        ),
      );
      await _pumpFrames(tester);
      const roadmapCardKey = ValueKey<String>('home_view_roadmap_card');
      final roadmapCard = find.byKey(roadmapCardKey);
      expect(roadmapCard, findsOneWidget);
      final roadmapLabel = tester.element(roadmapCard).l10n.viewRoadmap;
      await tester.tap(
        find.descendant(of: roadmapCard, matching: find.text(roadmapLabel)),
      );
      await _pumpFrames(tester);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.learnRoadmap,
      );
      harness.dispose();
    });

    test('6. Home never creates a backend JLPT identifier', () {
      final source = _homeAndLearningSource();
      expect(source, isNot(contains('jlptGoalId')));
      expect(source, isNot(contains('/api/JLPT')));
      expect(source, isNot(contains('backendJlptId')));
    });

    test('7. Local progress has no backend progress mutation', () {
      final source = _homeSource();
      expect(source, isNot(contains('ApiClient')));
      expect(source, isNot(contains('LessonProgressApiPaths')));
      expect(source, isNot(contains('updatePlaybackPosition')));
    });

    test(
      'Selecting the N4 preview explicitly persists the selection',
      () async {
        final repository = _MemoryJourneyRepository(
          const LearnerJourneyState(selectedLevel: JlptLevel.n4),
        );
        final harness = _ProviderHarness(
          ProviderContainer(
            overrides: [
              learnerJourneyRepositoryProvider.overrideWithValue(repository),
            ],
          ),
        );
        addTearDown(harness.dispose);

        await harness.container.read(learnerJourneyControllerProvider.future);
        await harness.container
            .read(learnerJourneyControllerProvider.notifier)
            .selectLevel(JlptLevel.n4);

        expect(
          harness.container
              .read(learnerJourneyControllerProvider)
              .requireValue
              .hasSelectedLevel,
          isTrue,
        );
        expect(repository.state.hasSelectedLevel, isTrue);
      },
    );
  });

  group('R4 Home analytics', () {
    test('8. Home references the existing Analytics controller', () {
      final source = File(
        'lib/features/home/presentation/home_screen.dart',
      ).readAsStringSync();
      expect(source, contains('learnerAnalyticsControllerProvider'));
      expect(source, isNot(contains('HomeAnalyticsRepository')));
    });

    testWidgets('9. Analytics loading does not block local Home sections', (
      tester,
    ) async {
      final pending = Completer<LearnerAnalytics>();
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        analytics: _TestAnalyticsRepository(future: pending.future),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('home_continue_learning_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home_analytics_loading')),
        findsOneWidget,
      );
      pending.complete(
        const LearnerAnalytics(
          streakDays: 0,
          completedLessons: 0,
          totalLessons: 0,
          skills: <SkillBreakdown>[],
        ),
      );
      await _pumpFrames(tester);
      harness.dispose();
    });

    testWidgets('10. Partial Analytics success keeps available metrics', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        analytics: const _TestAnalyticsRepository(
          data: LearnerAnalytics(
            streakDays: 6,
            completedLessons: 0,
            totalLessons: 0,
            skills: <SkillBreakdown>[
              SkillBreakdown(skill: 'Kanji', averageScore: 25, attemptCount: 8),
            ],
            unavailableSections: <AnalyticsSection>{
              AnalyticsSection.completion,
            },
          ),
        ),
      );
      await _pumpFrames(tester);
      await _scrollTo(tester, const ValueKey<String>('home_analytics_streak'));
      expect(
        find.byKey(const ValueKey<String>('home_analytics_streak')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home_analytics_skill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home_analytics_completion')),
        findsNothing,
      );
      harness.dispose();
    });

    testWidgets('11. Analytics total failure does not break Home navigation', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        analytics: _TestAnalyticsRepository(error: StateError('offline')),
      );
      await _pumpFrames(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await _scrollTo(
        tester,
        const ValueKey<String>('home_continue_learning_button'),
      );
      tester
          .widget<RikiPrimaryButton>(
            find.byKey(const ValueKey<String>('home_continue_learning_button')),
          )
          .onPressed!();
      await _pumpFrames(tester);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        startsWith('/learn/lesson/'),
      );
      harness.dispose();
    });

    testWidgets('12. View Progress uses the existing Analytics route', (
      tester,
    ) async {
      final harness = await _pumpHome(tester, journey: _selectedJourney());
      await _pumpFrames(tester);
      await _scrollToText(tester, 'Xem tiến độ');
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Xem tiến độ'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed!();
      await _pumpFrames(tester);
      expect(find.byType(LearnerAnalyticsScreen), findsOneWidget);
      expect(harness.router.canPop(), isTrue);
      await tester.binding.handlePopRoute();
      await _pumpFrames(tester);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.home,
      );
      harness.dispose();
    });

    testWidgets('Home displays the Backend streak without recalculating it', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        analytics: const _TestAnalyticsRepository(
          data: LearnerAnalytics(
            streakDays: 6,
            completedLessons: 0,
            totalLessons: 0,
            skills: <SkillBreakdown>[],
          ),
        ),
      );
      await _pumpFrames(tester);
      const streakKey = ValueKey<String>('home_analytics_streak');
      await _scrollTo(tester, streakKey);
      final streakCard = find.byKey(streakKey);
      final streakLabel = tester.element(streakCard).l10n.streakDaysValue(6);
      expect(
        find.descendant(of: streakCard, matching: find.text(streakLabel)),
        findsOneWidget,
      );
      expect(_homeSource(), isNot(contains('DateTime.now')));
      expect(_homeSource(), isNot(contains('.difference(')));
      harness.dispose();
    });
  });

  group('R4 Home practice and review', () {
    testWidgets('13. local Mock fixture does not leak into live Home CTA', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        sessions: _sessions(active: _activeAttempt()),
      );
      await _pumpFrames(tester);
      await _scrollTo(
        tester,
        const ValueKey<String>('home_start_practice_card'),
      );
      expect(
        find.byKey(const ValueKey<String>('home_start_practice_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home_resume_mock_card')),
        findsNothing,
      );
      harness.dispose();
    });

    testWidgets('14. expired local fixture does not alter live Home CTA', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        now: DateTime.utc(2026, 10, 3, 10),
        sessions: _sessions(
          active: _activeAttempt(startedAt: DateTime.utc(2026, 10, 3, 8)),
        ),
      );
      await _pumpFrames(tester);
      expect(
        find.byKey(const ValueKey<String>('home_resume_mock_card')),
        findsNothing,
      );
      await _scrollTo(
        tester,
        const ValueKey<String>('home_start_practice_card'),
      );
      expect(
        find.byKey(const ValueKey<String>('home_start_practice_card')),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('15. local score is not presented as a live result', (
      tester,
    ) async {
      final submitted = _activeAttempt().copyWith(
        status: DemoMockSessionStatus.submitted,
        submittedAt: DateTime.utc(2026, 10, 3, 9),
      );
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        sessions: _sessions(recent: submitted),
      );
      await _pumpFrames(tester);
      await _scrollTo(
        tester,
        const ValueKey<String>('home_start_practice_card'),
      );
      expect(
        find.byKey(const ValueKey<String>('home_recent_mock_card')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('home_start_practice_card')),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('16. Practice CTA always opens live discovery', (tester) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        sessions: _sessions(active: _activeAttempt()),
      );
      await _pumpFrames(tester);
      await _scrollToText(tester, 'Bắt đầu luyện tập');
      await tester.tap(find.text('Bắt đầu luyện tập'));
      await _pumpFrames(tester);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.practice,
      );
      harness.dispose();
    });

    test('17. Home has no live MockTest submission dependency', () {
      final source = _homeSource();
      expect(source, isNot(contains('MockTestApiPaths')));
      expect(source, isNot(contains('submitMockTest')));
      expect(source, isNot(contains('/api/MockTest')));
    });

    testWidgets('18. Daily Review CTA routes to the existing review screen', (
      tester,
    ) async {
      final harness = await _pumpHome(tester, journey: _selectedJourney());
      await _pumpFrames(tester);
      await _scrollToText(tester, 'Ôn tập ngay');
      await tester.tap(find.text('Ôn tập ngay'));
      await _pumpFrames(tester);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/practice/review',
      );
      harness.dispose();
    });

    test('19. Home does not infer a numeric Again quality', () {
      final source = _homeSource();
      expect(source, isNot(contains('DemoReviewAnswer.again')));
      expect(RegExp(r'again\s*[:=]>?\s*[12]').hasMatch(source), isFalse);
    });

    test('20. Home does not call the Review submit endpoint', () {
      expect(_homeSource(), isNot(contains('/api/Review/submit-result')));
    });

    testWidgets('21. Review card does not fabricate a live due count', (
      tester,
    ) async {
      final harness = await _pumpHome(tester, journey: _selectedJourney());
      await _pumpFrames(tester);
      await _scrollTo(tester, const ValueKey<String>('home_daily_review_card'));
      final card = find.byKey(const ValueKey<String>('home_daily_review_card'));
      expect(
        find.descendant(of: card, matching: find.textContaining('3 thẻ')),
        findsNothing,
      );
      harness.dispose();
    });

    testWidgets('An active live Review session displays Resume', (
      tester,
    ) async {
      const firstCard = DemoReviewCard(
        id: 'fixture-review-first',
        term: 'æœ',
        reading: 'ã‚ã•',
        meaning: 'buá»•i sÃ¡ng',
        contentType: 'Vocabulary',
      );
      const secondCard = DemoReviewCard(
        id: 'fixture-review-second',
        term: 'å­¦',
        reading: 'ãŒã',
        meaning: 'há»c',
        contentType: 'Kanji',
      );
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        sessions: const DemoPracticeSessions(
          reviewSession: DemoReviewSession(
            cards: <DemoReviewCard>[firstCard, secondCard],
            currentIndex: 1,
            responses: <DemoReviewResponse>[
              DemoReviewResponse(
                cardKey: 'fixture-review-first',
                answer: DemoReviewAnswer.good,
              ),
            ],
          ),
        ),
        dailyReviewRepository: _HomeDailyReviewRepository(
          cards: <DailyReviewCard>[_firstLiveReviewCard, _secondLiveReviewCard],
        ),
      );
      await harness.container.read(dailyReviewControllerProvider.future);
      final liveController = harness.container.read(
        dailyReviewControllerProvider.notifier,
      );
      liveController.revealAnswer();
      await liveController.submit(ReviewRating.good);
      await _pumpFrames(tester);
      const reviewKey = ValueKey<String>('home_daily_review_card');
      await _scrollTo(tester, reviewKey);
      final reviewCard = find.byKey(reviewKey);
      final resumeLabel = tester.element(reviewCard).l10n.homeResumeReview;
      expect(
        find.descendant(of: reviewCard, matching: find.text(resumeLabel)),
        findsOneWidget,
      );
      harness.dispose();
    });
  });

  group('R4 Home notifications and continuity', () {
    testWidgets('22. Header displays the live unread count', (tester) async {
      final notifications = _TestNotificationRepository(unreadCount: 3);
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        notifications: notifications,
      );
      await _pumpFrames(tester);
      final header = find.byType(HomeHeader);
      expect(
        find.descendant(
          of: header,
          matching: find.byKey(const Key('language_switcher_button')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byType(JlptBadge)),
        findsNothing,
      );
      expect(
        find.descendant(of: header, matching: find.byType(CircleAvatar)),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('home_notification_unread_badge')),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
      harness.dispose();
    });

    testWidgets('23. Mark read updates the Home badge reactively', (
      tester,
    ) async {
      final notifications = _TestNotificationRepository(unreadCount: 2);
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        notifications: notifications,
      );
      await _pumpFrames(tester);
      await harness.container
          .read(notificationControllerProvider.notifier)
          .markRead(notifications.items.first);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      harness.dispose();
    });

    testWidgets('24. Mark all read removes the unread badge', (tester) async {
      final notifications = _TestNotificationRepository(unreadCount: 2);
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        notifications: notifications,
      );
      await _pumpFrames(tester);
      await harness.container
          .read(notificationControllerProvider.notifier)
          .markAllRead();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('home_notification_unread_badge')),
        findsNothing,
      );
      harness.dispose();
    });

    testWidgets('25. Notification failure does not break Home', (tester) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        notifications: _TestNotificationRepository(
          error: StateError('offline'),
        ),
      );
      await _pumpFrames(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('home_continue_learning_card')),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('26. Completing a lesson updates Home without restart', (
      tester,
    ) async {
      final harness = await _pumpHome(tester, journey: _selectedJourney());
      await _pumpFrames(tester);
      expect(find.textContaining('Bài 19'), findsWidgets);
      await harness.container
          .read(learnerJourneyControllerProvider.notifier)
          .recordLessonProgress(
            FixtureLessonRepository.lesson19RouteId,
            _completedProgress(),
          );
      await _pumpFrames(tester);
      expect(find.textContaining('Bài 20'), findsWidgets);
      harness.dispose();
    });

    testWidgets('27. local Mock submission cannot masquerade as live result', (
      tester,
    ) async {
      final harness = await _pumpHome(tester, journey: _selectedJourney());
      await _pumpFrames(tester);
      final controller = harness.container.read(
        demoPracticeControllerProvider.notifier,
      );
      await controller.startMockTest();
      await controller.submitMockTest();
      await _pumpFrames(tester);
      await _scrollTo(
        tester,
        const ValueKey<String>('home_start_practice_card'),
      );
      expect(
        find.byKey(const ValueKey<String>('home_recent_mock_card')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('home_start_practice_card')),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('28. Live refresh preserves local learning progress', (
      tester,
    ) async {
      final journey = _MemoryJourneyRepository(
        _journeyWithFirstLessonCompleted(),
      );
      final harness = await _pumpHome(tester, journeyRepository: journey);
      await _pumpFrames(tester);
      await tester
          .widget<HomeDashboardView>(find.byType(HomeDashboardView))
          .onRefreshLive();
      await _pumpFrames(tester);
      expect(
        harness.container
            .read(learnerJourneyControllerProvider)
            .requireValue
            .isLessonCompleted(FixtureLessonRepository.lesson19RouteId),
        isTrue,
      );
      expect(journey.resetCalls, 0);
      harness.dispose();
    });

    testWidgets('29. Live refresh preserves an active practice attempt', (
      tester,
    ) async {
      final repository = _TestPracticeSessionRepository(
        _sessions(active: _activeAttempt()),
      );
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        sessionRepository: repository,
      );
      await _pumpFrames(tester);
      await tester
          .widget<HomeDashboardView>(find.byType(HomeDashboardView))
          .onRefreshLive();
      await _pumpFrames(tester);
      expect(
        harness.container
            .read(demoPracticeControllerProvider)
            .requireValue
            .hasActiveMockAttempt,
        isTrue,
      );
      expect(repository.resetCalls, 0);
      harness.dispose();
    });

    testWidgets('Live refresh preserves fixture bookmarks', (tester) async {
      final notebook = SessionDemoNotebookRepository();
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        notebookRepository: notebook,
      );
      await _pumpFrames(tester);
      await harness.container.read(demoNotebookControllerProvider.future);
      await harness.container
          .read(demoNotebookControllerProvider.notifier)
          .saveEntry(
            const NotebookFixtureDraft(
              stableKey: 'fixture-r4-bookmark',
              contentType: NotebookContentType.vocabulary,
              term: 'æœ',
              reading: 'ã‚ã•',
              meaning: 'buá»•i sÃ¡ng',
            ),
          );

      await tester
          .widget<HomeDashboardView>(find.byType(HomeDashboardView))
          .onRefreshLive();
      await _pumpFrames(tester);

      final entries = harness.container
          .read(demoNotebookControllerProvider)
          .requireValue
          .entries;
      expect(entries, hasLength(1));
      expect(entries.single.key.stableKey, 'fixture-r4-bookmark');
      expect(entries.single.origin, NotebookItemOrigin.fixture);
      harness.dispose();
    });

    testWidgets('30. Bottom-tab navigation preserves composed state', (
      tester,
    ) async {
      final harness = await _pumpHome(
        tester,
        journey: _selectedJourney(),
        sessions: _sessions(active: _activeAttempt()),
      );
      await _pumpFrames(tester);
      harness.router.go(AppRoutes.practice);
      await _pumpFrames(tester);
      harness.router.go(AppRoutes.home);
      await _pumpFrames(tester);
      await _scrollTo(
        tester,
        const ValueKey<String>('home_start_practice_card'),
      );
      expect(
        find.byKey(const ValueKey<String>('home_start_practice_card')),
        findsOneWidget,
      );
      expect(
        harness.container
            .read(demoPracticeControllerProvider)
            .requireValue
            .hasActiveMockAttempt,
        isTrue,
      );
      harness.dispose();
    });
  });
}

LearnerJourneyState _selectedJourney() => const LearnerJourneyState(
  selectedLevel: JlptLevel.n4,
  hasSelectedLevel: true,
);

LearnerJourneyState _journeyWithFirstLessonCompleted() => LearnerJourneyState(
  selectedLevel: JlptLevel.n4,
  hasSelectedLevel: true,
  lessonProgress: <String, LessonProgress>{
    FixtureLessonRepository.lesson19RouteId: _completedProgress(),
  },
);

LessonProgress _completedProgress() => LessonProgress(
  progressPercent: 100,
  resumePositionSeconds: 1200,
  isCompleted: true,
  completedAt: DateTime.utc(2026, 10, 3),
);

DemoMockAttempt _activeAttempt({DateTime? startedAt}) => DemoMockAttempt(
  testKey: 'fixture-mock-n4-01',
  localAttemptKey: 'local_fixture_test',
  startedAt: startedAt ?? DateTime.now().toUtc(),
  timeLimitMinutes: 25,
  status: DemoMockSessionStatus.inProgress,
);

DemoPracticeSessions _sessions({
  DemoMockAttempt? active,
  DemoMockAttempt? recent,
}) => DemoPracticeSessions(
  reviewSession: const DemoReviewSession(cards: <DemoReviewCard>[]),
  activeMockAttempt: active,
  recentMockAttempt: recent,
);

String _homeSource() => <String>[
  'lib/features/home/presentation/home_screen.dart',
  'lib/features/home/presentation/widgets/home_dashboard_view.dart',
].map((path) => File(path).readAsStringSync()).join('\n');

String _homeAndLearningSource() => <String>[
  _homeSource(),
  File(
    'lib/features/learning/application/learner_journey_controller.dart',
  ).readAsStringSync(),
].join('\n');

Future<void> _waitFor(bool Function() predicate) async {
  for (var index = 0; index < 30 && !predicate(); index++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await _pumpFrames(tester);
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await _pumpFrames(tester);
}

class _HomeHarness {
  _HomeHarness(this.container, this.router, this.session);

  final ProviderContainer container;
  final GoRouter router;
  final AuthSessionController session;

  void dispose() {
    router.dispose();
    session.dispose();
    container.dispose();
  }
}

class _ProviderHarness {
  _ProviderHarness(this.container);

  final ProviderContainer container;

  void dispose() => container.dispose();
}

_ProviderHarness _providerHarness({required LearnerJourneyState journey}) {
  return _ProviderHarness(
    ProviderContainer(
      overrides: [
        learnerJourneyRepositoryProvider.overrideWithValue(
          _MemoryJourneyRepository(journey),
        ),
        learningRepositoryProvider.overrideWithValue(
          const FixtureLearningRepository(),
        ),
        lessonRepositoryProvider.overrideWithValue(
          const FixtureLessonRepository(),
        ),
      ],
    ),
  );
}

Future<_HomeHarness> _pumpHome(
  WidgetTester tester, {
  LearnerJourneyState? journey,
  LearnerJourneyRepository? journeyRepository,
  AnalyticsRepository analytics = const _TestAnalyticsRepository(),
  NotificationRepository? notifications,
  DemoPracticeSessions? sessions,
  PracticeSessionRepository? sessionRepository,
  DailyReviewRepository dailyReviewRepository =
      const _HomeDailyReviewRepository(),
  DemoNotebookRepository? notebookRepository,
  DateTime? now,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final notificationRepository =
      notifications ?? _TestNotificationRepository(unreadCount: 0);
  final practiceRepository =
      sessionRepository ?? _TestPracticeSessionRepository(sessions);
  final container = ProviderContainer(
    overrides: [
      learnerJourneyRepositoryProvider.overrideWithValue(
        journeyRepository ??
            _MemoryJourneyRepository(journey ?? const LearnerJourneyState()),
      ),
      learningRepositoryProvider.overrideWithValue(
        const FixtureLearningRepository(),
      ),
      lessonRepositoryProvider.overrideWithValue(
        const FixtureLessonRepository(),
      ),
      analyticsRepositoryProvider.overrideWithValue(analytics),
      notificationRepositoryProvider.overrideWithValue(notificationRepository),
      practiceSessionRepositoryProvider.overrideWithValue(practiceRepository),
      dailyReviewRepositoryProvider.overrideWithValue(dailyReviewRepository),
      if (notebookRepository != null)
        demoNotebookRepositoryProvider.overrideWithValue(notebookRepository),
      if (now != null) practiceNowProvider.overrideWithValue(() => now),
    ],
  );
  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.home,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return _HomeHarness(container, router, session);
}

class _MemoryJourneyRepository implements LearnerJourneyRepository {
  _MemoryJourneyRepository(this.state);

  LearnerJourneyState state;
  int resetCalls = 0;

  @override
  Future<LearnerJourneyState> load() async => state;

  @override
  Future<void> save(LearnerJourneyState state) async {
    this.state = state;
  }

  @override
  Future<void> reset() async {
    resetCalls++;
    state = const LearnerJourneyState();
  }
}

class _TestAnalyticsRepository implements AnalyticsRepository {
  const _TestAnalyticsRepository({
    this.data = const LearnerAnalytics(
      streakDays: 4,
      completedLessons: 7,
      totalLessons: 20,
      skills: <SkillBreakdown>[],
    ),
    this.error,
    this.future,
  });

  final LearnerAnalytics data;
  final Object? error;
  final Future<LearnerAnalytics>? future;

  @override
  Future<LearnerAnalytics> loadLearnerAnalytics() async {
    if (future != null) return future!;
    if (error != null) throw error!;
    return data;
  }
}

class _TestNotificationRepository implements NotificationRepository {
  _TestNotificationRepository({this.unreadCount = 0, this.error})
    : items = List<AppNotification>.generate(
        unreadCount,
        (index) => AppNotification(
          id: index + 1,
          title: 'Notification ${index + 1}',
          message: 'Message',
          type: 'General',
          isRead: false,
          createdAt: DateTime.utc(2026, 10, 3),
        ),
      );

  final int unreadCount;
  final Object? error;
  final List<AppNotification> items;

  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async {
    if (error != null) throw error!;
    return items;
  }

  @override
  Future<int> loadUnreadCount() async {
    if (error != null) throw error!;
    return unreadCount;
  }

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

class _TestPracticeSessionRepository implements PracticeSessionRepository {
  _TestPracticeSessionRepository(this.sessions);

  DemoPracticeSessions? sessions;
  int resetCalls = 0;

  @override
  Future<DemoPracticeSessions?> load({
    required List<DemoReviewCard> reviewCards,
    required DemoMockTest mockTest,
  }) async {
    final current = sessions;
    if (current == null) {
      return DemoPracticeSessions(
        reviewSession: DemoReviewSession(cards: reviewCards),
      );
    }
    return DemoPracticeSessions(
      reviewSession: current.reviewSession.cards.isEmpty
          ? DemoReviewSession(cards: reviewCards)
          : current.reviewSession,
      activeMockAttempt: current.activeMockAttempt,
      recentMockAttempt: current.recentMockAttempt,
    );
  }

  @override
  Future<void> save(DemoPracticeSessions sessions) async {
    this.sessions = sessions;
  }

  @override
  Future<void> reset() async {
    resetCalls++;
    sessions = null;
  }
}

class _HomeDailyReviewRepository implements DailyReviewRepository {
  const _HomeDailyReviewRepository({this.cards = const <DailyReviewCard>[]});

  final List<DailyReviewCard> cards;

  @override
  Future<DailyReviewQueue> loadDailyQueue() async {
    return DailyReviewQueue(totalDue: cards.length, items: cards);
  }

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) async {
    return DailyReviewSubmitResult(
      reviewCardId: reviewCardId,
      qualitySubmitted: quality,
      shouldRepeatInSession: false,
      newEaseFactor: 2.5,
      newIntervalDays: 1,
      repetitions: 1,
      nextReviewDate: DateTime.utc(2026, 10, 22),
    );
  }
}

final DailyReviewCard _firstLiveReviewCard = DailyReviewCard(
  reviewCardId: 481,
  contentType: DailyReviewContentType.vocabulary,
  term: '朝',
  reading: 'あさ',
  meaning: 'buổi sáng',
  note: null,
  repetitions: 0,
  nextReviewDate: DateTime.utc(2026, 10, 21),
);

final DailyReviewCard _secondLiveReviewCard = DailyReviewCard(
  reviewCardId: 482,
  contentType: DailyReviewContentType.kanji,
  term: '学',
  reading: 'がく',
  meaning: 'học',
  note: null,
  repetitions: 0,
  nextReviewDate: DateTime.utc(2026, 10, 21),
);
