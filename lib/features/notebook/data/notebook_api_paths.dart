abstract final class NotebookApiPaths {
  static const String collections = '/api/Notebook/lists';

  static String entries(int collectionId) =>
      '/api/Notebook/lists/$collectionId/entries';

  static const String manualEntry = '/api/Notebook/entries';
  static const String bookmarkVocabulary = '/api/Notebook/bookmark/vocabulary';

  static String removeEntry(int noteEntryId) =>
      '/api/Notebook/entries/$noteEntryId';
}
