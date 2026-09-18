import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary_repository.dart';

class FallbackVocabularyRepository implements VocabularyRepository {
  const FallbackVocabularyRepository({
    required this.remote,
    required this.fixture,
  });

  final VocabularyRepository remote;
  final VocabularyRepository fixture;

  @override
  Future<VocabularyPage> search(VocabularyQuery query) async {
    // A name-to-ID mapping is not published, so a JLPT filter cannot be sent
    // to the remote API without inventing IDs.
    if (query.level != null) {
      return fixture.search(query);
    }

    final remotePage = await remote.search(query);
    if (query.page == 1 && remotePage.totalCount == 0) {
      return fixture.search(query);
    }
    return remotePage;
  }

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) {
    if (routeKey.startsWith('fixture-')) {
      return fixture.loadDetail(routeKey);
    }
    return remote.loadDetail(routeKey);
  }
}
