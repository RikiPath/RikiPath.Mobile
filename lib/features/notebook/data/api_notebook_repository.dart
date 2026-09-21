import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_api_paths.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_dtos.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_mapper.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

class ApiNotebookRepository implements NotebookRemoteDataSource {
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
      vocabularyListId: _remoteCollectionId(collection),
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
      vocabularyListId: _remoteCollectionId(collection),
      vocabularyEntryId: vocabularyEntryId,
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
  Future<void> removeEntry(NotebookEntry entry) async {
    final noteEntryId = entry.remoteNoteEntryId;
    if (noteEntryId == null || noteEntryId <= 0) {
      throw ArgumentError.value(
        noteEntryId,
        'entry.remoteNoteEntryId',
        'A positive remote note entry ID is required.',
      );
    }
    await _apiClient.delete<Object?>(NotebookApiPaths.removeEntry(noteEntryId));
  }

  int _remoteCollectionId(NotebookCollection collection) {
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
