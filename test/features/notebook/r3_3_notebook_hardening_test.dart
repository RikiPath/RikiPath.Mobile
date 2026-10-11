import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/persistent_demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_entry_detail_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_json_preference_store.dart';

void main() {
  test('1. Fixture vocabulary bookmark persists', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);

    final restored = await PersistentDemoNotebookRepository(
      store,
    ).loadEntries();
    expect(restored.single.key, _fixtureVocabulary.key);
    expect(restored.single.origin, NotebookItemOrigin.fixture);
  });

  test('2. Fixture kanji bookmark persists', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureKanji);

    final restored = await PersistentDemoNotebookRepository(
      store,
    ).loadEntries();
    expect(restored.single.key, _fixtureKanji.key);
    expect(restored.single.contentType, NotebookContentType.kanji);
  });

  test('3. Fixture grammar bookmark persists', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureGrammar);

    final restored = await PersistentDemoNotebookRepository(
      store,
    ).loadEntries();
    expect(restored.single.key, _fixtureGrammar.key);
    expect(restored.single.contentType, NotebookContentType.grammar);
  });

  test(
    '4. Duplicate fixture bookmark is prevented by exact identity',
    () async {
      final repository = PersistentDemoNotebookRepository(
        TestJsonPreferenceStore(),
      );
      final first = await repository.saveEntry(_fixtureVocabulary);
      final duplicate = await repository.saveEntry(_fixtureVocabulary);

      expect(await repository.loadEntries(), hasLength(1));
      expect(duplicate.key, first.key);
    },
  );

  test('5. Removing fixture bookmark removes local state', () async {
    final repository = PersistentDemoNotebookRepository(
      TestJsonPreferenceStore(),
    );
    await repository.saveEntry(_fixtureVocabulary);
    await repository.removeEntry(_fixtureVocabulary.key);

    expect(await repository.loadEntries(), isEmpty);
  });

  test('6. Removing fixture bookmark never calls live API', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final live = _RecordingNotebookRepository();
    final container = _container(store, live);
    addTearDown(container.dispose);
    final state = await container.read(notebookControllerProvider.future);
    final local = state.localEntries.single;

    expect(
      await container
          .read(notebookControllerProvider.notifier)
          .removeEntry(local),
      isTrue,
    );
    expect(live.removeCalls, 0);
  });

  test('7. Fixture bookmark never calls live bookmark API', () async {
    final live = _RecordingNotebookRepository();
    final container = _container(TestJsonPreferenceStore(), live);
    addTearDown(container.dispose);

    await container
        .read(demoNotebookControllerProvider.notifier)
        .saveEntry(_fixtureVocabulary);
    expect(live.bookmarkCalls, 0);
  });

  test('8. Fixture items survive repository reconstruction', () async {
    final store = TestJsonPreferenceStore();
    final original = PersistentDemoNotebookRepository(store);
    await original.saveEntry(_fixtureVocabulary);
    await original.saveEntry(_fixtureKanji);
    await original.saveEntry(_fixtureGrammar);

    final restored = await PersistentDemoNotebookRepository(
      store,
    ).loadEntries();
    expect(restored.map((entry) => entry.key).toSet(), {
      _fixtureVocabulary.key,
      _fixtureKanji.key,
      _fixtureGrammar.key,
    });
  });

  test('9. Bookmark state restores in Lesson from repository truth', () async {
    final store = TestJsonPreferenceStore();
    final first = _container(store, _RecordingNotebookRepository());
    final lessonId = FixtureLessonRepository.lesson19RouteId;
    await first.read(lessonControllerProvider(lessonId).future);
    await first
        .read(lessonControllerProvider(lessonId).notifier)
        .toggleFixtureVocabulary(0);
    expect(
      first
          .read(lessonControllerProvider(lessonId))
          .requireValue
          .lesson
          .vocabulary
          .first
          .isSaved,
      isTrue,
    );
    first.dispose();

    final restored = _container(store, _RecordingNotebookRepository());
    addTearDown(restored.dispose);
    final session = await restored.read(
      lessonControllerProvider(lessonId).future,
    );
    expect(session.lesson.vocabulary.first.isSaved, isTrue);
  });

  test('10. Live bookmark path still uses live repository', () async {
    final live = _RecordingNotebookRepository();
    final container = _container(TestJsonPreferenceStore(), live);
    addTearDown(container.dispose);

    await container
        .read(notebookRepositoryProvider)
        .bookmarkVocabulary(
          vocabulary: _liveVocabulary,
          collection: _liveCollection,
        );
    expect(live.bookmarkCalls, 1);
  });

  test('11. Valid backend ID passes through unchanged', () async {
    final live = _RecordingNotebookRepository();
    final container = _container(TestJsonPreferenceStore(), live);
    addTearDown(container.dispose);

    await container
        .read(notebookRepositoryProvider)
        .bookmarkVocabulary(
          vocabulary: _liveVocabulary,
          collection: _liveCollection,
        );
    expect(live.lastVocabularyId, 401);
    expect(live.lastCollectionId, 12);
  });

  test('12. Fixture key never converts into a backend ID', () {
    final parsed = NotebookEntryKey.tryParse(_fixtureVocabulary.key.encoded);
    expect(parsed?.origin, NotebookItemOrigin.fixture);
    expect(parsed?.liveNoteEntryId, isNull);
    expect(NotebookEntryKey.tryParse('live:vocabulary:not-an-id'), isNull);
  });

  test('13. Live and local entries stay isolated by collection', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final container = _container(store, _RecordingNotebookRepository());
    addTearDown(container.dispose);

    final notebook = await container.read(notebookControllerProvider.future);
    expect(notebook.entries.map((entry) => entry.key), <NotebookEntryKey>[
      _liveEntry.key,
    ]);
    expect(notebook.localEntries.single.key, _fixtureVocabulary.key);

    final localCollection = notebook.collections.firstWhere(
      (collection) => collection.source == NotebookDataSource.fixture,
    );
    await container
        .read(notebookControllerProvider.notifier)
        .selectCollection(localCollection);
    expect(
      container
          .read(notebookControllerProvider)
          .requireValue
          .entries
          .single
          .key,
      _fixtureVocabulary.key,
    );
  });

  test('14. Live empty keeps the local collection available', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureKanji);
    final container = _container(
      store,
      _RecordingNotebookRepository(entries: const <NotebookEntry>[]),
    );
    addTearDown(container.dispose);

    final notebook = await container.read(notebookControllerProvider.future);
    final localCollection = notebook.collections.firstWhere(
      (collection) => collection.source == NotebookDataSource.fixture,
    );
    await container
        .read(notebookControllerProvider.notifier)
        .selectCollection(localCollection);
    expect(
      container
          .read(notebookControllerProvider)
          .requireValue
          .entries
          .single
          .key,
      _fixtureKanji.key,
    );
  });

  test('15. Live failure keeps the local collection available', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureGrammar);
    final container = _container(
      store,
      _RecordingNotebookRepository(failEntries: true),
    );
    addTearDown(container.dispose);

    final notebook = await container.read(notebookControllerProvider.future);
    expect(notebook.entriesError, isNotNull);
    final localCollection = notebook.collections.firstWhere(
      (collection) => collection.source == NotebookDataSource.fixture,
    );
    await container
        .read(notebookControllerProvider.notifier)
        .selectCollection(localCollection);
    expect(
      container
          .read(notebookControllerProvider)
          .requireValue
          .entries
          .single
          .key,
      _fixtureGrammar.key,
    );
  });

  test('16. Local restore failure does not block live data', () async {
    final store = TestJsonPreferenceStore(failReads: true);
    final container = _container(store, _RecordingNotebookRepository());
    addTearDown(container.dispose);

    final notebook = await container.read(notebookControllerProvider.future);
    expect(notebook.liveEntries.single.key, _liveEntry.key);
    expect(notebook.mutationError, isNotNull);
  });

  test('17. Refreshing live data preserves local items', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final container = _container(store, _RecordingNotebookRepository());
    addTearDown(container.dispose);
    await container.read(notebookControllerProvider.future);

    await container.read(notebookControllerProvider.notifier).retry();
    final refreshed = container.read(notebookControllerProvider).requireValue;
    expect(
      refreshed.localEntries.any(
        (entry) => entry.key == _fixtureVocabulary.key,
      ),
      isTrue,
    );
  });

  test('18. Repeated refresh does not duplicate local item', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final container = _container(store, _RecordingNotebookRepository());
    addTearDown(container.dispose);
    await container.read(notebookControllerProvider.future);
    final controller = container.read(notebookControllerProvider.notifier);

    await controller.retry();
    await controller.retry();
    final matches = container
        .read(notebookControllerProvider)
        .requireValue
        .localEntries
        .where((entry) => entry.key == _fixtureVocabulary.key);
    expect(matches, hasLength(1));
  });

  test('19. Notebook search finds local item', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureKanji);
    final container = _container(store, _RecordingNotebookRepository());
    addTearDown(container.dispose);
    final notebook = await container.read(notebookControllerProvider.future);
    final localCollection = notebook.collections.firstWhere(
      (collection) => collection.source == NotebookDataSource.fixture,
    );
    await container
        .read(notebookControllerProvider.notifier)
        .selectCollection(localCollection);

    container.read(notebookControllerProvider.notifier).search('かん');
    final state = container.read(notebookControllerProvider).requireValue;
    expect(state.visibleEntries.single.key, _fixtureKanji.key);
  });

  test('20. Notebook search finds already-loaded live item', () async {
    final container = _container(
      TestJsonPreferenceStore(),
      _RecordingNotebookRepository(),
    );
    addTearDown(container.dispose);
    await container.read(notebookControllerProvider.future);

    container.read(notebookControllerProvider.notifier).search('約束');
    final state = container.read(notebookControllerProvider).requireValue;
    expect(state.visibleEntries.single.key, _liveEntry.key);
  });

  testWidgets('21. Malformed entryKey fails safely without Backend call', (
    tester,
  ) async {
    final live = _RecordingNotebookRepository();
    await _pumpDetail(tester, entryKey: 'fixture:vocabulary', live: live);

    expect(
      find.byKey(const ValueKey<String>('notebook_entry_unavailable')),
      findsOneWidget,
    );
    expect(live.totalCalls, 0);
  });

  testWidgets('22. Missing local detail fails safely', (tester) async {
    final live = _RecordingNotebookRepository();
    await _pumpDetail(
      tester,
      entryKey: NotebookEntryKey.fixture(
        contentType: NotebookContentType.vocabulary,
        stableKey: 'removed-item',
      ).encoded,
      live: live,
    );

    expect(
      find.byKey(const ValueKey<String>('notebook_entry_unavailable')),
      findsOneWidget,
    );
    expect(live.totalCalls, 0);
  });

  testWidgets('23. Local detail never invokes Backend', (tester) async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final live = _RecordingNotebookRepository();
    await _pumpDetail(
      tester,
      entryKey: _fixtureVocabulary.key.encoded,
      live: live,
      store: store,
    );

    expect(
      find.byKey(const ValueKey<String>('notebook_entry_detail_view')),
      findsOneWidget,
    );
    expect(find.text(_fixtureVocabulary.term), findsOneWidget);
    expect(live.totalCalls, 0);
  });

  testWidgets('24. Live detail path uses typed live identity', (tester) async {
    final live = _RecordingNotebookRepository();
    await _pumpDetail(tester, entryKey: _liveEntry.key.encoded, live: live);

    expect(
      find.byKey(const ValueKey<String>('notebook_entry_detail_view')),
      findsOneWidget,
    );
    expect(find.text(_liveEntry.term), findsOneWidget);
    expect(_liveEntry.key.origin, NotebookItemOrigin.live);
    expect(_liveEntry.key.liveNoteEntryId, 901);
  });

  test('25. Local collection key never reaches live list loading', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final live = _RecordingNotebookRepository(
      collections: const <NotebookCollection>[],
      entries: const <NotebookEntry>[],
    );
    final container = _container(store, live);
    addTearDown(container.dispose);

    final notebook = await container.read(notebookControllerProvider.future);
    expect(notebook.selectedCollection?.source, NotebookDataSource.fixture);
    expect(live.loadEntryCalls, 0);
    expect(live.lastCollectionId, isNull);
  });

  test('26. Manual entry rejects local collection identity', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureVocabulary);
    final live = _RecordingNotebookRepository(
      collections: const <NotebookCollection>[],
      entries: const <NotebookEntry>[],
    );
    final container = _container(store, live);
    addTearDown(container.dispose);
    await container.read(notebookControllerProvider.future);

    final added = await container
        .read(notebookControllerProvider.notifier)
        .addManualEntry(word: '例', meaning: 'Ví dụ');
    expect(added, isFalse);
    expect(live.manualEntryCalls, 0);
  });

  test('27. Deleting live item uses verified live entry path', () async {
    final live = _RecordingNotebookRepository();
    final container = _container(TestJsonPreferenceStore(), live);
    addTearDown(container.dispose);
    final state = await container.read(notebookControllerProvider.future);

    final removed = await container
        .read(notebookControllerProvider.notifier)
        .removeEntry(state.liveEntries.single);
    expect(removed, isTrue);
    expect(live.removeCalls, 1);
    expect(live.lastRemovedKey, _liveEntry.key);
  });

  test(
    '28. Backend delete failure does not falsely remove live item',
    () async {
      final live = _RecordingNotebookRepository(
        deleteError: StateError('delete failed'),
      );
      final container = _container(TestJsonPreferenceStore(), live);
      addTearDown(container.dispose);
      final state = await container.read(notebookControllerProvider.future);

      final removed = await container
          .read(notebookControllerProvider.notifier)
          .removeEntry(state.liveEntries.single);
      final after = container.read(notebookControllerProvider).requireValue;
      expect(removed, isFalse);
      expect(after.liveEntries.single.key, _liveEntry.key);
      expect(after.mutationError, isNotNull);
    },
  );

  test('29. Restart preserves the local Notebook snapshot', () async {
    final store = TestJsonPreferenceStore();
    final first = _container(store, _RecordingNotebookRepository());
    await first
        .read(demoNotebookControllerProvider.notifier)
        .saveEntry(_fixtureGrammar);
    first.dispose();

    final restarted = _container(store, _RecordingNotebookRepository());
    addTearDown(restarted.dispose);
    final notebook = await restarted.read(notebookControllerProvider.future);
    expect(notebook.localEntries.single.key, _fixtureGrammar.key);
  });

  test('30. Local and live sources recover independently', () async {
    final unavailableLocal = _container(
      TestJsonPreferenceStore(failReads: true),
      _RecordingNotebookRepository(),
    );
    final liveOnly = await unavailableLocal.read(
      notebookControllerProvider.future,
    );
    expect(liveOnly.liveEntries.single.key, _liveEntry.key);
    unavailableLocal.dispose();

    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureKanji);
    final unavailableLive = _container(
      store,
      _RecordingNotebookRepository(failCollections: true),
    );
    addTearDown(unavailableLive.dispose);
    final localOnly = await unavailableLive.read(
      notebookControllerProvider.future,
    );
    expect(localOnly.localEntries.single.key, _fixtureKanji.key);
  });
}

