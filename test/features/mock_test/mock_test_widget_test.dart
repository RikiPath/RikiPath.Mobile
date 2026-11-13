import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/mock_test_library_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_json_preference_store.dart';
import '../../support/test_live_mock_data.dart';

void main() {
  testWidgets(
    'Practice Home shows navigation without seed tests or demo grading',
    (tester) async {
      final container = _container(_CatalogRepository());
      addTearDown(container.dispose);
      await _pump(tester, container, const PracticeScreen());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('practice_mock_library_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('practice_essay_writing_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('practice_daily_review_card')),
        findsOneWidget,
      );
      expect(find.text('Luyện tập theo nhịp của bạn'), findsNothing);
      expect(find.text('Chiến lược ôn luyện'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('ai_grading_submit_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('demo_checkout_button')),
        findsNothing,
      );
      expect(find.textContaining('MOCK-SEED'), findsNothing);
    },
  );

  for (final width in <double>[360, 393, 412]) {
    for (final scale in <double>[1.3, 2]) {
      testWidgets('Practice and exam library fit ${width}dp at ${scale}x', (
        tester,
      ) async {
        final container = _container(_CatalogRepository());
        addTearDown(container.dispose);
        await _settleProviders(container);

        await _pump(
          tester,
          container,
          const PracticeScreen(),
          width: width,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await _pump(
          tester,
          container,
          const MockTestLibraryScreen(),
          width: width,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('mock_level_N3')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Japanese Practice and library labels fit at 2x', (tester) async {
    final container = _container(_CatalogRepository());
    addTearDown(container.dispose);
    await _settleProviders(container);
    await _pump(
      tester,
      container,
      const PracticeScreen(),
      width: 393,
      textScale: 2,
      locale: const Locale('ja'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      container,
      const MockTestLibraryScreen(),
      width: 393,
      textScale: 2,
      locale: const Locale('ja'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('available test loading state is controlled', (tester) async {
    final completer = Completer<List<LiveMockTestSummary>>();
    final repository = _CatalogRepository(completer: completer);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(demoPracticeControllerProvider.future);

    await _pump(tester, container, const MockTestLibraryScreen());

    expect(
      find.byKey(const ValueKey<String>('mock_test_library_loading')),
      findsOneWidget,
    );
    completer.complete(const <LiveMockTestSummary>[]);
    await tester.pump();
  });

  testWidgets('empty published catalog renders without fixture fallback', (
    tester,
  ) async {
    final container = _container(_CatalogRepository(tests: const []));
    addTearDown(container.dispose);
    await _settleProviders(container);

    await _pump(tester, container, const MockTestLibraryScreen());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('mock_test_library_empty')),
      findsOneWidget,
    );
    expect(find.text('N3 Live Test'), findsNothing);
  });

  testWidgets('catalog error renders retry state instead of raw exception', (
    tester,
  ) async {
    final container = _container(
      _CatalogRepository(error: const NetworkError()),
    );
    addTearDown(container.dispose);
    await container.read(demoPracticeControllerProvider.future);
    await expectLater(
      container.read(mockTestControllerProvider.future),
      throwsA(isA<NetworkError>()),
    );

    await _pump(tester, container, const MockTestLibraryScreen());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('mock_test_library_error')),
      findsOneWidget,
    );
    expect(find.textContaining('NetworkError'), findsNothing);
  });

  testWidgets('library remains available without a target level', (
    tester,
  ) async {
    final container = _container(
      _CatalogRepository(),
      profile: const TestMockProfileRepository(targetLevelId: null),
    );
    addTearDown(container.dispose);
    await _settleProviders(container);

    await _pump(tester, container, const MockTestLibraryScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('mock_level_N3')), findsOneWidget);
  });

  testWidgets('published test group uses live ID and metadata', (tester) async {
    final container = _container(_CatalogRepository());
    addTearDown(container.dispose);
    await _settleProviders(container);

    await _pump(tester, container, const MockTestLibraryScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('mock_level_N3')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('mock_library_test_731')),
      findsOneWidget,
    );
    expect(find.text('N3 Live Test'), findsOneWidget);
    expect(find.textContaining('45'), findsOneWidget);
  });

  testWidgets('question and options render and select by backend IDs', (
    tester,
  ) async {
    final container = _container(_CatalogRepository());
    addTearDown(container.dispose);
    await _settleProviders(container);
    final controller = container.read(mockTestControllerProvider.notifier);
    controller.selectTest(731);
    await controller.startSelectedTest();

    await _pump(tester, container, const MockTestScreen(testId: '731'));

    expect(
      find.byKey(const ValueKey<String>('mock_test_question_view')),
      findsOneWidget,
    );
    expect(find.text('Choose the correct answer.'), findsOneWidget);
    expect(find.text('Correct answer'), findsOneWidget);
    expect(find.text('Other answer'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('mock_option_4402')));
    await tester.pump();

    final state = container.read(mockTestControllerProvider).requireValue;
    expect(state.attempt?.answers, <int, int>{1201: 4402});
  });
}

ProviderContainer _container(
  MockTestRepository repository, {
  TestMockProfileRepository profile = const TestMockProfileRepository(),
}) {
  return ProviderContainer(
    overrides: [
      mockTestRepositoryProvider.overrideWithValue(repository),
      jlptCatalogRepositoryProvider.overrideWithValue(
        const _SingleLevelCatalog(),
      ),
      userProfileRepositoryProvider.overrideWithValue(profile),
      jsonPreferenceStoreProvider.overrideWithValue(TestJsonPreferenceStore()),
      dailyReviewRepositoryProvider.overrideWithValue(
        const _EmptyDailyReviewRepository(),
      ),
    ],
  );
}

class _SingleLevelCatalog implements JlptCatalogRepository {
  const _SingleLevelCatalog();

  @override
  Future<List<JlptLevelCatalogItem>> loadLevels() async => const [
    JlptLevelCatalogItem(id: 3, code: 'N3', level: JlptLevel.n3, sortOrder: 3),
  ];
}

Future<void> _settleProviders(ProviderContainer container) async {
  await Future.wait<Object?>([
    container.read(demoPracticeControllerProvider.future),
    container.read(dailyReviewControllerProvider.future),
    container.read(mockTestControllerProvider.future),
  ]);
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget home, {
  double width = 393,
  double textScale = 1,
  Locale locale = const Locale('vi'),
}) async {
  tester.view.physicalSize = Size(width, 873);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
}

class _CatalogRepository extends TestLiveMockTestRepository {
  _CatalogRepository({super.tests, this.completer, this.error});

  final Completer<List<LiveMockTestSummary>>? completer;
  final Object? error;

  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async {
    if (error != null) throw error!;
    return completer?.future ?? super.loadTestsByLevel(jlptLevelId);
  }
}

class _EmptyDailyReviewRepository implements DailyReviewRepository {
  const _EmptyDailyReviewRepository();

  @override
  Future<DailyReviewQueue> loadDailyQueue() async {
    return const DailyReviewQueue(totalDue: 0, items: <DailyReviewCard>[]);
  }

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) {
    throw UnsupportedError('The empty queue cannot be submitted.');
  }
}
