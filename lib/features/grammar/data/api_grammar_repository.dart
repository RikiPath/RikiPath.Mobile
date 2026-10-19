import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_api_paths.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_dtos.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_mapper.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';

class ApiGrammarRepository implements GrammarRepository {
  const ApiGrammarRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<GrammarPage> search(GrammarQuery query) async {
    if (query.level != null) {
      throw const GrammarJlptMappingUnavailableException();
    }

    final keyword = query.keyword.trim();
    final request = GrammarSearchFilterDto(
      jlptLevelId: null,
      keyword: keyword.isEmpty ? null : keyword,
      page: query.page,
      pageSize: query.pageSize,
    );
    final response = await _apiClient.post<Object?>(
      GrammarApiPaths.search,
      data: request.toJson(),
    );

    try {
      final dto = GrammarPageDto.fromEnvelope(response.data);
      return GrammarPage(
        items: dto.items.map(GrammarMapper.fromRemote).toList(growable: false),
        page: dto.page,
        pageSize: dto.pageSize,
        totalCount: dto.totalCount,
        totalPages: dto.totalPages,
        source: GrammarDataSource.remote,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The grammar search response did not match the contract.',
      );
    }
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) async {
    try {
      final id = _remoteId(routeKey);
      final response = await _apiClient.get<Object?>(
        GrammarApiPaths.detail(id),
      );
      return GrammarMapper.fromRemote(readGrammarDetail(response.data));
    } on FormatException {
      throw const UnknownError(
        message: 'The grammar detail response did not match the contract.',
      );
    }
  }

  int _remoteId(String routeKey) {
    const prefix = 'remote-';
    if (!routeKey.startsWith(prefix)) {
      throw const FormatException('Expected a remote grammar route key.');
    }
    final id = int.tryParse(routeKey.substring(prefix.length));
    if (id == null || id <= 0) {
      throw const FormatException('Invalid remote grammar route key.');
    }
    return id;
  }
}

class ApiGrammarBookmarkRepository implements GrammarBookmarkRepository {
  const ApiGrammarBookmarkRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<GrammarBookmark> bookmarkGrammar(int grammarPatternId) async {
    if (grammarPatternId <= 0) {
      throw ArgumentError.value(
        grammarPatternId,
        'grammarPatternId',
        'A positive LIVE Grammar ID is required.',
      );
    }
    final response = await _apiClient.post<Object?>(
      GrammarApiPaths.bookmark(grammarPatternId),
    );
    try {
      final dto = readGrammarBookmark(response.data);
      if (dto.grammarPatternId != grammarPatternId) {
        throw const FormatException(
          'The bookmarked Grammar ID did not match the requested ID.',
        );
      }
      return GrammarBookmark(
        reviewCardId: dto.reviewCardId,
        grammarPatternId: dto.grammarPatternId,
        grammarTitle: dto.grammarTitle,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The grammar bookmark response did not match the contract.',
      );
    }
  }
}

class GrammarJlptMappingUnavailableException implements Exception {
  const GrammarJlptMappingUnavailableException();
}
