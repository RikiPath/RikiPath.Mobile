import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/grammar/data/api_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/data/fallback_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/data/fixture_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_api_paths.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_dtos.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_mapper.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';

void main() {
  group('Grammar DTO and mapper contract', () {
    test('serializes only the verified search fields', () {
      const request = GrammarSearchFilterDto(
        jlptLevelId: null,
        keyword: 'たり',
        page: 2,
        pageSize: 10,
      );

      expect(request.toJson(), <String, Object?>{
        'jlptLevelId': null,
        'keyword': 'たり',
        'page': 2,
        'pageSize': 10,
      });
    });

    test('accepts omitted nullable entity-backed response fields', () {
      final dto = GrammarCardDto.fromJson(
        _grammarJson(includeNullableFields: false),
      );
      final entry = GrammarMapper.fromRemote(dto);

      expect(entry.explanation, isNull);
      expect(entry.exampleSentence, isNull);
      expect(entry.enrichment, isNull);
      expect(entry.remoteId, 19);
    });

    test('rejects a fractional remote ID instead of truncating it', () {
      final json = _grammarJson();
      json['id'] = 19.5;

      expect(() => GrammarCardDto.fromJson(json), throwsFormatException);
    });

    test('rejects JLPT levels outside mobile N5/N4/N3 scope', () {
      expect(() => GrammarMapper.parseLevel('N2'), throwsFormatException);
      expect(() => GrammarMapper.parseLevel('N1'), throwsFormatException);
    });
  });

  group('API Grammar repository', () {
    test('uses exact search route, body, envelope, and remote ID', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'POST ${GrammarApiPaths.search}': _searchEnvelope(
          items: <Object?>[_grammarJson()],
          page: 2,
          pageSize: 10,
          totalCount: 11,
          totalPages: 2,
        ),
      });
      final repository = ApiGrammarRepository(client);

      final page = await repository.search(
        const GrammarQuery(keyword: 'たり', page: 2, pageSize: 10),
      );

      expect(client.calls, <String>['POST ${GrammarApiPaths.search}']);
      expect(client.lastData, <String, Object?>{
        'jlptLevelId': null,
        'keyword': 'たり',
        'page': 2,
        'pageSize': 10,
      });
      expect(page.page, 2);
      expect(page.hasNextPage, isFalse);
      expect(page.items.single.routeKey, 'remote-19');
      expect(page.items.single.remoteId, 19);
    });

    test('uses exact detail route and only supported fields', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${GrammarApiPaths.detail(19)}': <String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': _grammarJson(),
        },
      });
      final repository = ApiGrammarRepository(client);

      final entry = await repository.loadDetail('remote-19');

      expect(client.calls, <String>['GET ${GrammarApiPaths.detail(19)}']);
      expect(entry.title, '～たり～たりする');
      expect(entry.structure, 'V(た) + り、V(た) + りする');
      expect(entry.source, GrammarDataSource.remote);
      expect(entry.enrichment, isNull);
    });

    test('does not invent a numeric JLPT ID', () async {
      final client = _RecordingApiClient(const <String, Object?>{});
      final repository = ApiGrammarRepository(client);

      await expectLater(
        repository.search(const GrammarQuery(level: JlptLevel.n4)),
        throwsA(isA<GrammarJlptMappingUnavailableException>()),
      );
      expect(client.calls, isEmpty);
    });

    test('maps a malformed live response to a typed unknown error', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'POST ${GrammarApiPaths.search}': <String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': <String, Object?>{'items': 'not-an-array'},
        },
      });

      await expectLater(
        ApiGrammarRepository(client).search(const GrammarQuery()),
        throwsA(isA<UnknownError>()),
      );
    });
  });

  group('fixture and fallback Grammar repositories', () {
    test(
      'fixture search matches backend title, structure, explanation only',
      () async {
        const repository = FixtureGrammarRepository();

        final title = await repository.search(
          const GrammarQuery(keyword: 'ながら'),
        );
        final explanation = await repository.search(
          const GrammarQuery(keyword: 'đồng thời'),
        );
        final exampleOnly = await repository.search(
          const GrammarQuery(keyword: '写真'),
        );

        expect(title.items.single.title, '～ながら');
        expect(explanation.items.single.title, '～ながら');
        expect(exampleOnly.items, isEmpty);
      },
    );

    test('fixture supports exactly N5/N4/N3 level filtering', () async {
      const repository = FixtureGrammarRepository();

      for (final level in JlptLevel.values) {
        final page = await repository.search(GrammarQuery(level: level));
        expect(page.items, isNotEmpty);
        expect(page.items.every((entry) => entry.level == level), isTrue);
      }
      expect(JlptLevel.values, <JlptLevel>[
        JlptLevel.n5,
        JlptLevel.n4,
        JlptLevel.n3,
      ]);
    });

    test('fixture paginates without reusing backend IDs', () async {
      const repository = FixtureGrammarRepository();
      final first = await repository.search(const GrammarQuery(pageSize: 2));
      final second = await repository.search(
        const GrammarQuery(page: 2, pageSize: 2),
      );

      expect(first.items, hasLength(2));
      expect(first.hasNextPage, isTrue);
      expect(second.items, hasLength(2));
      expect(
        FixtureGrammarRepository.entries.every(
          (entry) =>
              entry.remoteId == null && entry.routeKey.startsWith('fixture-'),
        ),
        isTrue,
      );
    });

    test(
      'fallback uses fixture for empty first page and JLPT filters',
      () async {
        final remote = _FakeGrammarRepository(
          page: _emptyPage(GrammarDataSource.remote),
        );
        final repository = FallbackGrammarRepository(
          remote: remote,
          fixture: const FixtureGrammarRepository(),
        );

        final emptyFallback = await repository.search(const GrammarQuery());
        final levelFallback = await repository.search(
          const GrammarQuery(level: JlptLevel.n4),
        );

        expect(emptyFallback.source, GrammarDataSource.fixture);
        expect(levelFallback.source, GrammarDataSource.fixture);
        expect(remote.searchCalls, 1);
      },
    );
  });
}

Map<String, Object?> _searchEnvelope({
  required List<Object?> items,
  required int page,
  required int pageSize,
  required int totalCount,
  required int totalPages,
}) {
  return <String, Object?>{
    'statusCode': 200,
    'isSuccess': true,
    'result': <String, Object?>{
      'items': items,
      'page': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
    },
  };
}

Map<String, Object?> _grammarJson({bool includeNullableFields = true}) {
  return <String, Object?>{
    'id': 19,
    'title': '～たり～たりする',
    'structure': 'V(た) + り、V(た) + りする',
    if (includeNullableFields)
      'explanation': 'Liệt kê một số hành động hoặc trạng thái tiêu biểu.',
    if (includeNullableFields) 'exampleSentence': '週末は映画を見たり、本を読んだりします。',
    'jlptLevelName': 'N4',
  };
}

GrammarPage _emptyPage(GrammarDataSource source) {
  return GrammarPage(
    items: const <GrammarEntry>[],
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

class _FakeGrammarRepository implements GrammarRepository {
  _FakeGrammarRepository({required this.page});

  final GrammarPage page;
  int searchCalls = 0;

  @override
  Future<GrammarPage> search(GrammarQuery query) async {
    searchCalls++;
    return page;
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) {
    return Future<GrammarEntry>.error(StateError('No detail fixture.'));
  }
}
