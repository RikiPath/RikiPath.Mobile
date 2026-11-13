import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_library_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_display_title.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/mock_test_library_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  test('known seed title is hidden without changing the server ID', () {
    expect(
      mockTestDisplayTitle('[MOCK-SEED-v1] JLPT N5 – Đề kiểm thử 01'),
      'JLPT N5 — Đề thi thử 01',
    );
    expect(
      mockTestDisplayTitle(
        '[MOCK-SEED-v1] JLPT N5 – Đề kiểm thử 01',
        japanese: true,
      ),
      'JLPT N5 — 模擬試験 01',
    );
    expect(
      mockTestDisplayTitle('Đề ôn luyện chính thức'),
      'Đề ôn luyện chính thức',
    );
  });

  test('compact display title strips redundant JLPT level for exam hub', () {
    expect(
      mockTestDisplayTitle(
        '[MOCK-SEED-v1] JLPT N5 – Đề kiểm thử 01',
        compact: true,
      ),
      'Đề thi thử 01',
    );
    expect(
      mockTestDisplayTitle('Đề thi thử JLPT N5 - Đề số 1', compact: true),
      'Đề thi thử 01',
    );
    expect(
      mockTestDisplayTitle('JLPT N5 — Đề thi thử 02', compact: true),
      'Đề thi thử 02',
    );
    expect(
      mockTestDisplayTitle(
        'Đề thi thử JLPT N5 - Đề số 1',
        compact: true,
        japanese: true,
      ),
      '模擬試験 01',
    );
    expect(
      mockTestDisplayTitle('Đề ôn luyện chính thức', compact: true),
      'Đề ôn luyện chính thức',
    );
  });

  test('library groups only levels with published Backend tests', () async {
    final repository = _LibraryRepository();
    final container = ProviderContainer(
      overrides: [
        jlptCatalogRepositoryProvider.overrideWithValue(const _Levels()),
        mockTestRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final groups = await container.read(mockTestLibraryProvider.future);

    expect(repository.requestedIds, containsAll(<int>[5, 4, 3]));
    expect(groups.map((group) => group.level.code), <String>['N5', 'N3']);
    expect(groups.first.tests.single.id, 731);
    expect(groups.last.tests.single.id, 733);
  });

  testWidgets(
    'Exam Hub renders Level Selector, Overview Card, and Compact Exam List',
    (tester) async {
      final repository = _MultiExamRepository();
      final container = ProviderContainer(
        overrides: [
          jlptCatalogRepositoryProvider.overrideWithValue(const _Levels()),
          mockTestRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MockTestLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check level selector tabs
      expect(
        find.byKey(const ValueKey<String>('mock_level_N5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mock_level_N3')),
        findsOneWidget,
      );

      // Check overview card displays JLPT N5 and available count
      expect(find.text('JLPT N5'), findsWidgets);
      expect(find.textContaining('2 đề khả dụng'), findsOneWidget);

      // Check compact exam list displays index '01' and clean title 'Đề thi thử 01'
      expect(
        find.byKey(const ValueKey<String>('mock_library_test_731')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mock_library_test_732')),
        findsOneWidget,
      );
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('Đề thi thử 01'), findsOneWidget);
      expect(find.text('Đề thi thử 02'), findsOneWidget);

      // Switch to N3 level
      await tester.tap(find.byKey(const ValueKey<String>('mock_level_N3')));
      await tester.pumpAndSettle();

      // Check N3 content is now shown
      expect(
        find.byKey(const ValueKey<String>('mock_library_test_733')),
        findsOneWidget,
      );
      expect(find.textContaining('1 đề khả dụng'), findsOneWidget);
    },
  );
}

class _Levels implements JlptCatalogRepository {
  const _Levels();

  @override
  Future<List<JlptLevelCatalogItem>> loadLevels() async => const [
    JlptLevelCatalogItem(id: 5, code: 'N5', level: JlptLevel.n5, sortOrder: 1),
    JlptLevelCatalogItem(id: 4, code: 'N4', level: JlptLevel.n4, sortOrder: 2),
    JlptLevelCatalogItem(id: 3, code: 'N3', level: JlptLevel.n3, sortOrder: 3),
  ];
}

class _LibraryRepository implements MockTestRepository {
  @override
  Future<LiveMockTestAttempt?> loadActive(int mockTestId) async => null;
  final List<int> requestedIds = [];

  @override
  Future<void> saveAnswer(
    int attemptId,
    MockTestAnswerSubmission answer,
  ) async {}
  @override
  Future<LiveMockTestResult> finalizeExpired(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async {
    requestedIds.add(jlptLevelId);
    if (jlptLevelId == 4) throw const NotFoundError();
    return [
      LiveMockTestSummary(
        id: jlptLevelId == 5 ? 731 : 733,
        title: 'JLPT N$jlptLevelId',
        description: '',
        jlptLevelName: 'N$jlptLevelId',
        timeLimitMinutes: 100,
      ),
    ];
  }

  @override
  Future<LiveMockTestAttempt> start(int mockTestId) =>
      throw UnimplementedError();
  @override
  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  ) => throw UnimplementedError();
  @override
  Future<LiveMockTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();
  @override
  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId) =>
      throw UnimplementedError();
}

class _MultiExamRepository implements MockTestRepository {
  @override
  Future<LiveMockTestAttempt?> loadActive(int mockTestId) async => null;
  @override
  Future<void> saveAnswer(
    int attemptId,
    MockTestAnswerSubmission answer,
  ) async {}
  @override
  Future<LiveMockTestResult> finalizeExpired(int attemptId) =>
      throw UnimplementedError();
  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async {
    if (jlptLevelId == 4) throw const NotFoundError();
    if (jlptLevelId == 5) {
      return const [
        LiveMockTestSummary(
          id: 731,
          title: '[MOCK-SEED-v1] JLPT N5 – Đề kiểm thử 01',
          description: '',
          jlptLevelName: 'N5',
          timeLimitMinutes: 100,
        ),
        LiveMockTestSummary(
          id: 732,
          title: 'Đề thi thử JLPT N5 - Đề số 2',
          description: '',
          jlptLevelName: 'N5',
          timeLimitMinutes: 105,
        ),
      ];
    }
    return const [
      LiveMockTestSummary(
        id: 733,
        title: 'JLPT N3 — Đề thi thử 01',
        description: '',
        jlptLevelName: 'N3',
        timeLimitMinutes: 140,
      ),
    ];
  }

  @override
  Future<LiveMockTestAttempt> start(int mockTestId) =>
      throw UnimplementedError();
  @override
  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  ) => throw UnimplementedError();
  @override
  Future<LiveMockTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();
  @override
  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId) =>
      throw UnimplementedError();
}
