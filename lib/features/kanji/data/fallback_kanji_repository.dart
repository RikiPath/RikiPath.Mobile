import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';

class FallbackKanjiRepository implements KanjiRepository {
  const FallbackKanjiRepository({required this.remote, required this.fixture});

  final KanjiRepository remote;
  final KanjiRepository fixture;

  @override
  Future<KanjiPage> search(KanjiQuery query) => remote.search(query);

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    if (routeKey.startsWith('fixture-')) return fixture.loadDetail(routeKey);
    return remote.loadDetail(routeKey);
  }
}
