import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/database/app_database.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_local_store.dart';
import 'package:rikipath_mobile/features/notebook/data/persistent_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

void main() {
  late AppDatabase database;
  late _FakeNotebookRemote remote;
  late PersistentNotebookRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = _FakeNotebookRemote();
    repository = PersistentNotebookRepository(
      remote,
      NotebookLocalStore(database),
      () async => 42,
    );
  });

  tearDown(() => database.close());

  test(
    'saves once by stable entryKey and prevents duplicate bookmarks',
    () async {
      final collection = _remoteCollection();
      final vocabulary = _remoteVocabulary();

      await repository.bookmarkVocabulary(
        vocabulary: vocabulary,
        collection: collection,
      );
      await repository.bookmarkVocabulary(
        vocabulary: vocabulary,
        collection: collection,
      );

      expect(remote.bookmarkCalls, 1);
      expect(await repository.isVocabularySaved(vocabulary.routeKey), isTrue);
      expect(
        await repository.watchSavedVocabularyKeys().first,
        contains(vocabulary.routeKey),
      );
      final entries = await repository.loadEntries(collection);
      expect(entries, hasLength(1));
      expect(entries.single.vocabularyRouteKey, vocabulary.routeKey);
      expect(entries.single.remoteNoteEntryId, 91);
    },
  );

  test(
    'cached Notebook survives repository recreation and remote failure',
    () async {
      final collection = _remoteCollection();
      await repository.bookmarkVocabulary(
        vocabulary: _remoteVocabulary(),
        collection: collection,
      );

      final restartedRemote = _FakeNotebookRemote(failReads: true);
      final restarted = PersistentNotebookRepository(
        restartedRemote,
        NotebookLocalStore(database),
        () async => 42,
      );

      final collections = await restarted.loadCollections();
      final entries = await restarted.loadEntries(collections.single);

      expect(collections.single.routeKey, collection.routeKey);
      expect(entries.single.term, '経験');
      expect(entries.single.reading, 'けいけん');
      expect(entries.single.meaning, 'Kinh nghiệm');
      expect(entries.single.vocabularyRouteKey, 'remote-7');
    },
  );

  test('remove updates the persisted source observed by Vocabulary', () async {
    final collection = _remoteCollection();
    final vocabulary = _remoteVocabulary();
    await repository.bookmarkVocabulary(
      vocabulary: vocabulary,
      collection: collection,
    );
    final entry = (await repository.loadEntries(collection)).single;

    await repository.removeEntry(entry);

    expect(remote.removedNoteEntryIds, <int>[91]);
    expect(await repository.isVocabularySaved(vocabulary.routeKey), isFalse);
    expect(await repository.loadEntries(collection), isEmpty);
    expect(
      await repository.watchSavedVocabularyKeys().first,
      isNot(contains(vocabulary.routeKey)),
    );
  });

  test('local fixture identity is rejected before a live mutation', () async {
    const collection = NotebookCollection(
      routeKey: 'local-default',
      remoteId: null,
      name: 'Mặc định',
      entryCount: 0,
      createdAt: null,
      source: NotebookDataSource.local,
    );
    const vocabulary = NotebookVocabularyDraft(
      routeKey: 'fixture-keiken',
      remoteId: null,
      term: '経験',
      reading: 'けいけん',
      meaning: 'Kinh nghiệm',
      jlptLevel: 'N3',
    );

    await expectLater(
      repository.bookmarkVocabulary(
        vocabulary: vocabulary,
        collection: collection,
      ),
      throwsA(isA<ArgumentError>()),
    );
    final entries = await repository.loadEntries(collection);

    expect(remote.bookmarkCalls, 0);
    expect(entries, isEmpty);
  });

  test(
    'remote list and entries are cached for deterministic offline search',
    () async {
      remote.collections = <NotebookCollection>[_remoteCollection()];
      remote.entries = <NotebookEntry>[
        NotebookEntry(
          key: NotebookEntryKey.live(
            contentType: NotebookContentType.vocabulary,
            noteEntryId: 55,
          ),
          remoteNoteEntryId: 55,
          contentType: NotebookContentType.vocabulary,
          term: '改善',
          reading: 'かいぜん',
          meaning: 'Cải thiện',
          addedAt: DateTime.utc(2026, 9, 20),
        ),
      ];

      final collection = (await repository.loadCollections()).single;
      await repository.loadEntries(collection);
      remote.failReads = true;

      final offline = await repository.loadEntries(collection);
      expect(offline.single.term, '改善');
      expect(offline.single.reading, 'かいぜん');
      expect(offline.single.meaning, 'Cải thiện');
    },
  );
}

NotebookCollection _remoteCollection() => NotebookCollection(
  routeKey: 'remote-list-3',
  remoteId: 3,
  name: 'JLPT N3',
  entryCount: 0,
  createdAt: DateTime.utc(2026, 9, 20),
  source: NotebookDataSource.remote,
);

const NotebookVocabularyDraft _vocabulary = NotebookVocabularyDraft(
  routeKey: 'remote-7',
  remoteId: 7,
  term: '経験',
  reading: 'けいけん',
  meaning: 'Kinh nghiệm',
  jlptLevel: 'N3',
);

NotebookVocabularyDraft _remoteVocabulary() => _vocabulary;

class _FakeNotebookRemote implements NotebookRemoteDataSource {
  _FakeNotebookRemote({this.failReads = false});

  bool failReads;
  List<NotebookCollection> collections = <NotebookCollection>[];
  List<NotebookEntry> entries = <NotebookEntry>[];
  int bookmarkCalls = 0;
  final List<int> removedNoteEntryIds = <int>[];

  @override
  Future<List<NotebookCollection>> loadCollections() async {
    if (failReads) throw const NetworkError();
    return List<NotebookCollection>.unmodifiable(collections);
  }

  @override
  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection) async {
    if (failReads) throw const NetworkError();
    return List<NotebookEntry>.unmodifiable(entries);
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
  }) async {
    bookmarkCalls += 1;
    expect(vocabularyEntryId, 7);
    expect(collection.remoteId, 3);
    entries = <NotebookEntry>[
      NotebookEntry(
        key: NotebookEntryKey.live(
          contentType: NotebookContentType.vocabulary,
          noteEntryId: 91,
        ),
        remoteNoteEntryId: 91,
        contentType: NotebookContentType.vocabulary,
        term: '経験',
        reading: 'けいけん',
        meaning: 'Kinh nghiệm',
        addedAt: DateTime.utc(2026, 9, 20),
      ),
    ];
    return NotebookBookmark(
      noteEntryId: 91,
      collectionRouteKey: collection.routeKey,
      collectionName: collection.name,
    );
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    removedNoteEntryIds.add(entry.remoteNoteEntryId!);
    entries.removeWhere(
      (candidate) => candidate.remoteNoteEntryId == entry.remoteNoteEntryId,
    );
  }
}
