import 'package:drift/drift.dart';
import 'package:rikipath_mobile/core/database/app_database.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

class NotebookLocalStore {
  const NotebookLocalStore(this._database);

  final AppDatabase _database;

  Future<List<NotebookCollection>> loadCollections(int ownerUserId) async {
    final prefix = _ownerPrefix(ownerUserId);
    final rows =
        await (_database.select(_database.vocabularyLists)
              ..where((row) => row.id.like('$prefix%'))
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();
    return rows
        .map((row) => _collectionFromRow(ownerUserId, row))
        .toList(growable: false);
  }

  Future<List<NotebookEntry>> loadEntries(
    int ownerUserId,
    String collectionRouteKey,
  ) async {
    final storageListId = _storageKey(ownerUserId, collectionRouteKey);
    final rows =
        await (_database.select(_database.personalVocabularyEntries)
              ..where((row) => row.listId.equals(storageListId))
              ..orderBy([
                (row) => OrderingTerm.desc(row.addedAt),
                (row) => OrderingTerm.desc(row.updatedAt),
              ]))
            .get();
    return rows
        .map((row) => _entryFromRow(ownerUserId, row))
        .toList(growable: false);
  }

  Future<bool> hasEntriesSnapshot(
    int ownerUserId,
    String collectionRouteKey,
  ) async {
    final storageListId = _storageKey(ownerUserId, collectionRouteKey);
    final row =
        await (_database.select(_database.vocabularyLists)
              ..where((candidate) => candidate.id.equals(storageListId)))
            .getSingleOrNull();
    return row?.entriesCached ?? false;
  }

  Future<void> cacheCollections(
    int ownerUserId,
    List<NotebookCollection> collections,
  ) async {
    await _database.transaction(() async {
      for (final collection in collections) {
        await saveCollection(ownerUserId, collection);
      }
    });
  }

  Future<void> saveCollection(
    int ownerUserId,
    NotebookCollection collection,
  ) async {
    await _database
        .into(_database.vocabularyLists)
        .insertOnConflictUpdate(
          VocabularyListsCompanion(
            id: Value(_storageKey(ownerUserId, collection.routeKey)),
            remoteId: Value(collection.remoteId),
            name: Value(collection.name),
            description: Value(collection.description),
            source: Value(collection.source.name),
            createdAt: Value(collection.createdAt),
            entryCount: Value(collection.entryCount),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(false),
          ),
        );
  }

  Future<void> replaceEntries(
    int ownerUserId,
    NotebookCollection collection,
    List<NotebookEntry> entries,
  ) async {
    final existing = await loadEntries(ownerUserId, collection.routeKey);
    final stableKeys = <String, String?>{
      for (final entry in existing) entry.routeKey: entry.vocabularyRouteKey,
    };
    final storageListId = _storageKey(ownerUserId, collection.routeKey);

    await _database.transaction(() async {
      await (_database.delete(_database.personalVocabularyEntries)..where(
            (row) =>
                row.listId.equals(storageListId) &
                row.source.equals(NotebookDataSource.remote.name),
          ))
          .go();
      for (final entry in entries) {
        await _saveEntry(
          ownerUserId,
          collection.routeKey,
          _withVocabularyRouteKey(
            entry,
            entry.vocabularyRouteKey ?? stableKeys[entry.routeKey],
          ),
        );
      }
      await _updateEntryCount(ownerUserId, collection.routeKey);
      await _markEntriesCached(ownerUserId, collection.routeKey);
    });
  }

  Future<void> saveEntry(
    int ownerUserId,
    NotebookCollection collection,
    NotebookEntry entry,
  ) async {
    await _database.transaction(() async {
      await saveCollection(ownerUserId, collection);
      await _saveEntry(ownerUserId, collection.routeKey, entry);
      await _updateEntryCount(ownerUserId, collection.routeKey);
      await _markEntriesCached(ownerUserId, collection.routeKey);
    });
  }

  Future<void> removeEntry(int ownerUserId, NotebookEntry entry) async {
    final storageEntryId = _storageKey(ownerUserId, entry.routeKey);
    final row =
        await (_database.select(_database.personalVocabularyEntries)
              ..where((candidate) => candidate.id.equals(storageEntryId)))
            .getSingleOrNull();
    if (row == null) return;

    await _database.transaction(() async {
      await (_database.delete(
        _database.personalVocabularyEntries,
      )..where((candidate) => candidate.id.equals(storageEntryId))).go();
      final storageListId = row.listId;
      if (storageListId != null) {
        await _updateEntryCount(
          ownerUserId,
          _routeKey(ownerUserId, storageListId),
        );
      }
    });
  }

  Future<NotebookEntry?> findByVocabularyRouteKey(
    int ownerUserId,
    String vocabularyRouteKey,
  ) async {
    final prefix = _ownerPrefix(ownerUserId);
    final row =
        await (_database.select(_database.personalVocabularyEntries)..where(
              (candidate) =>
                  candidate.id.like('$prefix%') &
                  candidate.sourceVocabularyId.equals(vocabularyRouteKey),
            ))
            .getSingleOrNull();
    return row == null ? null : _entryFromRow(ownerUserId, row);
  }

  Stream<Set<String>> watchSavedVocabularyKeys(int ownerUserId) {
    final prefix = _ownerPrefix(ownerUserId);
    final query = _database.select(_database.personalVocabularyEntries)
      ..where(
        (row) => row.id.like('$prefix%') & row.sourceVocabularyId.isNotNull(),
      );
    return query.watch().map(
      (rows) =>
          rows.map((row) => row.sourceVocabularyId).whereType<String>().toSet(),
    );
  }

  Future<void> _saveEntry(
    int ownerUserId,
    String collectionRouteKey,
    NotebookEntry entry,
  ) async {
    await _database
        .into(_database.personalVocabularyEntries)
        .insertOnConflictUpdate(
          PersonalVocabularyEntriesCompanion(
            id: Value(_storageKey(ownerUserId, entry.routeKey)),
            remoteNoteEntryId: Value(entry.remoteNoteEntryId),
            reviewItemId: Value(entry.reviewCardId),
            sourceVocabularyId: Value(entry.vocabularyRouteKey),
            listId: Value(_storageKey(ownerUserId, collectionRouteKey)),
            contentType: Value(entry.contentType.name),
            source: Value(entry.source.name),
            word: Value(entry.term),
            reading: Value(entry.reading),
            meaning: Value(entry.meaning),
            note: Value(entry.note),
            addedAt: Value(entry.addedAt),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(false),
          ),
        );
  }

  Future<void> _updateEntryCount(
    int ownerUserId,
    String collectionRouteKey,
  ) async {
    final storageListId = _storageKey(ownerUserId, collectionRouteKey);
    final countExpression = _database.personalVocabularyEntries.id.count();
    final countQuery = _database.selectOnly(_database.personalVocabularyEntries)
      ..addColumns([countExpression]);
    countQuery.where(
      _database.personalVocabularyEntries.listId.equals(storageListId),
    );
    final count = (await countQuery.getSingle()).read(countExpression) ?? 0;
    await (_database.update(_database.vocabularyLists)
          ..where((row) => row.id.equals(storageListId)))
        .write(VocabularyListsCompanion(entryCount: Value(count)));
  }

  Future<void> _markEntriesCached(
    int ownerUserId,
    String collectionRouteKey,
  ) async {
    final storageListId = _storageKey(ownerUserId, collectionRouteKey);
    await (_database.update(_database.vocabularyLists)
          ..where((row) => row.id.equals(storageListId)))
        .write(const VocabularyListsCompanion(entriesCached: Value(true)));
  }

  NotebookCollection _collectionFromRow(int ownerUserId, VocabularyList row) {
    return NotebookCollection(
      routeKey: _routeKey(ownerUserId, row.id),
      remoteId: row.remoteId,
      name: row.name,
      description: row.description,
      entryCount: row.entryCount,
      createdAt: row.createdAt,
      source: _dataSource(row.source),
    );
  }

  NotebookEntry _entryFromRow(int ownerUserId, PersonalVocabularyEntry row) {
    final contentType = _contentType(row.contentType);
    final source = _dataSource(row.source);
    final routeKey = _routeKey(ownerUserId, row.id);
    final key =
        source == NotebookDataSource.remote &&
            row.remoteNoteEntryId != null &&
            row.remoteNoteEntryId! > 0
        ? NotebookEntryKey.live(
            contentType: contentType,
            noteEntryId: row.remoteNoteEntryId!,
          )
        : NotebookEntryKey.fixture(
            contentType: contentType,
            stableKey:
                NotebookEntryKey.tryParse(routeKey)?.stableKey ?? routeKey,
          );
    return NotebookEntry(
      key: key,
      remoteNoteEntryId: row.remoteNoteEntryId,
      reviewCardId: row.reviewItemId,
      contentType: contentType,
      term: row.word,
      reading: row.reading,
      meaning: row.meaning,
      note: row.note,
      addedAt: row.addedAt ?? row.updatedAt,
      vocabularyRouteKey: row.sourceVocabularyId,
    );
  }

  NotebookEntry _withVocabularyRouteKey(
    NotebookEntry entry,
    String? vocabularyRouteKey,
  ) {
    return entry.copyWith(vocabularyRouteKey: vocabularyRouteKey);
  }

  NotebookDataSource _dataSource(String value) {
    return NotebookDataSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => NotebookDataSource.local,
    );
  }

  NotebookContentType _contentType(String value) {
    return NotebookContentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotebookContentType.unknown,
    );
  }

  String _ownerPrefix(int ownerUserId) => 'user-$ownerUserId::';

  String _storageKey(int ownerUserId, String routeKey) =>
      '${_ownerPrefix(ownerUserId)}$routeKey';

  String _routeKey(int ownerUserId, String storageKey) {
    final prefix = _ownerPrefix(ownerUserId);
    return storageKey.startsWith(prefix)
        ? storageKey.substring(prefix.length)
        : storageKey;
  }
}
