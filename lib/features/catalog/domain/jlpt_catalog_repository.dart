import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

abstract interface class JlptCatalogRepository {
  Future<List<JlptLevelCatalogItem>> loadLevels();
}
