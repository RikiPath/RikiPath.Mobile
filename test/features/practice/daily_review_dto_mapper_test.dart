import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/practice/data/api_daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/data/daily_review_api_paths.dart';
import 'package:rikipath_mobile/features/practice/data/daily_review_dtos.dart';
import 'package:rikipath_mobile/features/practice/data/daily_review_mapper.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';

void main() {
  group('Daily Review API contract', () {
    test('maps queue envelope and preserves the backend review card ID', () {
      final queue = DailyReviewMapper.queue(
        readDailyReviewQueue(<String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': <String, Object?>{
            'totalDue': 1,
            'items': <Object?>[
              <String, Object?>{
                'reviewCardId': 481,
                'contentType': 'Vocabulary',
                'term': '学ぶ',
                'reading': 'まなぶ',
                'meaning': 'học',
                'note': null,
                'repetitions': 2,
                'nextReviewDate': '2026-10-21T00:00:00',
              },
            ],
          },
        }),
      );

      expect(queue.totalDue, 1);
      expect(queue.items.single.reviewCardId, 481);
      expect(queue.items.single.contentType, DailyReviewContentType.vocabulary);
      expect(queue.items.single.nextReviewDate.isUtc, isTrue);
    });

    test('maps an empty due queue without introducing fixture cards', () {
      final queue = DailyReviewMapper.queue(
        readDailyReviewQueue(<String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{'totalDue': 0, 'items': <Object?>[]},
        }),
      );

      expect(queue.items, isEmpty);
    });

    test('maps the schedule returned by submit-result', () {
      final result = DailyReviewMapper.submit(
        readDailyReviewSubmitResult(<String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{
            'reviewCardId': 481,
            'qualitySubmitted': 4,
            'shouldRepeatInSession': false,
            'newEaseFactor': 2.5,
            'newIntervalDays': 6,
            'repetitions': 2,
            'nextReviewDate': '2026-10-27T00:00:00Z',
          },
        }),
      );

      expect(result.reviewCardId, 481);
      expect(result.qualitySubmitted, 4);
      expect(result.newIntervalDays, 6);
      expect(result.nextReviewDate.isUtc, isTrue);
    });

    test('rejects a queue whose total does not match its items', () {
      final dto = DailyReviewQueueDto(
        totalDue: 2,
        items: <DailyReviewCardDto>[_cardDto()],
      );

      expect(() => DailyReviewMapper.queue(dto), throwsFormatException);
    });

    test('rejects unknown content types and invalid schedule values', () {
      expect(
        () => DailyReviewMapper.card(_cardDto(contentType: 'Listening')),
        throwsFormatException,
      );
      expect(
        () => DailyReviewMapper.submit(
          DailyReviewSubmitResultDto(
            reviewCardId: 481,
            qualitySubmitted: 0,
            shouldRepeatInSession: false,
            newEaseFactor: 2.5,
            newIntervalDays: 1,
            repetitions: 1,
            nextReviewDate: DateTime.utc(2026, 10, 22),
          ),
        ),
        throwsFormatException,
      );
    });

    test('repository uses the exact queue route and submit payload', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${DailyReviewApiPaths.queue}': <String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{'totalDue': 0, 'items': <Object?>[]},
        },
        'POST ${DailyReviewApiPaths.submit}': <String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{
            'reviewCardId': 481,
            'qualitySubmitted': 3,
            'shouldRepeatInSession': false,
            'newEaseFactor': 2.36,
            'newIntervalDays': 1,
            'repetitions': 1,
            'nextReviewDate': '2026-10-22T00:00:00Z',
          },
        },
      });
      final repository = ApiDailyReviewRepository(client);

      final queue = await repository.loadDailyQueue();
      final result = await repository.submitResult(
        reviewCardId: 481,
        quality: 3,
      );

      expect(queue.items, isEmpty);
      expect(result.reviewCardId, 481);
      expect(client.calls, <String>[
        'GET ${DailyReviewApiPaths.queue}',
        'POST ${DailyReviewApiPaths.submit}',
      ]);
      expect(client.lastData, <String, Object?>{
        'reviewCardId': 481,
        'quality': 3,
      });
    });
  });
}

DailyReviewCardDto _cardDto({String contentType = 'Kanji'}) {
  return DailyReviewCardDto(
    reviewCardId: 481,
    contentType: contentType,
    term: '学',
    reading: 'がく',
    meaning: 'học',
    note: null,
    repetitions: 0,
    nextReviewDate: DateTime.utc(2026, 10, 21),
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
