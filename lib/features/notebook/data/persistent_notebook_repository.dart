import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_local_store.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

typedef NotebookOwnerIdLoader = Future<int?> Function();

class PersistentNotebookRepository implements NotebookRepository {
  const PersistentNotebookRepository(
    this._remote,
    this._local,
    this._loadOwnerUserId,
  );

  final NotebookRemoteDataSource _remote;
  final NotebookLocalStore _local;
  final NotebookOwnerIdLoader _loadOwnerUserId;

  @override
  Stream<Set<String>> watchSavedVocabularyKeys() async* {
    final ownerUserId = await _ownerUserId();
    yield* _local.watchSavedVocabularyKeys(ownerUserId);
  }

  @override
  Future<bool> isVocabularySaved(String vocabularyRouteKey) async {
    final ownerUserId = await _ownerUserId();
    return await _local.findByVocabularyRouteKey(
          ownerUserId,
          vocabularyRouteKey,
        ) !=
        null;
  }

  @override
  Future<List<NotebookCollection>> loadCollections() async {
    final ownerUserId = await _ownerUserId();
    try {
      final remoteCollections = await _remote.loadCollections();
      await _local.cacheCollections(ownerUserId, remoteCollections);
      return await _local.loadCollections(ownerUserId);
    } catch (_) {
      final cached = await _local.loadCollections(ownerUserId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection) async {
    final ownerUserId = await _ownerUserId();
    if (collection.remoteId == null) {
      return _local.loadEntries(ownerUserId, collection.routeKey);
    }

    try {
      final remoteEntries = await _remote.loadEntries(collection);
      await _local.replaceEntries(ownerUserId, collection, remoteEntries);
    } catch (_) {
      if (!await _local.hasEntriesSnapshot(ownerUserId, collection.routeKey)) {
        rethrow;
      }
      // A previously loaded collection remains readable/searchable offline.
    }
    return _local.loadEntries(ownerUserId, collection.routeKey);
  }

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) async {
    final ownerUserId = await _ownerUserId();
    final created = await _remote.createCollection(
      name: name,
      description: description,
    );
    await _local.saveCollection(ownerUserId, created);
    return created;
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) async {
    final ownerUserId = await _ownerUserId();
    final normalizedReading = _optionalText(reading);
    final normalizedNote = _optionalText(note);
    final entry = collection.remoteId == null
        ? NotebookEntry(
            routeKey: 'local-manual-${DateTime.now().microsecondsSinceEpoch}',
            remoteNoteEntryId: null,
            contentType: NotebookContentType.manual,
            term: word.trim(),
            reading: normalizedReading,
            meaning: meaning.trim(),
            note: normalizedNote,
            addedAt: DateTime.now().toUtc(),
            source: NotebookDataSource.local,
          )
        : await _remote.addManualEntry(
            collection: collection,
            word: word,
            reading: reading,
            meaning: meaning,
            note: note,
          );
    await _local.saveEntry(ownerUserId, collection, entry);
    return entry;
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  }) async {
    final ownerUserId = await _ownerUserId();
    final existing = await _local.findByVocabularyRouteKey(
      ownerUserId,
      vocabulary.routeKey,
    );
    if (existing != null) {
      return NotebookBookmark(
        noteEntryId: existing.remoteNoteEntryId,
        collectionRouteKey: collection.routeKey,
        collectionName: collection.name,
      );
    }

    NotebookBookmark bookmark;
    if (collection.remoteId != null && vocabulary.remoteId != null) {
      bookmark = await _remote.bookmarkVocabulary(
        vocabularyEntryId: vocabulary.remoteId!,
        collection: collection,
      );
    } else {
      bookmark = NotebookBookmark(
        noteEntryId: null,
        collectionRouteKey: collection.routeKey,
        collectionName: collection.name,
      );
    }

    final noteEntryId = bookmark.noteEntryId;
    final entry = NotebookEntry(
      routeKey: noteEntryId == null
          ? 'local-vocabulary-${Uri.encodeComponent(vocabulary.routeKey)}'
          : 'remote-note-$noteEntryId',
      remoteNoteEntryId: noteEntryId,
      contentType: NotebookContentType.vocabulary,
      term: vocabulary.term,
      reading: _optionalText(vocabulary.reading),
      meaning: vocabulary.meaning,
      addedAt: DateTime.now().toUtc(),
      source: noteEntryId == null
          ? NotebookDataSource.local
          : NotebookDataSource.remote,
      vocabularyRouteKey: vocabulary.routeKey,
    );
    await _local.saveEntry(ownerUserId, collection, entry);
    return bookmark;
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    final ownerUserId = await _ownerUserId();
    if (entry.remoteNoteEntryId != null) {
      await _remote.removeEntry(entry);
    }
    await _local.removeEntry(ownerUserId, entry);
  }

  Future<int> _ownerUserId() async {
    final userId = await _loadOwnerUserId();
    if (userId == null || userId <= 0) {
      throw const UnauthorizedError();
    }
    return userId;
  }

  String? _optionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
