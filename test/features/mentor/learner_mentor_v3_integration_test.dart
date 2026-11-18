import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_dtos.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ApiClient _createTestClient(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:5000',
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.httpClientAdapter = _FakeHttpAdapter(handler);
  return ApiClient(dio, const ApiErrorMapper());
}

ResponseBody _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('Canonical Mentor Discovery Contracts & DTOs', () {
    test('BookableMentorDto parses PublicMentorCardResponse correctly', () {
      final backendJson = <String, Object?>{
        'mentorId': 42,
        'name': 'Sensei Kenji',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'bio': 'Chuyên gia luyện thi JLPT N2',
        'expertise': 'Luyện thi N2, Hội thoại thương mại',
        'jlptLevel': 'N2',
        'yearsOfExperience': 8,
        'workplace': 'Tokyo University',
      };

      final dto = BookableMentorDto.fromJson(backendJson);
      final domain = dto.toDomain();

      expect(domain.id, 42);
      expect(domain.name, 'Sensei Kenji');
      expect(domain.avatarUrl, 'https://example.com/avatar.jpg');
      expect(domain.bio, 'Chuyên gia luyện thi JLPT N2');
      expect(domain.headline, 'Luyện thi N2, Hội thoại thương mại');
      expect(domain.jlptLevels, ['N2']);
      expect(domain.teachingMethod, 'Tokyo University');
    });

    test('readLearnerMentorResultList unwraps PagedResult from /api/mentors', () {
      final pagedEnvelope = <String, Object?>{
        'isSuccess': true,
        'statusCode': 200,
        'result': {
          'items': [
            {
              'mentorId': 101,
              'name': 'Sensei Sakura',
              'avatarUrl': null,
              'expertise': 'Kaiwa N3',
              'jlptLevel': 'N3',
            },
            {
              'mentorId': 102,
              'name': 'Sensei Takeshi',
              'avatarUrl': null,
              'expertise': 'Ngữ pháp N2',
              'jlptLevel': 'N2',
            },
          ],
          'totalCount': 2,
          'pageNumber': 1,
          'pageSize': 10,
        },
      };

      final items = readLearnerMentorResultList(pagedEnvelope);
      expect(items.length, 2);
      expect(items[0]['mentorId'], 101);
      expect(items[1]['name'], 'Sensei Takeshi');
    });

    test('ApiLearnerMentorRepository.loadMentors queries /api/mentors', () async {
      RequestOptions? captured;
      final client = _createTestClient((options) async {
        captured = options;
        return _jsonResponse({
          'isSuccess': true,
          'statusCode': 200,
          'result': [
            {
              'mentorId': 7,
              'name': 'Sensei Aoi',
              'expertise': 'JLPT N3',
              'teachingJlptLevels': ['N3', 'N4'],
            },
          ],
        });
      });

      final repo = ApiLearnerMentorRepository(client);
      final mentors = await repo.loadMentors();

      expect(captured?.path, '/api/mentors');
      expect(mentors, hasLength(1));
      expect(mentors.single.id, 7);
      expect(mentors.single.teachingJlptLevels, ['N3', 'N4']);
    });
  });
}
