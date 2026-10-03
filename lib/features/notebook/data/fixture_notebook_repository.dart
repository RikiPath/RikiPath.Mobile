import 'dart:async';

import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

/// Explicit test/demo data source. Production providers never fall back here.
class FixtureNotebookRepository implements NotebookRepository {
  FixtureNotebookRepository({
    List<NotebookCollection>? collections,
    Map<String, List<NotebookEntry>>? entries,
  }) : _collections = List<NotebookCollection>.of(
         collections ?? defaultCollections,
       ),
       _entries = <String, List<NotebookEntry>>{
         for (final item in (entries ?? defaultEntries).entries)
           item.key: List<NotebookEntry>.of(item.value),
       };

  static const NotebookCollection defaultCollection = NotebookCollection(
    routeKey: 'fixture-list-n3',
    remoteId: null,
    name: 'N3 khó nhớ · dữ liệu mẫu',
    description: 'Bộ từ minh họa cục bộ',
    entryCount: 3,
    createdAt: null,
    source: NotebookDataSource.fixture,
  );

  static const List<NotebookCollection> defaultCollections =
      <NotebookCollection>[defaultCollection];

  static final Map<String, List<NotebookEntry>> defaultEntries =
      <String, List<NotebookEntry>>{
        defaultCollection.routeKey: <NotebookEntry>[
          NotebookEntry(
            key: NotebookEntryKey.fixture(
              contentType: NotebookContentType.vocabulary,
              stableKey: 'fixture-note-keiken',
            ),
            remoteNoteEntryId: null,
            contentType: NotebookContentType.vocabulary,
            term: '経験',
            reading: 'けいけん',
            meaning: 'Kinh nghiệm',
            note: 'Dữ liệu minh họa cục bộ',
            addedAt: DateTime.utc(2026, 9, 12),
            vocabularyRouteKey: 'fixture-keiken',
          ),
          NotebookEntry(
            key: NotebookEntryKey.fixture(
              contentType: NotebookContentType.vocabulary,
              stableKey: 'fixture-note-kaizen',
            ),
            remoteNoteEntryId: null,
            contentType: NotebookContentType.vocabulary,
            term: '改善',
            reading: 'かいぜん',
            meaning: 'Cải thiện, cải tiến',
            addedAt: DateTime.utc(2026, 9, 11),
            vocabularyRouteKey: 'fixture-kaizen',
          ),
          NotebookEntry(
            key: NotebookEntryKey.fixture(
              contentType: NotebookContentType.manual,
              stableKey: 'fixture-note-yakusoku',
            ),
            remoteNoteEntryId: null,
            contentType: NotebookContentType.manual,
            term: '約束',
            reading: 'やくそく',
            meaning: 'Lời hứa, cuộc hẹn',
            addedAt: DateTime.utc(2026, 9, 10),
          ),
        ],
      };

  final List<NotebookCollection> _collections;
  final Map<String, List<NotebookEntry>> _entries;
  final StreamController<Set<String>> _savedKeysController =
      StreamController<Set<String>>.broadcast();

  @override
  Stream<Set<String>> watchSavedVocabularyKeys() async* {
    yield _savedVocabularyKeys();
    yield* _savedKeysController.stream;
  }

  @override
  Future<bool> isVocabularySaved(String vocabularyRouteKey) async {
    return _savedVocabularyKeys().contains(vocabularyRouteKey);
  }

  @override
  Future<List<NotebookCollection>> loadCollections() async =>
      List<NotebookCollection>.unmodifiable(_collections);

  @override
  Future<List<NotebookEntry>> loadEntries(
    NotebookCollection collection,
  ) async => List<NotebookEntry>.unmodifiable(
    _entries[collection.routeKey] ?? const <NotebookEntry>[],
  );

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) {
    throw UnsupportedError(
      'Fixture collection mutation is not production API.',
    );
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) {
    throw UnsupportedError('Fixture entry mutation is not production API.');
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  }) async {
    final existing = _entries[collection.routeKey] ?? <NotebookEntry>[];
    NotebookEntry? duplicate;
    for (final entry in existing) {
      if (entry.vocabularyRouteKey == vocabulary.routeKey) {
        duplicate = entry;
        break;
      }
    }
    if (duplicate == null) {
      existing.insert(
        0,
        NotebookEntry(
          key: NotebookEntryKey.fixture(
            contentType: NotebookContentType.vocabulary,
            stableKey: vocabulary.routeKey,
          ),
          remoteNoteEntryId: null,
          contentType: NotebookContentType.vocabulary,
          term: vocabulary.term,
          reading: vocabulary.reading,
          meaning: vocabulary.meaning,
          addedAt: DateTime.now().toUtc(),
          vocabularyRouteKey: vocabulary.routeKey,
        ),
      );
      _entries[collection.routeKey] = existing;
      _savedKeysController.add(_savedVocabularyKeys());
    }
    return NotebookBookmark(
      noteEntryId: duplicate?.remoteNoteEntryId,
      collectionRouteKey: collection.routeKey,
      collectionName: collection.name,
    );
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    for (final values in _entries.values) {
      values.removeWhere((item) => item.routeKey == entry.routeKey);
    }
    _savedKeysController.add(_savedVocabularyKeys());
  }

  Set<String> _savedVocabularyKeys() {
    return _entries.values
        .expand((entries) => entries)
        .map((entry) => entry.vocabularyRouteKey)
        .whereType<String>()
        .toSet();
  }
}
