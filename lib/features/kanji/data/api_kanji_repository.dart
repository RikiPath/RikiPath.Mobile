import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_api_paths.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_dtos.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_mapper.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';

class ApiKanjiRepository implements KanjiRepository {
  const ApiKanjiRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<KanjiPage> search(KanjiQuery query) async {
    if (query.level != null) {
      throw const KanjiJlptMappingUnavailableException();
    }

    final request = KanjiSearchFilterDto(
      jlptLevelId: null,
      keyword: query.keyword.trim().isEmpty ? null : query.keyword.trim(),
      page: query.page,
      pageSize: query.pageSize,
      minStrokeCount: query.minStrokeCount,
      maxStrokeCount: query.maxStrokeCount,
    );
    final response = await _apiClient.post<Object?>(
      KanjiApiPaths.search,
      data: request.toJson(),
    );

    try {
      final dto = KanjiPageDto.fromEnvelope(response.data);
      return KanjiPage(
        items: dto.items.map(KanjiMapper.fromRemote).toList(growable: false),
        page: dto.page,
        pageSize: dto.pageSize,
        totalCount: dto.totalCount,
        totalPages: dto.totalPages,
        source: KanjiDataSource.remote,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The kanji search response did not match the contract.',
      );
    }
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) async {
    final id = _remoteId(routeKey);
    final response = await _apiClient.get<Object?>(KanjiApiPaths.detail(id));
    try {
      return KanjiMapper.fromRemote(readKanjiDetail(response.data));
    } on FormatException {
      throw const UnknownError(
        message: 'The kanji detail response did not match the contract.',
      );
    }
  }

  int _remoteId(String routeKey) {
    const prefix = 'remote-';
    if (!routeKey.startsWith(prefix)) {
      throw const FormatException('Expected a remote kanji route key.');
    }
    final id = int.tryParse(routeKey.substring(prefix.length));
    if (id == null || id <= 0) {
      throw const FormatException('Invalid remote kanji route key.');
    }
    return id;
  }
}

class ApiKanjiNotebookRepository implements KanjiNotebookRepository {
  const ApiKanjiNotebookRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<KanjiNotebookList>> loadLists() async {
    final response = await _apiClient.get<Object?>(KanjiApiPaths.notebookLists);
    try {
      return readKanjiNotebookLists(
        response.data,
      ).map(KanjiMapper.listFromRemote).toList(growable: false);
    } on FormatException {
      throw const UnknownError(
        message: 'The notebook list response did not match the contract.',
      );
    }
  }

  @override
  Future<KanjiBookmark> bookmarkKanji({
    required int kanjiEntryId,
    required KanjiNotebookList list,
  }) async {
    final request = BookmarkKanjiRequestDto(
      vocabularyListId: list.id,
      kanjiEntryId: kanjiEntryId,
    );
    final response = await _apiClient.post<Object?>(
      KanjiApiPaths.bookmarkKanji,
      data: request.toJson(),
    );
    try {
      final entry = KanjiNotebookEntryDto.fromEnvelope(response.data);
      return KanjiBookmark(
        noteEntryId: entry.noteEntryId,
        listId: list.id,
        listName: list.name,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The kanji bookmark response did not match the contract.',
      );
    }
  }
}

class KanjiJlptMappingUnavailableException implements Exception {
  const KanjiJlptMappingUnavailableException();
}
