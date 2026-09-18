import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notebook/data/api_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/data/fixture_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_api_paths.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

void main() {
  group('API Notebook repository', () {
    test('uses exact list, entries, and remove routes', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${NotebookApiPaths.collections}': _envelope(<Object?>[
          _collectionJson(),
        ]),
        'GET ${NotebookApiPaths.entries(3)}': _envelope(<Object?>[
          _entryJson(),
        ]),
        'DELETE ${NotebookApiPaths.removeEntry(41)}': _envelope(null),
      });
      final repository = ApiNotebookRepository(client);

      final collections = await repository.loadCollections();
      final entries = await repository.loadEntries(collections.single);
      await repository.removeEntry(entries.single);

      expect(client.calls, <String>[
        'GET ${NotebookApiPaths.collections}',
        'GET ${NotebookApiPaths.entries(3)}',
        'DELETE ${NotebookApiPaths.removeEntry(41)}',
      ]);
      expect(collections.single.routeKey, 'remote-list-3');
      expect(collections.single.remoteId, 3);
      expect(entries.single.routeKey, 'remote-note-41');
      expect(entries.single.remoteNoteEntryId, 41);
      expect(entries.single.reviewItemId, 52);
    });

    test('maps every source-backed entry field and nullable values', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${NotebookApiPaths.collections}': _envelope(<Object?>[
          _collectionJson(description: 'Từ khó'),
        ]),
        'GET ${NotebookApiPaths.entries(3)}': _envelope(<Object?>[
          _entryJson(note: 'Hay nhầm', reading: null),
        ]),
      });
      final repository = ApiNotebookRepository(client);

      final collection = (await repository.loadCollections()).single;
      final entry = (await repository.loadEntries(collection)).single;

      expect(collection.description, 'Từ khó');
      expect(collection.createdAt, DateTime.utc(2026, 9, 12));
      expect(entry.contentType, NotebookContentType.vocabulary);
      expect(entry.term, '経験');
      expect(entry.reading, isNull);
      expect(entry.meaning, 'Kinh nghiệm');
      expect(entry.note, 'Hay nhầm');
      expect(entry.addedAt, DateTime.utc(2026, 9, 12));
    });

    test(
      'does not invent a vocabulary detail ID from Notebook response',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'GET ${NotebookApiPaths.collections}': _envelope(<Object?>[
            _collectionJson(),
          ]),
          'GET ${NotebookApiPaths.entries(3)}': _envelope(<Object?>[
            _entryJson(),
          ]),
        });
        final repository = ApiNotebookRepository(client);
        final collection = (await repository.loadCollections()).single;
        final entry = (await repository.loadEntries(collection)).single;

        expect(entry.vocabularyRouteKey, isNull);
        expect(entry.source, NotebookDataSource.remote);
      },
    );

    test('preserves unknown plain-string content types safely', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${NotebookApiPaths.collections}': _envelope(<Object?>[
          _collectionJson(),
        ]),
        'GET ${NotebookApiPaths.entries(3)}': _envelope(<Object?>[
          _entryJson(contentType: 'future-type'),
        ]),
      });
      final repository = ApiNotebookRepository(client);
      final collection = (await repository.loadCollections()).single;
      final entry = (await repository.loadEntries(collection)).single;

      expect(entry.contentType, NotebookContentType.unknown);
    });

    test('uses exact create-list request fields', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'POST ${NotebookApiPaths.collections}': _envelope(
          _collectionJson(name: 'N3 khó nhớ'),
        ),
      });
      final repository = ApiNotebookRepository(client);

      final created = await repository.createCollection(
        name: '  N3 khó nhớ  ',
        description: '  Đọc hiểu  ',
      );

      expect(client.lastData, <String, Object?>{
        'name': 'N3 khó nhớ',
        'description': 'Đọc hiểu',
      });
      expect(created.name, 'N3 khó nhớ');
    });

    test('uses exact manual-entry request fields', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'POST ${NotebookApiPaths.manualEntry}': _envelope(
          _entryJson(contentType: 'manual'),
        ),
      });
      final repository = ApiNotebookRepository(client);

      await repository.addManualEntry(
        collection: _remoteCollection(),
        word: '  経験 ',
        reading: ' けいけん ',
        meaning: ' Kinh nghiệm ',
        note: ' công việc ',
      );

      expect(client.lastData, <String, Object?>{
        'vocabularyListId': 3,
        'word': '経験',
        'reading': 'けいけん',
        'meaning': 'Kinh nghiệm',
        'note': 'công việc',
      });
    });

    test('uses the shared exact vocabulary bookmark contract', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'POST ${NotebookApiPaths.bookmarkVocabulary}': _envelope(_entryJson()),
      });
      final repository = ApiNotebookRepository(client);

      final bookmark = await repository.bookmarkVocabulary(
        vocabularyEntryId: 7,
        collection: _remoteCollection(),
      );

      expect(client.lastData, <String, Object?>{
        'vocabularyListId': 3,
        'vocabularyEntryId': 7,
      });
      expect(bookmark.noteEntryId, 41);
      expect(bookmark.collectionRouteKey, 'remote-list-3');
      expect(bookmark.collectionName, 'JLPT N3');
    });

    test(
      'does not claim duplicate-save protection the backend lacks',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'POST ${NotebookApiPaths.bookmarkVocabulary}': _envelope(
            _entryJson(),
          ),
        });
        final repository = ApiNotebookRepository(client);

        await repository.bookmarkVocabulary(
          vocabularyEntryId: 7,
          collection: _remoteCollection(),
        );
        await repository.bookmarkVocabulary(
          vocabularyEntryId: 7,
          collection: _remoteCollection(),
        );

        expect(client.calls, <String>[
          'POST ${NotebookApiPaths.bookmarkVocabulary}',
          'POST ${NotebookApiPaths.bookmarkVocabulary}',
        ]);
      },
    );

    test('rejects local keys before issuing a remote mutation', () async {
      final client = _RecordingApiClient(const <String, Object?>{});
      final repository = ApiNotebookRepository(client);
      final fixture = FixtureNotebookRepository.defaultCollection;

      await expectLater(
        repository.loadEntries(fixture),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repository.removeEntry(
          FixtureNotebookRepository.defaultEntries[fixture.routeKey]!.first,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(client.calls, isEmpty);
    });

    test('maps malformed source responses to a typed UnknownError', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${NotebookApiPaths.collections}': _envelope(<Object?>[
          <String, Object?>{'id': 3},
        ]),
      });
      final repository = ApiNotebookRepository(client);

      await expectLater(
        repository.loadCollections(),
        throwsA(isA<UnknownError>()),
      );
    });
  });

  group('explicit fixture Notebook repository', () {
    test('keeps route keys separate from remote IDs', () async {
      final repository = FixtureNotebookRepository();
      final collection = (await repository.loadCollections()).single;
      final entries = await repository.loadEntries(collection);

      expect(collection.source, NotebookDataSource.fixture);
      expect(collection.remoteId, isNull);
      expect(entries.every((entry) => entry.remoteNoteEntryId == null), isTrue);
      expect(entries.first.vocabularyRouteKey, 'fixture-keiken');
    });

    test('fixture removal remains local and deliberate', () async {
      final repository = FixtureNotebookRepository();
      final collection = (await repository.loadCollections()).single;
      final entry = (await repository.loadEntries(collection)).first;

      await repository.removeEntry(entry);

      expect(
        (await repository.loadEntries(collection)).map((item) => item.routeKey),
        isNot(contains(entry.routeKey)),
      );
    });
  });
}

Map<String, Object?> _envelope(Object? result) => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': result,
};

Map<String, Object?> _collectionJson({
  String name = 'JLPT N3',
  String? description,
}) => <String, Object?>{
  'id': 3,
  'name': name,
  'description': description,
  'entryCount': 1,
  'createdAt': '2026-09-12T00:00:00Z',
};

Map<String, Object?> _entryJson({
  String contentType = 'vocabulary',
  String? reading = 'けいけん',
  String? note,
}) => <String, Object?>{
  'noteEntryId': 41,
  'reviewItemId': 52,
  'contentType': contentType,
  'term': '経験',
  'reading': reading,
  'meaning': 'Kinh nghiệm',
  'note': note,
  'addedAt': '2026-09-12T00:00:00Z',
};

NotebookCollection _remoteCollection() => NotebookCollection(
  routeKey: 'remote-list-3',
  remoteId: 3,
  name: 'JLPT N3',
  entryCount: 1,
  createdAt: DateTime.utc(2026, 9, 12),
  source: NotebookDataSource.remote,
);

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

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final key = 'DELETE $path';
    calls.add(key);
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
