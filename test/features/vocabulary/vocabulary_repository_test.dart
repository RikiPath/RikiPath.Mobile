import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/vocabulary/data/api_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/fallback_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/fixture_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/vocabulary_api_paths.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary_repository.dart';

void main() {
  group('API vocabulary repository', () {
    test(
      'uses the exact search route, body fields, and response envelope',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'POST ${VocabularyApiPaths.search}': _searchEnvelope(
            items: <Object?>[_vocabularyJson(id: 7)],
            totalCount: 1,
            totalPages: 1,
          ),
        });
        final repository = ApiVocabularyRepository(client);

        final page = await repository.search(
          const VocabularyQuery(keyword: '経験', page: 1, pageSize: 20),
        );

        expect(client.calls, <String>['POST ${VocabularyApiPaths.search}']);
        expect(client.lastData, <String, Object?>{
          'jlptLevelId': null,
          'keyword': '経験',
          'page': 1,
          'pageSize': 20,
        });
        expect(page.source, VocabularyDataSource.remote);
        expect(page.totalCount, 1);
        expect(page.items.single.routeKey, 'remote-7');
        expect(page.items.single.remoteId, 7);
        expect(page.items.single.level, JlptLevel.n3);
      },
    );

    test(
      'keeps nullable response fields nullable without inventing data',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'GET ${VocabularyApiPaths.detail(7)}': <String, Object?>{
            'statusCode': 200,
            'isSuccess': true,
            'result': _vocabularyJson(id: 7, includeOptionalFields: false),
          },
        });
        final repository = ApiVocabularyRepository(client);

        final entry = await repository.loadDetail('remote-7');

        expect(client.calls, <String>['GET ${VocabularyApiPaths.detail(7)}']);
        expect(entry.partOfSpeech, isNull);
        expect(entry.exampleSentence, isNull);
        expect(entry.audioUrl, isNull);
        expect(entry.enrichment, isNull);
      },
    );

    test('does not invent a numeric JLPT level ID', () async {
      final client = _RecordingApiClient(const <String, Object?>{});
      final repository = ApiVocabularyRepository(client);

      await expectLater(
        repository.search(const VocabularyQuery(level: JlptLevel.n4)),
        throwsA(isA<VocabularyJlptMappingUnavailableException>()),
      );
      expect(client.calls, isEmpty);
    });
  });

  group('fixture and fallback vocabulary repositories', () {
    test('fixture supports keyword search and pagination', () async {
      const repository = FixtureVocabularyRepository();

      final firstPage = await repository.search(
        const VocabularyQuery(pageSize: 2),
      );
      final secondPage = await repository.search(
        const VocabularyQuery(page: 2, pageSize: 2),
      );
      final search = await repository.search(
        const VocabularyQuery(keyword: 'cải thiện'),
      );

      expect(firstPage.items, hasLength(2));
      expect(firstPage.hasNextPage, isTrue);
      expect(secondPage.items, hasLength(2));
      expect(search.items.single.word, '改善');
    });

    test('fixture filtering remains limited to N5, N4, and N3', () async {
      const repository = FixtureVocabularyRepository();
      final levels = <JlptLevel>{};

      for (final level in JlptLevel.values) {
        final page = await repository.search(VocabularyQuery(level: level));
        expect(page.items, isNotEmpty);
        levels.addAll(page.items.map((entry) => entry.level));
        expect(page.items.every((entry) => entry.level == level), isTrue);
      }

      expect(JlptLevel.values, <JlptLevel>[
        JlptLevel.n5,
        JlptLevel.n4,
        JlptLevel.n3,
      ]);
      expect(levels, <JlptLevel>{JlptLevel.n5, JlptLevel.n4, JlptLevel.n3});
      expect(
        FixtureVocabularyRepository.entries.every(
          (entry) => entry.remoteId == null,
        ),
        isTrue,
      );
    });

    test(
      'fallback uses fixtures only for an empty first remote page',
      () async {
        final remote = _FakeVocabularyRepository(
          page: _emptyPage(VocabularyDataSource.remote),
        );
        const fixture = FixtureVocabularyRepository();
        final repository = FallbackVocabularyRepository(
          remote: remote,
          fixture: fixture,
        );

        final page = await repository.search(const VocabularyQuery());

        expect(remote.searchCalls, 1);
        expect(page.source, VocabularyDataSource.fixture);
        expect(page.items, isNotEmpty);
      },
    );

    test('fallback keeps remote results when the API has vocabulary', () async {
      final remoteEntry = VocabularyEntry(
        routeKey: 'remote-7',
        remoteId: 7,
        word: '経験',
        reading: 'けいけん',
        meaning: 'Kinh nghiệm',
        level: JlptLevel.n3,
        source: VocabularyDataSource.remote,
      );
      final remote = _FakeVocabularyRepository(
        page: VocabularyPage(
          items: <VocabularyEntry>[remoteEntry],
          page: 1,
          pageSize: 20,
          totalCount: 1,
          totalPages: 1,
          source: VocabularyDataSource.remote,
        ),
        detail: remoteEntry,
      );
      final repository = FallbackVocabularyRepository(
        remote: remote,
        fixture: const FixtureVocabularyRepository(),
      );

      final page = await repository.search(const VocabularyQuery());
      final detail = await repository.loadDetail('remote-7');

      expect(page.source, VocabularyDataSource.remote);
      expect(detail, same(remoteEntry));
    });
  });
}

Map<String, Object?> _searchEnvelope({
  required List<Object?> items,
  required int totalCount,
  required int totalPages,
}) {
  return <String, Object?>{
    'statusCode': 200,
    'isSuccess': true,
    'result': <String, Object?>{
      'items': items,
      'page': 1,
      'pageSize': 20,
      'totalCount': totalCount,
      'totalPages': totalPages,
    },
  };
}

Map<String, Object?> _vocabularyJson({
  required int id,
  bool includeOptionalFields = true,
}) {
  return <String, Object?>{
    'id': id,
    'word': '経験',
    'reading': 'けいけん',
    'meaning': 'Kinh nghiệm',
    if (includeOptionalFields) 'partOfSpeech': 'Danh từ',
    if (includeOptionalFields) 'exampleSentence': '経験があります。',
    if (includeOptionalFields) 'audioUrl': 'https://cdn.example.test/7.mp3',
    'jlptLevelName': 'N3',
  };
}

VocabularyPage _emptyPage(VocabularyDataSource source) {
  return VocabularyPage(
    items: const <VocabularyEntry>[],
    page: 1,
    pageSize: 20,
    totalCount: 0,
    totalPages: 0,
    source: source,
  );
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.responses) : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;
  final List<String> calls = <String>[];
  Object? lastData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final key = 'GET $path';
    calls.add(key);
    return _response<T>(key, path);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final key = 'POST $path';
    calls.add(key);
    lastData = data;
    return _response<T>(key, path);
  }

  Response<T> _response<T>(String key, String path) {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responses[key] as T,
    );
  }
}

class _FakeVocabularyRepository implements VocabularyRepository {
  _FakeVocabularyRepository({required this.page, this.detail});

  final VocabularyPage page;
  final VocabularyEntry? detail;
  int searchCalls = 0;

  @override
  Future<VocabularyPage> search(VocabularyQuery query) async {
    searchCalls++;
    return page;
  }

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) async {
    return detail ?? (throw StateError('No detail fixture.'));
  }
}
