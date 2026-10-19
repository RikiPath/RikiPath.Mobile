import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/vocabulary/data/vocabulary_api_paths.dart';
import 'package:rikipath_mobile/features/vocabulary/data/vocabulary_dtos.dart';
import 'package:rikipath_mobile/features/vocabulary/data/vocabulary_mapper.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary_repository.dart';

class ApiVocabularyRepository implements VocabularyRepository {
  const ApiVocabularyRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<VocabularyPage> search(VocabularyQuery query) async {
    final request = VocabularySearchFilterDto(
      keyword: query.keyword.trim().isEmpty ? null : query.keyword.trim(),
      jlptLevelId: query.level?.id,
      page: query.page,
      pageSize: query.pageSize,
    );
    final response = await _apiClient.post<Object?>(
      VocabularyApiPaths.search,
      data: request.toJson(),
    );

    try {
      final dto = VocabularyPageDto.fromEnvelope(response.data);
      final items = dto.items
          .map(VocabularyMapper.fromRemote)
          .toList(growable: false);
      return VocabularyPage(
        items: items,
        page: dto.page,
        pageSize: dto.pageSize,
        totalCount: dto.totalCount,
        totalPages: dto.totalPages,
        source: VocabularyDataSource.remote,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The vocabulary search response did not match the contract.',
      );
    }
  }

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) async {
    final id = _remoteId(routeKey);
    final response = await _apiClient.get<Object?>(
      VocabularyApiPaths.detail(id),
    );

    try {
      return VocabularyMapper.fromRemote(readVocabularyDetail(response.data));
    } on FormatException {
      throw const UnknownError(
        message: 'The vocabulary detail response did not match the contract.',
      );
    }
  }

  int _remoteId(String routeKey) {
    const prefix = 'remote-';
    if (!routeKey.startsWith(prefix)) {
      throw const FormatException('Expected a remote vocabulary route key.');
    }
    final id = int.tryParse(routeKey.substring(prefix.length));
    if (id == null || id <= 0) {
      throw const FormatException('Invalid remote vocabulary route key.');
    }
    return id;
  }
}
