import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/data/fixture_demo_practice_repository.dart';
import 'package:rikipath_mobile/features/practice/data/persistent_practice_session_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/review_quality.dart';
import 'package:rikipath_mobile/features/practice/presentation/daily_review_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_result_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_json_preference_store.dart';
import '../../support/test_live_mock_data.dart';

void main() {
  group('Daily Review hardening', () {
    test('1. review card initially hides answer', () async {
      final harness = await _createHarness();
      expect(harness.state.isReviewAnswerVisible, isFalse);
      expect(harness.state.currentReviewCard, isNotNull);
    });

    test('2. reveal shows answer', () async {
      final harness = await _createHarness();
      await harness.controller.revealReviewAnswer();
      expect(harness.value.isReviewAnswerVisible, isTrue);
    });

    for (final entry in <(int, DemoReviewAnswer)>[
      (3, DemoReviewAnswer.again),
      (4, DemoReviewAnswer.hard),
      (5, DemoReviewAnswer.good),
      (6, DemoReviewAnswer.easy),
    ]) {
      test('${entry.$1}. ${entry.$2.name} advances locally', () async {
        final harness = await _createHarness();
        await harness.controller.revealReviewAnswer();
        await harness.controller.answerReview(entry.$2);
        expect(harness.value.reviewIndex, 1);
        expect(harness.value.reviewAnswers, <DemoReviewAnswer>[entry.$2]);
        expect(harness.value.isReviewAnswerVisible, isFalse);
      });
    }

    test('7. completion summary counts semantic responses correctly', () {
      final cards = List<DemoReviewCard>.generate(
        4,
        (index) => DemoReviewCard(
          id: 'fixture-card-$index',
          term: '語$index',
          reading: null,
          meaning: 'meaning $index',
          contentType: 'Vocabulary',
        ),
      );
      final session = DemoReviewSession(
        cards: cards,
        currentIndex: cards.length,
        responses: <DemoReviewResponse>[
          DemoReviewResponse(
            cardKey: cards[0].id,
            answer: DemoReviewAnswer.again,
          ),
          DemoReviewResponse(
            cardKey: cards[1].id,
            answer: DemoReviewAnswer.hard,
          ),
          DemoReviewResponse(
            cardKey: cards[2].id,
            answer: DemoReviewAnswer.good,
          ),
          DemoReviewResponse(
            cardKey: cards[3].id,
            answer: DemoReviewAnswer.easy,
          ),
        ],
      );
      expect(session.isComplete, isTrue);
      for (final answer in DemoReviewAnswer.values) {
        expect(session.count(answer), 1);
      }
    });

    test('8. live review integration uses the backend Review endpoints', () {
      final source = _practiceSource();
      expect(source, contains('/api/Review/daily-queue'));
      expect(source, contains('/api/Review/submit-result'));
    });

    test('9. semantic actions map to the confirmed backend qualities', () {
      expect(ReviewRating.again.quality, 1);
      expect(ReviewRating.hard.quality, 3);
      expect(ReviewRating.good.quality, 4);
      expect(ReviewRating.easy.quality, 5);
    });

    testWidgets('10. empty queue renders safely', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jsonPreferenceStoreProvider.overrideWithValue(
              TestJsonPreferenceStore(),
            ),
            dailyReviewRepositoryProvider.overrideWithValue(
              const _DailyReviewRepository(empty: true),
            ),
          ],
          child: _localizedApp(const DailyReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay chưa có thẻ cần ôn.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test(
      '11. network failure does not silently become fixture success',
      () async {
        final container = ProviderContainer(
          overrides: [
            jsonPreferenceStoreProvider.overrideWithValue(
              TestJsonPreferenceStore(),
            ),
            demoPracticeRepositoryProvider.overrideWithValue(
              const _FailingReviewRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);
        await expectLater(
          container.read(demoPracticeControllerProvider.future),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Mock Test hardening', () {
    test('12. starting test creates a local attempt', () async {
      final harness = await _createHarness();
      await harness.controller.startMockTest();
      expect(harness.value.mockAttempt, isNotNull);
      expect(harness.value.mockAttempt!.localAttemptKey, startsWith('local_'));
      expect(
        harness.value.mockAttempt!.status,
        DemoMockSessionStatus.inProgress,
      );
    });

    test('13. selecting answer persists within session', () async {
      final harness = await _startedHarness();
      final question = harness.value.mockTest.questions.first;
      await harness.controller.selectMockAnswer(
        question.id,
        question.options.first.id,
      );
      expect(
        harness.value.mockAttempt!.answers[question.id],
        question.options.first.id,
      );
    });

    test('14. changing answer works before submit', () async {
      final harness = await _startedHarness();
      final question = harness.value.mockTest.questions.first;
      await harness.controller.selectMockAnswer(
        question.id,
        question.options.first.id,
      );
      await harness.controller.selectMockAnswer(
        question.id,
        question.options.last.id,
      );
      expect(
        harness.value.mockAttempt!.answers[question.id],
        question.options.last.id,
      );
      expect(harness.value.mockAttempt!.answers, hasLength(1));
    });

    test('15. next and previous preserve answers', () async {
      final harness = await _startedHarness();
      final question = harness.value.mockTest.questions.first;
      await harness.controller.selectMockAnswer(
        question.id,
        question.correctOptionId,
      );
      await harness.controller.showMockQuestion(1);
      await harness.controller.showMockQuestion(0);
      expect(harness.value.currentMockQuestionIndex, 0);
      expect(
        harness.value.mockAttempt!.answers[question.id],
        question.correctOptionId,
      );
    });

    test('16. timer does not reset on controller reconstruction', () async {
      final store = TestJsonPreferenceStore();
      final clock = _MutableClock(DateTime.utc(2026, 10, 2, 10));
      final first = await _createHarness(store: store, clock: clock);
      await first.controller.startMockTest();
      final startedAt = first.value.mockAttempt!.startedAt;
      first.dispose();
      clock.value = clock.value.add(const Duration(minutes: 3));
      final restored = await _createHarness(store: store, clock: clock);
      expect(restored.value.mockAttempt!.startedAt, startedAt);
      expect(
        restored.value.mockAttempt!.deadline,
        startedAt.add(const Duration(minutes: 25)),
      );
    });

    test(
      '17. persisted active attempt restores after reconstruction',
      () async {
        final store = TestJsonPreferenceStore();
        final first = await _startedHarness(store: store);
        final question = first.value.mockTest.questions.first;
        await first.controller.selectMockAnswer(
          question.id,
          question.correctOptionId,
        );
        await first.controller.showMockQuestion(1);
        first.dispose();
        final restored = await _createHarness(store: store);
        expect(restored.value.hasActiveMockAttempt, isTrue);
        expect(restored.value.currentMockQuestionIndex, 1);
        expect(
          restored.value.mockAttempt!.answers[question.id],
          question.correctOptionId,
        );
      },
    );

    test('18. elapsed wall-clock time is subtracted after restore', () async {
      final store = TestJsonPreferenceStore();
      final clock = _MutableClock(DateTime.utc(2026, 10, 2, 10));
      final first = await _startedHarness(store: store, clock: clock);
      first.dispose();
      clock.value = clock.value.add(const Duration(minutes: 7));
      final restored = await _createHarness(store: store, clock: clock);
      expect(
        restored.value.remainingMockTime(clock.value),
        const Duration(minutes: 18),
      );
    });

    test('19. expired restored attempt finalizes safely', () async {
      final store = TestJsonPreferenceStore();
      final clock = _MutableClock(DateTime.utc(2026, 10, 2, 10));
      final first = await _startedHarness(store: store, clock: clock);
      first.dispose();
      clock.value = clock.value.add(const Duration(minutes: 26));
      final restored = await _createHarness(store: store, clock: clock);
      expect(restored.value.hasActiveMockAttempt, isFalse);
      expect(
        restored.value.mockAttempt?.status,
        DemoMockSessionStatus.submitted,
      );
      expect(restored.value.mockResult, isNotNull);
    });

    test('20. submit performs deterministic local scoring only', () async {
      final harness = await _startedHarness();
      final question = harness.value.mockTest.questions.first;
      await harness.controller.selectMockAnswer(
        question.id,
        question.correctOptionId,
      );
      await harness.controller.submitMockTest();
      expect(harness.value.mockResult?.score, 1);
      expect(harness.value.mockResult?.total, 2);
      expect(harness.value.mockResult?.percentage, 50);
    });

    test('21. fixture IDs never reach live MockTest API', () {
      final source = _practiceSource();
      expect(source, isNot(contains('MockTestApiPaths')));
      expect(source, isNot(contains('/api/MockTest/')));
    });

    test('22. partial and unanswered scoring is deterministic', () async {
      final harness = await _startedHarness();
      final firstQuestion = harness.value.mockTest.questions.first;
      await harness.controller.selectMockAnswer(
        firstQuestion.id,
        firstQuestion.correctOptionId,
      );
      await harness.controller.submitMockTest();
      final result = harness.value.mockResult!;
      expect(result.score, 1);
      expect(result.total, harness.value.mockTest.questions.length);
      expect(result.sectionScores.values.reduce((a, b) => a + b), 1);
    });

    test('23. result score and section totals are correct', () async {
      final harness = await _startedHarness();
      for (final question in harness.value.mockTest.questions) {
        await harness.controller.selectMockAnswer(
          question.id,
          question.correctOptionId,
        );
      }
      await harness.controller.submitMockTest();
      final result = harness.value.mockResult!;
      expect(result.score, result.total);
      expect(result.percentage, 100);
      expect(result.sectionTotals.values.reduce((a, b) => a + b), result.total);
    });

    testWidgets('24. detailed review shows selected and correct answers', (
      tester,
    ) async {
      final container = await _createLiveContainer(submitted: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _localizedApp(
            MockTestDetailedReviewScreen(
              testId: testLiveMockSummary.id.toString(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn chọn:'), findsWidgets);
      expect(find.textContaining('Đáp án đúng:'), findsWidgets);
    });

    testWidgets('25. detailed review route is not auto-popped', (tester) async {
      final routeHarness = await _createSubmittedRouteHarness(tester);
      routeHarness.router.go(
        AppRoutes.mockTestDetailedReview(routeHarness.testId),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MockTestDetailedReviewScreen), findsOneWidget);
    });

    testWidgets('26. back from Detailed Review returns to Result', (
      tester,
    ) async {
      final routeHarness = await _createSubmittedRouteHarness(tester);
      routeHarness.router.go(AppRoutes.mockTestResult(routeHarness.testId));
      await tester.pumpAndSettle();
      routeHarness.router.push(
        AppRoutes.mockTestDetailedReview(routeHarness.testId),
      );
      await tester.pumpAndSettle();
      routeHarness.router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(MockTestResultScreen), findsOneWidget);
    });

    test('27. retake creates a fresh local attempt', () async {
      final harness = await _startedHarness();
      final firstKey = harness.value.mockAttempt!.localAttemptKey;
      await harness.controller.submitMockTest();
      await harness.controller.prepareMockRetake();
      await harness.controller.startMockTest();
      expect(harness.value.mockAttempt!.localAttemptKey, isNot(firstKey));
      expect(harness.value.hasRecentMockResult, isTrue);
    });

    test('28. retake clears old answers', () async {
      final harness = await _startedHarness();
      final question = harness.value.mockTest.questions.first;
      await harness.controller.selectMockAnswer(
        question.id,
        question.correctOptionId,
      );
      await harness.controller.submitMockTest();
      await harness.controller.prepareMockRetake();
      await harness.controller.startMockTest();
      expect(harness.value.mockAttempt!.answers, isEmpty);
      expect(harness.value.currentMockQuestionIndex, 0);
    });

    test('29. malformed persisted attempt falls back safely', () async {
      final store = TestJsonPreferenceStore(
        initialValues: <String, String>{
          PersistentPracticeSessionRepository.storageKey:
              '{"activeMockAttempt":"invalid"}',
        },
      );
      final harness = await _createHarness(store: store);
      expect(harness.value.mockAttempt, isNull);
      expect(harness.value.mockResult, isNull);
      expect(
        store.values[PersistentPracticeSessionRepository.storageKey],
        isNull,
      );
    });

    test('30. submitted recent result restores', () async {
      final store = TestJsonPreferenceStore();
      final first = await _startedHarness(store: store);
      final question = first.value.mockTest.questions.first;
      await first.controller.selectMockAnswer(
        question.id,
        question.correctOptionId,
      );
      await first.controller.submitMockTest();
      final expectedKey = first.value.mockResultAttempt!.localAttemptKey;
      first.dispose();
      final restored = await _createHarness(store: store);
      expect(restored.value.hasRecentMockResult, isTrue);
      expect(restored.value.mockResultAttempt!.localAttemptKey, expectedKey);
      expect(restored.value.mockResult?.score, 1);
    });
  });

  group('Live mutation safety', () {
    test('31. fixture submit never invokes ApiClient or API repository', () {
      final controller = File(
        'lib/features/practice/application/demo_practice_controller.dart',
      ).readAsStringSync();
      expect(controller, isNot(contains('ApiClient')));
      expect(controller, isNot(contains('ApiMockTestRepository')));
    });

    test('32. fixture review buttons never invoke Review submit endpoint', () {
      final controller = File(
        'lib/features/practice/application/demo_practice_controller.dart',
      ).readAsStringSync();
      expect(controller, isNot(contains('ReviewApiPaths')));
      expect(controller, isNot(contains('submit-result')));
    });

    test('33. no backend attemptId is fabricated', () {
      final source = _practiceSource();
      expect(source, isNot(contains('backendAttemptId')));
      expect(source, isNot(contains('attemptId:')));
      expect(source, contains('localAttemptKey'));
    });

    test('34. fixture review does not infer backend quality from Again', () {
      final controller = File(
        'lib/features/practice/application/demo_practice_controller.dart',
      ).readAsStringSync();
      expect(controller, isNot(contains('quality')));
      expect(controller, isNot(contains('ReviewRating')));
    });

    test('35. fixture identities stay inside local persistence', () {
      final persistence = File(
        'lib/features/practice/data/persistent_practice_session_repository.dart',
      ).readAsStringSync();
      expect(persistence, isNot(contains('ApiClient')));
      expect(persistence, isNot(contains('/api/')));
      expect(persistence, contains('localAttemptKey'));
    });

    testWidgets('36. submit confirmation opens result exactly once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = await _createLiveContainer();
      container.read(mockTestControllerProvider.notifier).showQuestion(1);
      final session = createTestAuthSession();
      final router = createAppRouter(
        authSession: session,
        initialLocation: AppRoutes.mockTest(testLiveMockSummary.id.toString()),
      );
      addTearDown(session.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MockTestScreen), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('mock_test_submit_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Nộp bài'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MockTestResultScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('mock_test_result_view')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('R7 responsive presentation', () {
    testWidgets('37. semantic review actions fit a 320px phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          dailyReviewRepositoryProvider.overrideWithValue(
            const _DailyReviewRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(dailyReviewControllerProvider.future);
      container.read(dailyReviewControllerProvider.notifier).revealAnswer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _localizedApp(const DailyReviewScreen()),
        ),
      );
      await tester.pump();

      for (final answer in ReviewRating.values) {
        expect(
          find.byKey(ValueKey<String>('review_answer_${answer.name}')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('38. result hierarchy fits a 320px phone', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = await _createLiveContainer(submitted: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _localizedApp(
            MockTestResultScreen(testId: testLiveMockSummary.id.toString()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('mock_test_result_view')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

class _PracticeHarness {
  _PracticeHarness(this.container, this.controller, this.state);

  final ProviderContainer container;
  final DemoPracticeController controller;
  final DemoPracticeState state;
  bool _isDisposed = false;

  DemoPracticeState get value =>
      container.read(demoPracticeControllerProvider).requireValue;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    container.dispose();
  }
}

class _RouteHarness {
  const _RouteHarness(this.router, this.testId);

  final GoRouter router;
  final String testId;
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;
}

Future<_PracticeHarness> _createHarness({
  TestJsonPreferenceStore? store,
  _MutableClock? clock,
}) async {
  final container = ProviderContainer(
    overrides: [
      jsonPreferenceStoreProvider.overrideWithValue(
        store ?? TestJsonPreferenceStore(),
      ),
      if (clock != null) practiceNowProvider.overrideWithValue(clock.call),
    ],
  );
  final state = await container.read(demoPracticeControllerProvider.future);
  final controller = container.read(demoPracticeControllerProvider.notifier);
  final harness = _PracticeHarness(container, controller, state);
  addTearDown(harness.dispose);
  return harness;
}

Future<_PracticeHarness> _startedHarness({
  TestJsonPreferenceStore? store,
  _MutableClock? clock,
}) async {
  final harness = await _createHarness(store: store, clock: clock);
  await harness.controller.startMockTest();
  return harness;
}

Future<_RouteHarness> _createSubmittedRouteHarness(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = await _createLiveContainer(submitted: true);
  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.practice,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _RouteHarness(router, testLiveMockSummary.id.toString());
}

Future<ProviderContainer> _createLiveContainer({bool submitted = false}) async {
  final container = ProviderContainer(
    overrides: [
      mockTestRepositoryProvider.overrideWithValue(
        TestLiveMockTestRepository(),
      ),
      userProfileRepositoryProvider.overrideWithValue(
        const TestMockProfileRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(mockTestControllerProvider.future);
  final controller = container.read(mockTestControllerProvider.notifier);
  controller.selectTest(testLiveMockSummary.id);
  await controller.startSelectedTest();
  if (submitted) await controller.submit();
  return container;
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    home: home,
  );
}

String _practiceSource() {
  final buffer = StringBuffer();
  for (final entity in Directory(
    'lib/features/practice',
  ).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      buffer.writeln(entity.readAsStringSync());
    }
  }
  return buffer.toString();
}

class _EmptyReviewRepository implements DemoPracticeRepository {
  const _EmptyReviewRepository();

  FixtureDemoPracticeRepository get _delegate =>
      const FixtureDemoPracticeRepository();

  @override
  Future<List<DemoReviewCard>> loadReviewQueue() async =>
      const <DemoReviewCard>[];

  @override
  Future<DemoMockTest> loadMockTest() => _delegate.loadMockTest();

  @override
  Future<DemoAiGradingResult> gradeSubmission(String text) =>
      _delegate.gradeSubmission(text);

  @override
  Future<List<DemoMentorPlan>> loadMentorPlans() => _delegate.loadMentorPlans();

  @override
  Future<List<DemoMentorSlot>> loadMentorSlots() => _delegate.loadMentorSlots();
}

class _FailingReviewRepository extends _EmptyReviewRepository {
  const _FailingReviewRepository();

  @override
  Future<List<DemoReviewCard>> loadReviewQueue() {
    throw StateError('Live review queue failed.');
  }
}

class _DailyReviewRepository implements DailyReviewRepository {
  const _DailyReviewRepository({this.empty = false});

  final bool empty;

  @override
  Future<DailyReviewQueue> loadDailyQueue() async {
    if (empty) {
      return const DailyReviewQueue(totalDue: 0, items: <DailyReviewCard>[]);
    }
    return DailyReviewQueue(
      totalDue: 1,
      items: <DailyReviewCard>[
        DailyReviewCard(
          reviewCardId: 481,
          contentType: DailyReviewContentType.vocabulary,
          term: '学ぶ',
          reading: 'まなぶ',
          meaning: 'học',
          note: null,
          repetitions: 0,
          nextReviewDate: DateTime.utc(2026, 10, 21),
        ),
      ],
    );
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
