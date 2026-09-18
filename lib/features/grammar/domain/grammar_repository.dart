import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';

abstract interface class GrammarRepository {
  Future<GrammarPage> search(GrammarQuery query);

  Future<GrammarEntry> loadDetail(String routeKey);
}
