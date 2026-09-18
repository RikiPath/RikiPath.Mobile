import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';

class FallbackKanjiRepository implements KanjiRepository {
  const FallbackKanjiRepository({required this.remote, required this.fixture});

  final KanjiRepository remote;
  final KanjiRepository fixture;

  @override
  Future<KanjiPage> search(KanjiQuery query) async {
    // The backend exposes only numeric JLPT IDs and no learner-facing mapping.
    if (query.level != null) return fixture.search(query);

    final remotePage = await remote.search(query);
    if (query.page == 1 && remotePage.totalCount == 0) {
      return fixture.search(query);
    }
    return remotePage;
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    if (routeKey.startsWith('fixture-')) return fixture.loadDetail(routeKey);
    return remote.loadDetail(routeKey);
  }
}
