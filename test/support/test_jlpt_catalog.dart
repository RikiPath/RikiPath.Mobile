import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

const testJlptCatalog = <JlptLevelCatalogItem>[
  JlptLevelCatalogItem(
    id: 101,
    code: 'N5',
    level: JlptLevel.n5,
    description: 'JLPT N5',
    sortOrder: 1,
  ),
  JlptLevelCatalogItem(
    id: 204,
    code: 'N4',
    level: JlptLevel.n4,
    description: 'JLPT N4',
    sortOrder: 2,
  ),
  JlptLevelCatalogItem(
    id: 309,
    code: 'N3',
    level: JlptLevel.n3,
    description: 'JLPT N3',
    sortOrder: 3,
  ),
  JlptLevelCatalogItem(
    id: 418,
    code: 'N2',
    level: JlptLevel.n2,
    description: 'JLPT N2',
    sortOrder: 4,
  ),
  JlptLevelCatalogItem(
    id: 527,
    code: 'N1',
    level: JlptLevel.n1,
    description: 'JLPT N1',
    sortOrder: 5,
  ),
];

class TestJlptCatalogRepository implements JlptCatalogRepository {
  TestJlptCatalogRepository({this.levels = testJlptCatalog, this.error});

  final List<JlptLevelCatalogItem> levels;
  final Object? error;
  int calls = 0;

  @override
  Future<List<JlptLevelCatalogItem>> loadLevels() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return levels;
  }
}
