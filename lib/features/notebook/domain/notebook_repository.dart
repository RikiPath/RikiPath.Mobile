import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

abstract interface class NotebookRepository {
  Stream<Set<String>> watchSavedVocabularyKeys();

  Future<bool> isVocabularySaved(String vocabularyRouteKey);

  Future<List<NotebookCollection>> loadCollections();

  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection);

  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  });

  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  });

  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  });

  Future<void> removeEntry(NotebookEntry entry);
}

/// Exact remote Notebook contract. Persistence and stable frontend identity
/// are intentionally handled by [NotebookRepository], not by this data source.
abstract interface class NotebookRemoteDataSource {
  Future<List<NotebookCollection>> loadCollections();

  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection);

  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  });

  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  });

  Future<NotebookBookmark> bookmarkVocabulary({
    required int vocabularyEntryId,
    required NotebookCollection collection,
  });

  Future<void> removeEntry(NotebookEntry entry);
}
