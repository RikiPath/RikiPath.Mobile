import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/fixture_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/data/session_demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/shared_bank/presentation/shared_bank_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/application/vocabulary_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/data/fixture_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_detail_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_library_screen.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  test('vocabulary routes are nested Learn-branch paths', () {
    expect(AppRoutes.vocabulary, '/learn/vocabulary');
    expect(
      AppRoutes.vocabularyDetail(FixtureVocabularyRepository.keikenRouteKey),
      '/learn/vocabulary/fixture-keiken',
    );
  });

  testWidgets('library renders list, search, filters, and Learn navigation', (
    tester,
  ) async {
    await _pumpVocabulary(tester);
    await tester.pumpAndSettle();

    expect(find.byType(VocabularyLibraryScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('vocabulary_search_field')),
      findsOneWidget,
    );
    expect(find.text('JLPT N5'), findsOneWidget);
    expect(find.text('JLPT N4'), findsOneWidget);
    expect(find.text('JLPT N3'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey<String>('vocabulary_filter_loaded')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('JLPT N2'), findsOneWidget);
    expect(find.text('JLPT N1'), findsOneWidget);
    expect(find.text('Nội dung bổ sung'), findsOneWidget);

    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);
  });

  testWidgets('search submits a typed repository query', (tester) async {
    await _pumpVocabulary(tester);
    await tester.pumpAndSettle();

    final searchField = find.byKey(
      const ValueKey<String>('vocabulary_search_field'),
    );
    await tester.enterText(searchField, 'cải thiện');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('改善'), findsOneWidget);
    expect(find.text('経験'), findsNothing);
  });

  testWidgets('JLPT filter exposes only matching N5 fixture entries', (
    tester,
  ) async {
    await _pumpVocabulary(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('vocabulary_filter_n5')),
    );
    await tester.pumpAndSettle();

    expect(find.text('学生'), findsOneWidget);
    expect(find.text('経験'), findsNothing);
  });

  testWidgets('tapping a vocabulary opens its detail route', (tester) async {
    await _pumpVocabulary(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('vocabulary_card_fixture-keiken')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VocabularyDetailScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('vocabulary_detail_view')),
      findsOneWidget,
    );
    expect(find.text('経験'), findsOneWidget);
    expect(find.text('Ý nghĩa'), findsOneWidget);
    expect(find.text('Nội dung bổ sung'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('vocabulary_detail_fixture_notice')),
      findsOneWidget,
    );
  });

  testWidgets('Learning Home opens SharedBank with all learner entries', (
    tester,
  ) async {
    await _pumpVocabulary(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();

    final libraryCard = find.byKey(
      const ValueKey<String>('learning_section_library'),
    );
    await tester.scrollUntilVisible(libraryCard, 180);
    await tester.drag(
      find.byKey(const ValueKey<String>('learning_home_success_view')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(libraryCard);
    await tester.pumpAndSettle();

    expect(find.byType(SharedBankScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('shared_bank_vocabulary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('shared_bank_kanji')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('shared_bank_grammar')),
      findsOneWidget,
    );
    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('shared_bank_vocabulary')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VocabularyLibraryScreen), findsOneWidget);
  });

  testWidgets('fixture detail can exercise the notebook save state locally', (
    tester,
  ) async {
    await _pumpVocabulary(
      tester,
      initialLocation: AppRoutes.vocabularyDetail(
        FixtureVocabularyRepository.keikenRouteKey,
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.byKey(
      const ValueKey<String>('vocabulary_save_button'),
    );
    await _scrollWithin(tester, saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('vocabulary_notebook_fixture-learning-saved'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('vocabulary_saved_banner')),
      findsOneWidget,
    );
  });

  testWidgets('Vocabulary and Notebook observe the same saved source', (
    tester,
  ) async {
    final router = await _pumpVocabulary(
      tester,
      initialLocation: AppRoutes.vocabularyDetail(
        FixtureVocabularyRepository.keikenRouteKey,
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.byKey(
      const ValueKey<String>('vocabulary_save_button'),
    );
    await _scrollWithin(tester, saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('vocabulary_notebook_fixture-learning-saved'),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.notebook);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('notebook_collection_fixture-learning-saved'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>(
          'notebook_entry_fixture:vocabulary:fixture-keiken',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'notebook_remove_fixture:vocabulary:fixture-keiken',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('notebook_confirm_remove_button')),
    );
    await tester.pumpAndSettle();

    router.go(
      AppRoutes.vocabularyDetail(FixtureVocabularyRepository.keikenRouteKey),
    );
    await tester.pumpAndSettle();
    await _scrollWithin(tester, saveButton);
    expect(saveButton, findsOneWidget);
  });

  testWidgets('pending repository renders the loading state', (tester) async {
    await _pumpVocabulary(tester, repository: _PendingVocabularyRepository());
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('vocabulary_loading_view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty repository renders the clear-filter state', (
    tester,
  ) async {
    await _pumpVocabulary(
      tester,
      repository: const _EmptyVocabularyRepository(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('vocabulary_empty_view')),
      findsOneWidget,
    );
    expect(find.text('Không tìm thấy từ vựng'), findsOneWidget);
  });

  testWidgets('failed repository renders the retry state', (tester) async {
    await _pumpVocabulary(
      tester,
      repository: const _FailingVocabularyRepository(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('vocabulary_error_view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('vocabulary_retry_button')),
      findsOneWidget,
    );
  });

  testWidgets('library and detail do not overflow at 320px portrait width', (
    tester,
  ) async {
    final router = await _pumpVocabulary(
      tester,
      viewportSize: const Size(320, 700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    router.go(
      AppRoutes.vocabularyDetail(FixtureVocabularyRepository.keikenRouteKey),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final saveButton = find.byKey(
      const ValueKey<String>('vocabulary_save_button'),
    );
    await _scrollWithin(tester, saveButton);
    expect(tester.takeException(), isNull);
  });

  test('vocabulary presentation contains no direct Dio usage', () {
    final dartFiles = Directory('lib/features/vocabulary/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:dio/')), reason: file.path);
      expect(source, isNot(matches(RegExp(r'\bDio\s*\('))), reason: file.path);
    }
  });
}

class _PendingVocabularyRepository implements VocabularyRepository {
  final Completer<VocabularyPage> _completer = Completer<VocabularyPage>();

  @override
  Future<VocabularyPage> search(VocabularyQuery query) => _completer.future;

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) {
    return Completer<VocabularyEntry>().future;
  }
}

class _EmptyVocabularyRepository implements VocabularyRepository {
  const _EmptyVocabularyRepository();

  @override
  Future<VocabularyPage> search(VocabularyQuery query) async {
    return VocabularyPage(
      items: const <VocabularyEntry>[],
      page: query.page,
      pageSize: query.pageSize,
      totalCount: 0,
      totalPages: 0,
      source: VocabularyDataSource.remote,
    );
  }

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) {
    return Future<VocabularyEntry>.error(StateError('No vocabulary.'));
  }
}

class _FailingVocabularyRepository implements VocabularyRepository {
  const _FailingVocabularyRepository();

  @override
  Future<VocabularyPage> search(VocabularyQuery query) {
    return Future<VocabularyPage>.error(StateError('fixture failure'));
  }

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) {
    return Future<VocabularyEntry>.error(StateError('fixture failure'));
  }
}

Future<GoRouter> _pumpVocabulary(
  WidgetTester tester, {
  String initialLocation = AppRoutes.vocabulary,
  VocabularyRepository repository = const FixtureVocabularyRepository(),
  Size viewportSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);
  final demoNotebookRepository = SessionDemoNotebookRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vocabularyRepositoryProvider.overrideWithValue(repository),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        notebookRepositoryProvider.overrideWithValue(
          FixtureNotebookRepository(entries: const {}),
        ),
        demoNotebookRepositoryProvider.overrideWithValue(
          demoNotebookRepository,
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) =>
            RikiToastHost(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  return router;
}

Future<void> _scrollWithin(WidgetTester tester, Finder target) async {
  final view = find.byKey(const ValueKey<String>('vocabulary_detail_view'));
  final scrollable = find
      .descendant(of: view, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(target, 240, scrollable: scrollable);
  await tester.pumpAndSettle();
}
