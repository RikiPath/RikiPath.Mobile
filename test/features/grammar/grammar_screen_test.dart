import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/grammar/application/grammar_controller.dart';
import 'package:rikipath_mobile/features/grammar/data/fixture_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/presentation/grammar_detail_screen.dart';
import 'package:rikipath_mobile/features/grammar/presentation/grammar_library_screen.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  test('Grammar routes are nested Learn-branch paths', () {
    expect(AppRoutes.grammar, '/learn/grammar');
    expect(
      AppRoutes.grammarDetail(FixtureGrammarRepository.tariRouteKey),
      '/learn/grammar/fixture-tari-tari',
    );
  });

  testWidgets('library renders the live N5-N1 filters and fixture label', (
    tester,
  ) async {
    await _pumpGrammar(tester);
    await tester.pumpAndSettle();

    expect(find.byType(GrammarLibraryScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('grammar_search_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_filter_n5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_filter_n4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_filter_n3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_fixture_label')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey<String>('grammar_filter_loaded')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('grammar_filter_n2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_filter_n1')),
      findsOneWidget,
    );
  });

  testWidgets('search submits a backend-compatible keyword query', (
    tester,
  ) async {
    await _pumpGrammar(tester);
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey<String>('grammar_search_field'));
    await tester.enterText(field, 'đồng thời');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('～ながら'), findsOneWidget);
    expect(find.text('～たり～たりする'), findsNothing);
  });

  testWidgets('JLPT filter displays only matching N5 fixture entries', (
    tester,
  ) async {
    await _pumpGrammar(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('grammar_filter_n5')));
    await tester.pumpAndSettle();

    expect(find.text('～てもいい'), findsOneWidget);
    expect(find.text('～たり～たりする'), findsNothing);
    expect(find.text('～わけではない'), findsNothing);
  });

  testWidgets('tapping a card opens the supported detail sections', (
    tester,
  ) async {
    await _pumpGrammar(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('grammar_card_fixture-tari-tari')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GrammarDetailScreen), findsOneWidget);
    expect(find.text('～たり～たりする'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('grammar_structure_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_explanation_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_detail_fixture_notice')),
      findsOneWidget,
    );
    await _scrollWithin(
      tester,
      find.byKey(const ValueKey<String>('grammar_examples_section')),
      'grammar_detail_view',
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_examples_section')),
      findsOneWidget,
    );
  });

  testWidgets('fixture detail exposes cautions and related Grammar section', (
    tester,
  ) async {
    await _pumpGrammar(
      tester,
      initialLocation: AppRoutes.grammarDetail(
        FixtureGrammarRepository.tariRouteKey,
      ),
    );
    await tester.pumpAndSettle();

    final cautions = find.byKey(
      const ValueKey<String>('grammar_cautions_section'),
    );
    await _scrollWithin(tester, cautions, 'grammar_detail_view');
    expect(cautions, findsOneWidget);

    final related = find.byKey(
      const ValueKey<String>('grammar_related_section'),
    );
    await _scrollWithin(tester, related, 'grammar_detail_view');

    expect(related, findsOneWidget);
    expect(find.text('～し～し'), findsOneWidget);
  });

  testWidgets('related Grammar item navigates through the same detail route', (
    tester,
  ) async {
    await _pumpGrammar(
      tester,
      initialLocation: AppRoutes.grammarDetail(
        FixtureGrammarRepository.tariRouteKey,
      ),
    );
    await tester.pumpAndSettle();

    final related = find.byKey(
      const ValueKey<String>('grammar_related_fixture-shi-shi'),
    );
    await _scrollWithin(tester, related, 'grammar_detail_view');
    await tester.tap(related);
    await tester.pumpAndSettle();

    expect(find.byType(GrammarDetailScreen), findsOneWidget);
    expect(find.text('～し～し'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('grammar_related_section')),
      findsNothing,
    );
  });

  testWidgets('pending repository renders loading state', (tester) async {
    await _pumpGrammar(tester, repository: _PendingGrammarRepository());
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('grammar_loading_view')),
      findsOneWidget,
    );
  });

  testWidgets('empty repository renders the clear-filter state', (
    tester,
  ) async {
    await _pumpGrammar(tester, repository: const _EmptyGrammarRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('grammar_empty_view')),
      findsOneWidget,
    );
    expect(find.text('Không tìm thấy ngữ pháp'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('grammar_search_field')),
      findsOneWidget,
    );
  });

  testWidgets('failed repository renders retry state', (tester) async {
    await _pumpGrammar(tester, repository: const _FailingGrammarRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('grammar_error_view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('grammar_retry_button')),
      findsOneWidget,
    );
  });

  testWidgets('load-more appends the next typed page', (tester) async {
    await _pumpGrammar(tester, repository: _PagedGrammarRepository());
    await tester.pumpAndSettle();

    expect(find.text('～たり～たりする'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('grammar_load_more_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('～たり～たりする'), findsOneWidget);
    expect(find.text('～わけではない'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('grammar_load_more_button')),
      findsNothing,
    );
  });

  testWidgets('detail repository failure renders retry state', (tester) async {
    await _pumpGrammar(
      tester,
      repository: const _FailingGrammarRepository(),
      initialLocation: AppRoutes.grammarDetail('remote-404'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('grammar_error_view')),
      findsOneWidget,
    );
  });

  testWidgets('successful bookmark uses the real ID and updates the UI', (
    tester,
  ) async {
    final bookmarkRepository = _FakeGrammarBookmarkRepository();
    await _pumpGrammar(
      tester,
      repository: const _RemoteGrammarRepository(),
      bookmarkRepository: bookmarkRepository,
      initialLocation: AppRoutes.grammarDetail('remote-19'),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey<String>('grammar_save_button'));
    await _scrollWithin(tester, button, 'grammar_detail_view');
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(bookmarkRepository.lastGrammarId, 19);
    expect(bookmarkRepository.calls, 1);
    final savedButton = tester.widget<RikiPrimaryButton>(button);
    expect(savedButton.onPressed, isNull);
  });

  testWidgets('duplicate bookmark conflict is treated as already saved', (
    tester,
  ) async {
    final bookmarkRepository = _FakeGrammarBookmarkRepository(
      error: const ConflictError(),
    );
    await _pumpGrammar(
      tester,
      repository: const _RemoteGrammarRepository(),
      bookmarkRepository: bookmarkRepository,
      initialLocation: AppRoutes.grammarDetail('remote-19'),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey<String>('grammar_save_button'));
    await _scrollWithin(tester, button, 'grammar_detail_view');
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(tester.widget<RikiPrimaryButton>(button).onPressed, isNull);
    expect(find.text('Không thể đánh dấu ngữ pháp.'), findsNothing);
  });

  for (final failure in <ApiError>[
    const ValidationError(),
    const NetworkError(),
  ]) {
    testWidgets('${failure.runtimeType} bookmark failure is controlled', (
      tester,
    ) async {
      await _pumpGrammar(
        tester,
        repository: const _RemoteGrammarRepository(),
        bookmarkRepository: _FakeGrammarBookmarkRepository(error: failure),
        initialLocation: AppRoutes.grammarDetail('remote-19'),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey<String>('grammar_save_button'));
      await _scrollWithin(tester, button, 'grammar_detail_view');
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Không thể đánh dấu ngữ pháp.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('library keeps the Learn bottom-navigation tab active', (
    tester,
  ) async {
    await _pumpGrammar(tester);
    await tester.pumpAndSettle();

    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);
  });

  testWidgets('library and detail fit a 320px portrait viewport', (
    tester,
  ) async {
    final router = await _pumpGrammar(
      tester,
      viewportSize: const Size(320, 700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.grammarDetail(FixtureGrammarRepository.tariRouteKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final related = find.byKey(
      const ValueKey<String>('grammar_related_section'),
    );
    await _scrollWithin(tester, related, 'grammar_detail_view');
    expect(tester.takeException(), isNull);
  });

  test('Grammar presentation contains no Dio or raw API JSON', () {
    final files = Directory('lib/features/grammar/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:dio/')), reason: file.path);
      expect(source, isNot(matches(RegExp(r'\bDio\s*\('))), reason: file.path);
      expect(source, isNot(contains("['result']")), reason: file.path);
      expect(source, isNot(contains("['items']")), reason: file.path);
    }
  });

  test('fixture Japanese and Vietnamese Unicode remains intact', () {
    final entry = FixtureGrammarRepository.entries.first;
    expect(entry.title, '～たり～たりする');
    expect(entry.structure, contains('V(た)'));
    expect(entry.explanation, contains('Liệt kê'));
    expect(entry.enrichment!.examples.first.sentence, contains('週末'));
    expect(entry.enrichment!.examples.first.translation, contains('Cuối tuần'));
  });
}

class _PendingGrammarRepository implements GrammarRepository {
  final Completer<GrammarPage> _completer = Completer<GrammarPage>();

  @override
  Future<GrammarPage> search(GrammarQuery query) => _completer.future;

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    return Completer<GrammarEntry>().future;
  }
}

class _EmptyGrammarRepository implements GrammarRepository {
  const _EmptyGrammarRepository();

  @override
  Future<GrammarPage> search(GrammarQuery query) async {
    return GrammarPage(
      items: const <GrammarEntry>[],
      page: query.page,
      pageSize: query.pageSize,
      totalCount: 0,
      totalPages: 0,
      source: GrammarDataSource.remote,
    );
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    return Future<GrammarEntry>.error(StateError('No Grammar.'));
  }
}

class _FailingGrammarRepository implements GrammarRepository {
  const _FailingGrammarRepository();

  @override
  Future<GrammarPage> search(GrammarQuery query) {
    return Future<GrammarPage>.error(StateError('fixture failure'));
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    return Future<GrammarEntry>.error(StateError('fixture failure'));
  }
}

class _PagedGrammarRepository implements GrammarRepository {
  @override
  Future<GrammarPage> search(GrammarQuery query) async {
    final item = query.page == 1
        ? FixtureGrammarRepository.entries.first
        : FixtureGrammarRepository.entries[1];
    return GrammarPage(
      items: <GrammarEntry>[item],
      page: query.page,
      pageSize: query.pageSize,
      totalCount: 2,
      totalPages: 2,
      source: GrammarDataSource.fixture,
    );
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    return const FixtureGrammarRepository().loadDetail(routeKey);
  }
}

class _RemoteGrammarRepository implements GrammarRepository {
  const _RemoteGrammarRepository();

  static final GrammarEntry entry = GrammarEntry(
    routeKey: 'remote-19',
    remoteId: 19,
    title: FixtureGrammarRepository.entries.first.title,
    structure: FixtureGrammarRepository.entries.first.structure,
    explanation: FixtureGrammarRepository.entries.first.explanation,
    exampleSentence: FixtureGrammarRepository.entries.first.exampleSentence,
    level: FixtureGrammarRepository.entries.first.level,
    source: GrammarDataSource.remote,
  );

  @override
  Future<GrammarPage> search(GrammarQuery query) async {
    return GrammarPage(
      items: <GrammarEntry>[entry],
      page: 1,
      pageSize: query.pageSize,
      totalCount: 1,
      totalPages: 1,
      source: GrammarDataSource.remote,
    );
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) async => entry;
}

class _FakeGrammarBookmarkRepository implements GrammarBookmarkRepository {
  _FakeGrammarBookmarkRepository({this.error});

  final Object? error;
  int calls = 0;
  int? lastGrammarId;

  @override
  Future<GrammarBookmark> bookmarkGrammar(int grammarPatternId) async {
    calls++;
    lastGrammarId = grammarPatternId;
    if (error != null) throw error!;
    return GrammarBookmark(
      reviewCardId: 811,
      grammarPatternId: grammarPatternId,
      grammarTitle: _RemoteGrammarRepository.entry.title,
    );
  }
}

Future<GoRouter> _pumpGrammar(
  WidgetTester tester, {
  String initialLocation = AppRoutes.grammar,
  GrammarRepository repository = const FixtureGrammarRepository(),
  GrammarBookmarkRepository? bookmarkRepository,
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        grammarRepositoryProvider.overrideWithValue(repository),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        if (bookmarkRepository != null)
          grammarBookmarkRepositoryProvider.overrideWithValue(
            bookmarkRepository,
          ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

Future<void> _scrollWithin(
  WidgetTester tester,
  Finder target,
  String viewKey,
) async {
  final view = find.byKey(ValueKey<String>(viewKey));
  final scrollable = find
      .descendant(of: view, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(target, 240, scrollable: scrollable);
  await tester.pumpAndSettle();
}
