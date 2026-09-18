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
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/fixture_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/application/vocabulary_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/data/fixture_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_detail_screen.dart';

import '../../support/test_auth_session.dart';

void main() {
  test('Notebook detail route stays under the Notebook shell branch', () {
    expect(AppRoutes.notebook, '/notebook');
    expect(
      AppRoutes.notebookVocabularyDetail('fixture-keiken'),
      '/notebook/vocabulary/fixture-keiken',
    );
  });

  testWidgets('Notebook route renders with its bottom tab selected', (
    tester,
  ) async {
    await _pumpNotebook(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NotebookScreen), findsOneWidget);
    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 3);
  });

  testWidgets('unauthenticated Notebook access redirects to login', (
    tester,
  ) async {
    await _pumpNotebook(tester, authState: AuthSessionState.unauthenticated);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(NotebookScreen), findsNothing);
  });

  testWidgets('saved list renders Japanese Unicode and Vietnamese meaning', (
    tester,
  ) async {
    await _pumpNotebook(tester);
    await tester.pumpAndSettle();

    expect(find.text('経験'), findsOneWidget);
    expect(find.text('けいけん'), findsOneWidget);
    expect(find.text('Kinh nghiệm'), findsOneWidget);
    expect(find.text('改善'), findsOneWidget);
  });

  testWidgets('fixture data is visibly identified', (tester) async {
    await _pumpNotebook(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('notebook_fixture_label')),
      findsOneWidget,
    );
    expect(find.text('Dữ liệu mẫu'), findsOneWidget);
  });

  testWidgets('empty Notebook renders the first-list action', (tester) async {
    await _pumpNotebook(
      tester,
      repository: _TestNotebookRepository(collections: const []),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('notebook_empty_view')),
      findsOneWidget,
    );
    expect(find.text('Sổ từ của bạn đang trống'), findsOneWidget);
  });

  testWidgets('empty selected list renders the add-entry action', (
    tester,
  ) async {
    await _pumpNotebook(
      tester,
      repository: _TestNotebookRepository(
        collections: <NotebookCollection>[_collection],
        entries: const <NotebookEntry>[],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('notebook_entries_empty_view')),
      findsOneWidget,
    );
    expect(find.text('Danh sách chưa có từ'), findsOneWidget);
  });

  testWidgets('pending repository renders loading', (tester) async {
    await _pumpNotebook(tester, repository: _PendingNotebookRepository());
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('notebook_loading_view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed repository renders retry', (tester) async {
    await _pumpNotebook(tester, repository: _FailingNotebookRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('notebook_error_view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('notebook_retry_button')),
      findsOneWidget,
    );
  });

  testWidgets('search matches reading and has a no-result state', (
    tester,
  ) async {
    await _pumpNotebook(tester);
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey<String>('notebook_search_field'));

    await tester.enterText(search, 'かいぜん');
    await tester.pump();
    expect(find.text('改善'), findsOneWidget);
    expect(find.text('経験'), findsNothing);

    await tester.enterText(search, 'không tồn tại');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('notebook_search_empty_view')),
      findsOneWidget,
    );
  });

  testWidgets('fixture vocabulary opens detail inside Notebook branch', (
    tester,
  ) async {
    await _pumpNotebook(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('notebook_entry_fixture-note-keiken')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VocabularyDetailScreen), findsOneWidget);
    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 3);
  });

  testWidgets('remove confirmation deletes a saved entry', (tester) async {
    await _pumpNotebook(tester);
    await tester.pumpAndSettle();

    await _startRemove(tester, 'fixture-note-keiken');
    await tester.pumpAndSettle();

    expect(find.text('経験'), findsNothing);
  });

  testWidgets('remove displays progress while the mutation is pending', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = _TestNotebookRepository(
      collections: <NotebookCollection>[_collection],
      entries: <NotebookEntry>[_remoteEntry],
      removeCompleter: completer,
    );
    await _pumpNotebook(tester, repository: repository);
    await tester.pumpAndSettle();

    await _startRemove(tester, _remoteEntry.routeKey);
    expect(
      find.byKey(const ValueKey<String>('notebook_remove_progress')),
      findsOneWidget,
    );

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('経験'), findsNothing);
  });

  testWidgets('remove failure preserves the entry and shows an error', (
    tester,
  ) async {
    final repository = _TestNotebookRepository(
      collections: <NotebookCollection>[_collection],
      entries: <NotebookEntry>[_remoteEntry],
      removeError: StateError('remove failed'),
    );
    await _pumpNotebook(tester, repository: repository);
    await tester.pumpAndSettle();

    await _startRemove(tester, _remoteEntry.routeKey);
    await tester.pumpAndSettle();

    expect(find.text('経験'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('notebook_mutation_error')),
      findsOneWidget,
    );
  });

  testWidgets('create-list form renders the repository result', (tester) async {
    final repository = _TestNotebookRepository(collections: const []);
    await _pumpNotebook(tester, repository: repository);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('notebook_empty_create_collection_button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('notebook_collection_name_field')),
      'N4 giao tiếp',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('notebook_create_collection_submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.createdNames, <String>['N4 giao tiếp']);
    expect(find.textContaining('N4 giao tiếp'), findsOneWidget);
  });

  testWidgets('manual form saves the supported entry fields', (tester) async {
    final repository = _TestNotebookRepository(
      collections: <NotebookCollection>[_collection],
      entries: const <NotebookEntry>[],
    );
    await _pumpNotebook(tester, repository: repository);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('notebook_add_entry_button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('notebook_manual_word_field')),
      '約束',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('notebook_manual_reading_field')),
      'やくそく',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('notebook_manual_meaning_field')),
      'Lời hứa',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('notebook_manual_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(repository.manualWords, <String>['約束']);
    expect(find.text('約束'), findsOneWidget);
    expect(find.text('やくそく'), findsOneWidget);
  });

  testWidgets('Notebook does not overflow at 320px portrait width', (
    tester,
  ) async {
    await _pumpNotebook(tester, viewportSize: const Size(320, 700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey<String>('notebook_content')),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('Notebook presentation contains no Dio, raw JSON, or API paths', () {
    final files = Directory('lib/features/notebook/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:dio/')), reason: file.path);
      expect(source, isNot(matches(RegExp(r'\bDio\s*\('))), reason: file.path);
      expect(source, isNot(contains('/api/')), reason: file.path);
      expect(
        source,
        isNot(contains('Map<String, Object?>')),
        reason: file.path,
      );
    }
  });
}

const NotebookCollection _collection = NotebookCollection(
  routeKey: 'remote-list-3',
  remoteId: 3,
  name: 'JLPT N3',
  entryCount: 1,
  createdAt: null,
  source: NotebookDataSource.remote,
);

final NotebookEntry _remoteEntry = NotebookEntry(
  routeKey: 'remote-note-41',
  remoteNoteEntryId: 41,
  reviewItemId: 52,
  contentType: NotebookContentType.vocabulary,
  term: '経験',
  reading: 'けいけん',
  meaning: 'Kinh nghiệm',
  addedAt: DateTime.utc(2026, 9, 12),
  source: NotebookDataSource.remote,
);

Future<GoRouter> _pumpNotebook(
  WidgetTester tester, {
  NotebookRepository? repository,
  AuthSessionState authState = AuthSessionState.authenticated,
  Size viewportSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession(initialState: authState);
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.notebook,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notebookRepositoryProvider.overrideWithValue(
          repository ?? FixtureNotebookRepository(),
        ),
        vocabularyRepositoryProvider.overrideWithValue(
          const FixtureVocabularyRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

Future<void> _startRemove(WidgetTester tester, String routeKey) async {
  await tester.tap(find.byKey(ValueKey<String>('notebook_remove_$routeKey')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey<String>('notebook_confirm_remove_button')),
  );
  await tester.pump();
}

class _PendingNotebookRepository implements NotebookRepository {
  final Completer<List<NotebookCollection>> _completer =
      Completer<List<NotebookCollection>>();

  @override
  Future<List<NotebookCollection>> loadCollections() => _completer.future;

  @override
  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection) {
    throw UnimplementedError();
  }

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required int vocabularyEntryId,
    required NotebookCollection collection,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) {
    throw UnimplementedError();
  }
}

class _FailingNotebookRepository extends _PendingNotebookRepository {
  @override
  Future<List<NotebookCollection>> loadCollections() async {
    throw StateError('load failed');
  }
}

class _TestNotebookRepository implements NotebookRepository {
  _TestNotebookRepository({
    required List<NotebookCollection> collections,
    List<NotebookEntry> entries = const <NotebookEntry>[],
    this.removeCompleter,
    this.removeError,
  }) : _collections = List<NotebookCollection>.of(collections),
       _entries = List<NotebookEntry>.of(entries);

  final List<NotebookCollection> _collections;
  final List<NotebookEntry> _entries;
  final Completer<void>? removeCompleter;
  final Object? removeError;
  final List<String> createdNames = <String>[];
  final List<String> manualWords = <String>[];

  @override
  Future<List<NotebookCollection>> loadCollections() async =>
      List<NotebookCollection>.unmodifiable(_collections);

  @override
  Future<List<NotebookEntry>> loadEntries(
    NotebookCollection collection,
  ) async => List<NotebookEntry>.unmodifiable(_entries);

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) async {
    createdNames.add(name);
    final collection = NotebookCollection(
      routeKey: 'remote-list-created',
      remoteId: 9,
      name: name,
      description: description,
      entryCount: 0,
      createdAt: DateTime.utc(2026, 9, 13),
      source: NotebookDataSource.remote,
    );
    _collections.add(collection);
    return collection;
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) async {
    manualWords.add(word);
    final entry = NotebookEntry(
      routeKey: 'remote-note-created',
      remoteNoteEntryId: 77,
      contentType: NotebookContentType.manual,
      term: word,
      reading: reading,
      meaning: meaning,
      note: note,
      addedAt: DateTime.utc(2026, 9, 13),
      source: NotebookDataSource.remote,
    );
    _entries.insert(0, entry);
    return entry;
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required int vocabularyEntryId,
    required NotebookCollection collection,
  }) async {
    return NotebookBookmark(
      noteEntryId: 41,
      collectionRouteKey: collection.routeKey,
      collectionName: collection.name,
    );
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    if (removeCompleter != null) await removeCompleter!.future;
    if (removeError != null) throw removeError!;
    _entries.removeWhere((item) => item.routeKey == entry.routeKey);
  }
}
