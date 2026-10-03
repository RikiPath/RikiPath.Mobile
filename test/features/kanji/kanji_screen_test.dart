import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/data/fixture_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_detail_screen.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_library_screen.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/session_demo_notebook_repository.dart';

import '../../support/test_auth_session.dart';

void main() {
  test('Kanji routes are nested Learn-branch paths', () {
    expect(AppRoutes.kanji, '/learn/kanji');
    expect(
      AppRoutes.kanjiDetail(FixtureKanjiRepository.kenRouteKey),
      '/learn/kanji/fixture-ken',
    );
  });

  testWidgets('library renders search, N5/N4/N3 filters, fixture label', (
    tester,
  ) async {
    await _pumpKanji(tester);
    await tester.pumpAndSettle();

    expect(find.byType(KanjiLibraryScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('kanji_search_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('kanji_level_N5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('kanji_level_N4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('kanji_level_N3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('kanji_fixture_label')),
      findsOneWidget,
    );
    expect(find.text('N2'), findsNothing);
    expect(find.text('N1'), findsNothing);
  });

  testWidgets('search submits a character-or-meaning query', (tester) async {
    await _pumpKanji(tester);
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey<String>('kanji_search_field'));
    await tester.enterText(field, 'học tập');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('学'), findsOneWidget);
    expect(find.text('験'), findsNothing);
  });

  testWidgets('JLPT filter displays only matching N4 fixture entries', (
    tester,
  ) async {
    await _pumpKanji(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('kanji_level_N4')));
    await tester.pumpAndSettle();

    expect(find.text('会'), findsOneWidget);
    expect(find.text('験'), findsNothing);
  });

  testWidgets('tapping a Kanji opens supported detail sections', (
    tester,
  ) async {
    await _pumpKanji(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('kanji_card_fixture-ken')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KanjiDetailScreen), findsOneWidget);
    expect(find.text('験'), findsWidgets);
    expect(find.text('Cách đọc'), findsOneWidget);
    expect(find.textContaining('Nội dung bổ sung'), findsOneWidget);
    await _scrollWithin(
      tester,
      find.text('Từ ghép thường gặp'),
      'kanji_detail_view',
    );
    expect(find.text('Mẹo ghi nhớ'), findsOneWidget);
    expect(find.text('Từ ghép thường gặp'), findsOneWidget);
  });

  testWidgets('stroke order detail is an internal state with step controls', (
    tester,
  ) async {
    await _pumpKanji(
      tester,
      initialLocation: AppRoutes.kanjiDetail(
        FixtureKanjiRepository.kenRouteKey,
      ),
    );
    await tester.pumpAndSettle();

    final openButton = find.byKey(
      const ValueKey<String>('kanji_open_strokes_button'),
    );
    await _scrollWithin(tester, openButton, 'kanji_detail_view');
    await tester.tap(openButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('kanji_stroke_order_view')),
      findsOneWidget,
    );
    expect(find.text('Nét 1/18'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('kanji_stroke_next')));
    await tester.pump();
    expect(find.text('Nét 2/18'), findsOneWidget);

    final closeButton = find.byKey(
      const ValueKey<String>('kanji_close_strokes_button'),
    );
    await _scrollWithin(tester, closeButton, 'kanji_stroke_order_view');
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('kanji_detail_view')),
      findsOneWidget,
    );
  });

  testWidgets('fixture detail exercises notebook save without remote ID', (
    tester,
  ) async {
    await _pumpKanji(
      tester,
      initialLocation: AppRoutes.kanjiDetail(
        FixtureKanjiRepository.kenRouteKey,
      ),
    );
    await tester.pumpAndSettle();

    final save = find.byKey(const ValueKey<String>('kanji_save_button'));
    await _scrollWithin(tester, save, 'kanji_detail_view');
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('kanji_notebook_-1')));
    await tester.pumpAndSettle();

    expect(find.text('Đã lưu vào Sổ từ'), findsOneWidget);
  });

  testWidgets('pending repository renders loading state', (tester) async {
    await _pumpKanji(tester, repository: _PendingKanjiRepository());
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('kanji_loading_view')),
      findsOneWidget,
    );
  });

  testWidgets('empty repository renders clear-filter state', (tester) async {
    await _pumpKanji(tester, repository: const _EmptyKanjiRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('kanji_empty_view')),
      findsOneWidget,
    );
    expect(find.text('Không tìm thấy Kanji'), findsOneWidget);
  });

  testWidgets('failed repository renders retry state', (tester) async {
    await _pumpKanji(tester, repository: const _FailingKanjiRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('kanji_error_view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('kanji_retry_button')),
      findsOneWidget,
    );
  });

  testWidgets('load-more appends the next typed page', (tester) async {
    await _pumpKanji(tester, repository: _PagedKanjiRepository());
    await tester.pumpAndSettle();

    expect(find.text('験'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('kanji_load_more_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('験'), findsOneWidget);
    expect(find.text('学'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('kanji_load_more_button')),
      findsNothing,
    );
  });

  testWidgets('detail repository failure renders retry state', (tester) async {
    await _pumpKanji(
      tester,
      repository: const _FailingKanjiRepository(),
      initialLocation: AppRoutes.kanjiDetail('remote-404'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('kanji_error_view')),
      findsOneWidget,
    );
  });

  testWidgets('library keeps the Learn bottom-navigation tab active', (
    tester,
  ) async {
    await _pumpKanji(tester);
    await tester.pumpAndSettle();

    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);
  });

  testWidgets('library, detail, and strokes fit 320px portrait width', (
    tester,
  ) async {
    final router = await _pumpKanji(tester, viewportSize: const Size(320, 700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.kanjiDetail(FixtureKanjiRepository.kenRouteKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final openButton = find.byKey(
      const ValueKey<String>('kanji_open_strokes_button'),
    );
    await _scrollWithin(tester, openButton, 'kanji_detail_view');
    await tester.tap(openButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('Kanji presentation contains no Dio or raw API JSON', () {
    final files = Directory('lib/features/kanji/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:dio/')), reason: file.path);
      expect(source, isNot(matches(RegExp(r'\bDio\s*\('))), reason: file.path);
      expect(source, isNot(contains("['result']")), reason: file.path);
    }
  });

  test('fixture Japanese and Vietnamese Unicode remains intact', () {
    final entry = FixtureKanjiRepository.entries.first;
    expect(entry.character, '験');
    expect(entry.onYomi, 'ケン・ゲン');
    expect(entry.meaning, contains('Kiểm nghiệm'));
    expect(entry.enrichment!.example!.sentence, '日本で働いた経験があります。');
  });
}

class _PendingKanjiRepository implements KanjiRepository {
  final Completer<KanjiPage> _completer = Completer<KanjiPage>();

  @override
  Future<KanjiPage> search(KanjiQuery query) => _completer.future;

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    return Completer<KanjiEntry>().future;
  }
}

class _EmptyKanjiRepository implements KanjiRepository {
  const _EmptyKanjiRepository();

  @override
  Future<KanjiPage> search(KanjiQuery query) async {
    return KanjiPage(
      items: const <KanjiEntry>[],
      page: query.page,
      pageSize: query.pageSize,
      totalCount: 0,
      totalPages: 0,
      source: KanjiDataSource.remote,
    );
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    return Future<KanjiEntry>.error(StateError('No Kanji.'));
  }
}

class _FailingKanjiRepository implements KanjiRepository {
  const _FailingKanjiRepository();

  @override
  Future<KanjiPage> search(KanjiQuery query) {
    return Future<KanjiPage>.error(StateError('fixture failure'));
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    return Future<KanjiEntry>.error(StateError('fixture failure'));
  }
}

class _PagedKanjiRepository implements KanjiRepository {
  @override
  Future<KanjiPage> search(KanjiQuery query) async {
    final item = query.page == 1
        ? FixtureKanjiRepository.entries.first
        : FixtureKanjiRepository.entries.firstWhere(
            (entry) => entry.character == '学',
          );
    return KanjiPage(
      items: <KanjiEntry>[item],
      page: query.page,
      pageSize: query.pageSize,
      totalCount: 2,
      totalPages: 2,
      source: KanjiDataSource.fixture,
    );
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    return const FixtureKanjiRepository().loadDetail(routeKey);
  }
}

Future<GoRouter> _pumpKanji(
  WidgetTester tester, {
  String initialLocation = AppRoutes.kanji,
  KanjiRepository repository = const FixtureKanjiRepository(),
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
        kanjiRepositoryProvider.overrideWithValue(repository),
        demoNotebookRepositoryProvider.overrideWithValue(
          demoNotebookRepository,
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
