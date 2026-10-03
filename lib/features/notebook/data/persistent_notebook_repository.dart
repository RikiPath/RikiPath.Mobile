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
    if (collection.source != NotebookDataSource.remote ||
        collection.remoteId == null ||
        collection.remoteId! <= 0) {
      throw ArgumentError.value(
        collection.routeKey,
        'collection',
        'Manual entries require a verified LIVE notebook collection.',
      );
    }
    final ownerUserId = await _ownerUserId();
    final entry = await _remote.addManualEntry(
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
    final vocabularyId = vocabulary.remoteId;
    if (collection.source != NotebookDataSource.remote ||
        collection.remoteId == null ||
        collection.remoteId! <= 0 ||
        vocabularyId == null ||
        vocabularyId <= 0) {
      throw ArgumentError(
        'A LIVE collection and positive backend vocabulary ID are required.',
      );
    }
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

    final bookmark = await _remote.bookmarkVocabulary(
      vocabularyEntryId: vocabularyId,
      collection: collection,
    );

    final noteEntryId = bookmark.noteEntryId;
    if (noteEntryId == null || noteEntryId <= 0) {
      throw StateError('LIVE bookmark response omitted a note-entry ID.');
    }
    final entry = NotebookEntry(
      key: NotebookEntryKey.live(
        contentType: NotebookContentType.vocabulary,
        noteEntryId: noteEntryId,
      ),
      remoteNoteEntryId: noteEntryId,
      contentType: NotebookContentType.vocabulary,
      term: vocabulary.term,
      reading: _optionalText(vocabulary.reading),
      meaning: vocabulary.meaning,
      addedAt: DateTime.now().toUtc(),
      vocabularyRouteKey: vocabulary.routeKey,
    );
    await _local.saveEntry(ownerUserId, collection, entry);
    return bookmark;
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    if (entry.origin != NotebookItemOrigin.live ||
        entry.key.liveNoteEntryId == null ||
        entry.remoteNoteEntryId != entry.key.liveNoteEntryId) {
      throw ArgumentError.value(
        entry.routeKey,
        'entry',
        'A verified LIVE notebook entry is required.',
      );
    }
    final ownerUserId = await _ownerUserId();
    await _remote.removeEntry(entry);
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
