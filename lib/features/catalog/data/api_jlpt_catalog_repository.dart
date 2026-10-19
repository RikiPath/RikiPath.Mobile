import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/catalog/data/jlpt_catalog_api_paths.dart';
import 'package:rikipath_mobile/features/catalog/data/jlpt_catalog_dtos.dart';
import 'package:rikipath_mobile/features/catalog/data/jlpt_catalog_mapper.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

class ApiJlptCatalogRepository implements JlptCatalogRepository {
  const ApiJlptCatalogRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<JlptLevelCatalogItem>> loadLevels() async {
    final response = await _client.get<Object?>(JlptCatalogApiPaths.levels);
    try {
      return readJlptLevelCatalog(
        response.data,
      ).map(JlptCatalogMapper.fromRemote).toList(growable: false);
    } on FormatException {
      throw const UnknownError(
        message: 'The JLPT catalog response did not match the contract.',
      );
    }
  }
}
