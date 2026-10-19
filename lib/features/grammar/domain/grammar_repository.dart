import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';

abstract interface class GrammarRepository {
  Future<GrammarPage> search(GrammarQuery query);

  Future<GrammarEntry> loadDetail(String routeKey);
}

abstract interface class GrammarBookmarkRepository {
  Future<GrammarBookmark> bookmarkGrammar(int grammarPatternId);
}
