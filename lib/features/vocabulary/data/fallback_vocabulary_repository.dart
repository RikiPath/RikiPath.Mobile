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
  Future<VocabularyPage> search(VocabularyQuery query) => remote.search(query);

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) {
    if (routeKey.startsWith('fixture-')) {
      return fixture.loadDetail(routeKey);
    }
    return remote.loadDetail(routeKey);
  }
}
