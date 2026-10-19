import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';

class FallbackGrammarRepository implements GrammarRepository {
  const FallbackGrammarRepository({
    required this.remote,
    required this.fixture,
  });

  final GrammarRepository remote;
  final GrammarRepository fixture;

  @override
  Future<GrammarPage> search(GrammarQuery query) => remote.search(query);

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    if (routeKey.startsWith('fixture-')) return fixture.loadDetail(routeKey);
    return remote.loadDetail(routeKey);
  }
}
