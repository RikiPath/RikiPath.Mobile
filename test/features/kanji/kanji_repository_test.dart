import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/kanji/data/api_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/data/fallback_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/data/fixture_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_api_paths.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_dtos.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_mapper.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';

void main() {
  group('Kanji DTO and mapper contract', () {
    test('serializes all verified search request fields', () {
      const request = KanjiSearchFilterDto(
        jlptLevelId: null,
        keyword: '験',
        page: 2,
        pageSize: 10,
        minStrokeCount: 5,
        maxStrokeCount: 18,
      );

      expect(request.toJson(), <String, Object?>{
        'jlptLevelId': null,
        'keyword': '験',
        'page': 2,
        'pageSize': 10,
        'minStrokeCount': 5,
        'maxStrokeCount': 18,
      });
    });

    test('accepts omitted nullable On reading without inventing a value', () {
      final dto = KanjiCardDto.fromJson(_kanjiJson(includeOptional: false));
      final entry = KanjiMapper.fromRemote(dto);

      expect(entry.onYomi, isNull);
      expect(entry.kunYomi, isNull);
      expect(entry.sinoVietnamese, isNull);
      expect(entry.strokeOrderUrl, isNull);
      expect(entry.audioUrl, isNull);
      expect(entry.enrichment, isNull);
      expect(entry.isSaved, isNull);
    });

    test('rejects a fractional integer field instead of truncating it', () {
      final json = _kanjiJson();
      json['strokeCount'] = 18.5;

      expect(() => KanjiCardDto.fromJson(json), throwsFormatException);
    });

    test('rejects JLPT levels outside the mobile N5/N4/N3 scope', () {
      expect(() => KanjiMapper.parseLevel('N2'), throwsFormatException);
    });

    test('accepts only absolute HTTP(S) media URLs', () {
      expect(KanjiMapper.publicUri('/audio/1.mp3'), isNull);
      expect(KanjiMapper.publicUri('javascript:alert(1)'), isNull);
      expect(
        KanjiMapper.publicUri('https://cdn.example.test/kanji.mp3'),
        Uri.parse('https://cdn.example.test/kanji.mp3'),
      );
    });
  });

  group('API Kanji repository', () {
    test(
      'uses exact search route, body, page envelope, and remote ID',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'POST ${KanjiApiPaths.search}': _searchEnvelope(
            items: <Object?>[_kanjiJson()],
            page: 2,
            pageSize: 10,
            totalCount: 12,
            totalPages: 2,
          ),
        });
        final repository = ApiKanjiRepository(client);

        final page = await repository.search(
          const KanjiQuery(
            keyword: '験',
            page: 2,
            pageSize: 10,
            minStrokeCount: 10,
            maxStrokeCount: 20,
          ),
        );

        expect(client.calls, <String>['POST ${KanjiApiPaths.search}']);
        expect(client.lastData, <String, Object?>{
          'jlptLevelId': null,
          'keyword': '験',
          'page': 2,
          'pageSize': 10,
          'minStrokeCount': 10,
          'maxStrokeCount': 20,
        });
        expect(page.page, 2);
        expect(page.hasNextPage, isFalse);
        expect(page.items.single.routeKey, 'remote-7');
        expect(page.items.single.remoteId, 7);
      },
    );

    test('uses exact detail route and supported response fields', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${KanjiApiPaths.detail(7)}': <String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': _kanjiJson(),
        },
      });
      final repository = ApiKanjiRepository(client);

      final entry = await repository.loadDetail('remote-7');

      expect(client.calls, <String>['GET ${KanjiApiPaths.detail(7)}']);
      expect(entry.character, '験');
      expect(entry.onYomi, 'ケン');
      expect(entry.strokeCount, 18);
      expect(entry.source, KanjiDataSource.remote);
    });

    test('does not invent numeric JLPT IDs', () async {
      final client = _RecordingApiClient(const <String, Object?>{});
      final repository = ApiKanjiRepository(client);

      await expectLater(
        repository.search(const KanjiQuery(level: JlptLevel.n4)),
        throwsA(isA<KanjiJlptMappingUnavailableException>()),
      );
      expect(client.calls, isEmpty);
    });

    test('uses exact notebook list and bookmark contracts', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${KanjiApiPaths.notebookLists}': <String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': <Object?>[
            <String, Object?>{
              'id': 3,
              'name': 'JLPT N3',
              'description': null,
              'entryCount': 12,
              'createdAt': '2026-09-12T00:00:00Z',
            },
          ],
        },
        'POST ${KanjiApiPaths.bookmarkKanji}': <String, Object?>{
          'statusCode': 201,
          'isSuccess': true,
          'result': <String, Object?>{
            'noteEntryId': 41,
            'reviewItemId': 52,
            'contentType': 'kanji',
            'term': '験',
            'reading': 'ケン',
            'meaning': 'Kiểm nghiệm',
            'note': null,
            'addedAt': '2026-09-12T00:00:00Z',
          },
        },
      });
      final repository = ApiKanjiNotebookRepository(client);

      final lists = await repository.loadLists();
      final bookmark = await repository.bookmarkKanji(
        kanjiEntryId: 7,
        list: lists.single,
      );

      expect(client.lastData, <String, Object?>{
        'learnerNoteId': 3,
        'kanjiId': 7,
      });
      expect(bookmark.noteEntryId, 41);
    });
  });

  group('fixture and fallback Kanji repositories', () {
    test('fixture search follows backend character-or-meaning scope', () async {
      const repository = FixtureKanjiRepository();

      final character = await repository.search(const KanjiQuery(keyword: '験'));
      final meaning = await repository.search(
        const KanjiQuery(keyword: 'học tập'),
      );
      final readingOnly = await repository.search(
        const KanjiQuery(keyword: 'ガク'),
      );

      expect(character.items.single.character, '験');
      expect(meaning.items.single.character, '学');
      expect(readingOnly.items, isEmpty);
    });

    test('fixture supports N5/N4/N3 filtering and stroke ranges', () async {
      const repository = FixtureKanjiRepository();

      for (final level in JlptLevel.values) {
        final page = await repository.search(KanjiQuery(level: level));
        expect(page.items, isNotEmpty);
        expect(page.items.every((entry) => entry.level == level), isTrue);
      }
      final range = await repository.search(
        const KanjiQuery(minStrokeCount: 18, maxStrokeCount: 18),
      );
      expect(range.items.single.character, '験');
      expect(JlptLevel.values, <JlptLevel>[
        JlptLevel.n5,
        JlptLevel.n4,
        JlptLevel.n3,
      ]);
    });

    test('fixture paginates and never reuses backend IDs', () async {
      const repository = FixtureKanjiRepository();
      final first = await repository.search(const KanjiQuery(pageSize: 2));
      final second = await repository.search(
        const KanjiQuery(page: 2, pageSize: 2),
      );

      expect(first.items, hasLength(2));
      expect(first.hasNextPage, isTrue);
      expect(second.items, hasLength(2));
      expect(
        FixtureKanjiRepository.entries.every(
          (entry) =>
              entry.remoteId == null && entry.routeKey.startsWith('fixture-'),
        ),
        isTrue,
      );
    });

    test(
      'fallback preserves remote empty results and isolates JLPT fixtures',
      () async {
        final remote = _FakeKanjiRepository(
          page: _emptyPage(KanjiDataSource.remote),
        );
        final repository = FallbackKanjiRepository(
          remote: remote,
          fixture: const FixtureKanjiRepository(),
        );

        final emptyFallback = await repository.search(const KanjiQuery());
        final levelFallback = await repository.search(
          const KanjiQuery(level: JlptLevel.n4),
        );

        expect(emptyFallback.source, KanjiDataSource.remote);
        expect(emptyFallback.items, isEmpty);
        expect(levelFallback.source, KanjiDataSource.fixture);
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

Map<String, Object?> _kanjiJson({bool includeOptional = true}) {
  return <String, Object?>{
    'id': 7,
    'character': '験',
    if (includeOptional) 'onYomi': 'ケン',
    if (includeOptional) 'kunYomi': 'ためす',
    if (includeOptional) 'sinoVietnamese': 'NGHIỆM',
    'meaning': 'Kiểm nghiệm',
    'strokeCount': 18,
    if (includeOptional)
      'strokeOrderUrl': 'https://cdn.example.test/kanji/7.png',
    if (includeOptional) 'audioUrl': 'https://cdn.example.test/kanji/7.mp3',
    'jlptLevelName': 'N3',
  };
}

KanjiPage _emptyPage(KanjiDataSource source) {
  return KanjiPage(
    items: const <KanjiEntry>[],
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

class _FakeKanjiRepository implements KanjiRepository {
  _FakeKanjiRepository({required this.page});

  final KanjiPage page;
  int searchCalls = 0;

  @override
  Future<KanjiPage> search(KanjiQuery query) async {
    searchCalls++;
    return page;
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) {
    return Future<KanjiEntry>.error(StateError('No detail fixture.'));
  }
}
