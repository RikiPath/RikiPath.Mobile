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
  Future<GrammarPage> search(GrammarQuery query) async {
    // No endpoint exposes the numeric ID for an N5/N4/N3 label.
    if (query.level != null) return fixture.search(query);

    return remote.search(query);
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    if (routeKey.startsWith('fixture-')) return fixture.loadDetail(routeKey);
    return remote.loadDetail(routeKey);
  }
}