const _fixtureVocabulary = NotebookFixtureDraft(
  stableKey: 'n4-lesson-19:vocabulary:0:経験',
  contentType: NotebookContentType.vocabulary,
  term: '経験',
  reading: 'けいけん',
  meaning: 'Kinh nghiệm',
  jlptLevel: 'N4',
);

const _fixtureKanji = NotebookFixtureDraft(
  stableKey: 'fixture-kanji-間',
  contentType: NotebookContentType.kanji,
  term: '間',
  reading: 'かん',
  meaning: 'Khoảng, giữa',
  jlptLevel: 'N4',
);

const _fixtureGrammar = NotebookFixtureDraft(
  stableKey: 'n4-lesson-19:grammar:0:〜たことがある',
  contentType: NotebookContentType.grammar,
  term: '〜たことがある',
  meaning: 'Đã từng làm gì',
  jlptLevel: 'N4',
);

const _liveVocabulary = NotebookVocabularyDraft(
  routeKey: 'live-vocabulary-401',
  remoteId: 401,
  term: '約束',
  reading: 'やくそく',
  meaning: 'Lời hứa',
  jlptLevel: 'N4',
);

const _liveCollection = NotebookCollection(
  routeKey: 'remote-list-12',
  remoteId: 12,
  name: 'Live N4',
  entryCount: 1,
  createdAt: null,
  source: NotebookDataSource.remote,
);

