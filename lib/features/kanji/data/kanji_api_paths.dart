abstract final class KanjiApiPaths {
  static const String search = '/api/SharedBank/kanji/search';

  static String detail(int id) => '/api/SharedBank/kanji/$id';

  static const String notebookLists = '/api/Notebook/lists';
  static const String bookmarkKanji = '/api/Notebook/bookmark/kanji';
}
