import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_api_paths.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_dtos.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_mapper.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

class ApiNotebookRepository
    implements NotebookRemoteDataSource, LessonNotebookRemoteDataSource {
  const ApiNotebookRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<NotebookCollection>> loadCollections() async {
    final response = await _apiClient.get<Object?>(
      NotebookApiPaths.collections,
    );
    try {
      return readNotebookCollections(
        response.data,
      ).map(NotebookMapper.collectionFromRemote).toList(growable: false);
    } on FormatException {
      throw const UnknownError(
        message: 'The notebook list response did not match the contract.',
      );
    }
  }

  @override
  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection) async {
    final collectionId = _remoteCollectionId(collection);
    final response = await _apiClient.get<Object?>(
      NotebookApiPaths.entries(collectionId),
    );
    try {
      return readNotebookEntries(
        response.data,
      ).map(NotebookMapper.entryFromRemote).toList(growable: false);
    } on FormatException {
      throw const UnknownError(
        message: 'The notebook entries response did not match the contract.',
      );
    }
  }

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) async {
    final request = CreateNotebookCollectionRequestDto(
      name: name.trim(),
      description: _optionalText(description),
    );
    final response = await _apiClient.post<Object?>(
      NotebookApiPaths.collections,
      data: request.toJson(),
    );
    try {
      return NotebookMapper.collectionFromRemote(
        readNotebookCollection(response.data),
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The created notebook list did not match the contract.',
      );
    }
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) async {
    final request = AddManualNotebookEntryRequestDto(
      learnerNoteId: _remoteCollectionId(collection),
      word: word.trim(),
      reading: _optionalText(reading),
      meaning: meaning.trim(),
      note: _optionalText(note),
    );
    final response = await _apiClient.post<Object?>(
      NotebookApiPaths.manualEntry,
      data: request.toJson(),
    );
    try {
      return NotebookMapper.entryFromRemote(readNotebookEntry(response.data));
    } on FormatException {
      throw const UnknownError(
        message: 'The manual notebook entry did not match the contract.',
      );
    }
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required int vocabularyEntryId,
    required NotebookCollection collection,
  }) async {
    final request = BookmarkVocabularyRequestDto(
      learnerNoteId: _remoteCollectionId(collection),
      vocabularyId: vocabularyEntryId,
    );
    final response = await _apiClient.post<Object?>(
      NotebookApiPaths.bookmarkVocabulary,
      data: request.toJson(),
    );
    try {
      final entry = readNotebookEntry(response.data);
      return NotebookBookmark(
        noteEntryId: entry.noteEntryId,
        collectionRouteKey: collection.routeKey,
        collectionName: collection.name,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The vocabulary bookmark response did not match the contract.',
      );
    }
  }

  @override
  Future<NotebookBookmark> bookmarkKanji({
    required int kanjiId,
    required NotebookCollection collection,
  }) async {
    final request = BookmarkKanjiRequestDto(
      learnerNoteId: _remoteCollectionId(collection),
      kanjiId: kanjiId,
    );
    final response = await _apiClient.post<Object?>(
      NotebookApiPaths.bookmarkKanji,
      data: request.toJson(),
    );
    try {
      final entry = readNotebookEntry(response.data);
      return NotebookBookmark(
        noteEntryId: entry.noteEntryId,
        collectionRouteKey: collection.routeKey,
        collectionName: collection.name,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The Kanji bookmark response did not match the contract.',
      );
    }
  }

  @override
  Future<void> bookmarkGrammar(int grammarPatternId) async {
    if (grammarPatternId <= 0) {
      throw ArgumentError.value(grammarPatternId, 'grammarPatternId');
    }
    await _apiClient.post<Object?>(
      NotebookApiPaths.bookmarkGrammar(grammarPatternId),
    );
  }

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    if (entry.origin != NotebookItemOrigin.live) {
      throw ArgumentError.value(
        entry.origin,
        'entry.origin',
        'A LIVE notebook entry is required.',
      );
    }
    final noteEntryId = entry.key.liveNoteEntryId;
    if (noteEntryId == null ||
        noteEntryId <= 0 ||
        entry.remoteNoteEntryId != noteEntryId) {
      throw ArgumentError.value(
        entry.remoteNoteEntryId,
        'entry',
        'The typed LIVE key and remote note-entry ID must match.',
      );
    }
    await _apiClient.delete<Object?>(NotebookApiPaths.removeEntry(noteEntryId));
  }

  int _remoteCollectionId(NotebookCollection collection) {
    if (collection.source != NotebookDataSource.remote) {
      throw ArgumentError.value(
        collection.source,
        'collection.source',
        'A LIVE notebook collection is required.',
      );
    }
    final id = collection.remoteId;
    if (id == null || id <= 0) {
      throw ArgumentError.value(
        id,
        'collection.remoteId',
        'A positive remote notebook list ID is required.',
      );
    }
    return id;
  }

  String? _optionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
