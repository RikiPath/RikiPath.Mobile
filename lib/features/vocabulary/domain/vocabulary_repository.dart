import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';

abstract interface class VocabularyRepository {
  Future<VocabularyPage> search(VocabularyQuery query);

  Future<VocabularyEntry> loadDetail(String routeKey);
}