final _liveEntry = NotebookEntry(
  key: NotebookEntryKey.live(
    contentType: NotebookContentType.vocabulary,
    noteEntryId: 901,
  ),
  remoteNoteEntryId: 901,
  reviewCardId: 902,
  contentType: NotebookContentType.vocabulary,
  term: '約束',
  reading: 'やくそく',
  meaning: 'Lời hứa',
  addedAt: DateTime.utc(2026, 10, 3),
);

ProviderContainer _container(
  TestJsonPreferenceStore store,
  NotebookRepository live,
) {
  return ProviderContainer(
    overrides: [
      jsonPreferenceStoreProvider.overrideWithValue(store),
      notebookRepositoryProvider.overrideWithValue(live),
    ],
  );
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required String entryKey,
  required NotebookRepository live,
  TestJsonPreferenceStore? store,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jsonPreferenceStoreProvider.overrideWithValue(
          store ?? TestJsonPreferenceStore(),
        ),
        notebookRepositoryProvider.overrideWithValue(live),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotebookEntryDetailScreen(entryKey: entryKey),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingNotebookRepository implements NotebookRepository {
  _RecordingNotebookRepository({
    this.failCollections = false,
    this.failEntries = false,
    this.deleteError,
    List<NotebookCollection>? collections,
    List<NotebookEntry>? entries,
  }) : collections = collections ?? <NotebookCollection>[_liveCollection],
       entries = entries ?? <NotebookEntry>[_liveEntry];

  final bool failCollections;
  final bool failEntries;
  final Object? deleteError;
  final List<NotebookCollection> collections;
  final List<NotebookEntry> entries;
  int loadCollectionCalls = 0;
  int loadEntryCalls = 0;
  int bookmarkCalls = 0;
  int manualEntryCalls = 0;
  int removeCalls = 0;
  int? lastVocabularyId;
  int? lastCollectionId;
  NotebookEntryKey? lastRemovedKey;

  int get totalCalls =>
      loadCollectionCalls +
      loadEntryCalls +
      bookmarkCalls +
      manualEntryCalls +
      removeCalls;

  @override
  Future<List<NotebookCollection>> loadCollections() async {
    loadCollectionCalls++;
    if (failCollections) throw StateError('Live collections unavailable.');
    return List<NotebookCollection>.unmodifiable(collections);
  }

  @override
  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection) async {
    loadEntryCalls++;
    lastCollectionId = collection.remoteId;
    if (failEntries) throw StateError('Live entries unavailable.');
    return List<NotebookEntry>.unmodifiable(entries);
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  }) async {
    bookmarkCalls++;
    lastVocabularyId = vocabulary.remoteId;
    lastCollectionId = collection.remoteId;
    return NotebookBookmark(
      noteEntryId: 901,
      collectionRouteKey: collection.routeKey,
      collectionName: collection.name,
    );
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) async {
    manualEntryCalls++;
    lastCollectionId = collection.remoteId;
    return NotebookEntry(
      key: NotebookEntryKey.live(
        contentType: NotebookContentType.manual,
        noteEntryId: 903,
      ),
      remoteNoteEntryId: 903,
      contentType: NotebookContentType.manual,
      term: word,
      reading: reading,
      meaning: meaning,
      note: note,
      addedAt: DateTime.utc(2026, 10, 3),
    );
  }

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) async => _liveCollection;

  @override
  Future<bool> isVocabularySaved(String vocabularyRouteKey) async => false;

  @override
  Stream<Set<String>> watchSavedVocabularyKeys() =>
      Stream<Set<String>>.value(const <String>{});

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    removeCalls++;
    lastRemovedKey = entry.key;
    if (deleteError != null) throw deleteError!;
    entries.removeWhere((candidate) => candidate.key == entry.key);
  }
}
