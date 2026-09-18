import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';

abstract interface class KanjiRepository {
  Future<KanjiPage> search(KanjiQuery query);

  Future<KanjiEntry> loadDetail(String routeKey);
}

abstract interface class KanjiNotebookRepository {
  Future<List<KanjiNotebookList>> loadLists();

  Future<KanjiBookmark> bookmarkKanji({
    required int kanjiEntryId,
    required KanjiNotebookList list,
  });
}
