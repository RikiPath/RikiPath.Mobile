import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/data/api_standard_roadmap_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

void main() {
  test(
    'loads the authenticated Standard Roadmap contract and real IDs',
    () async {
      final client = _RoadmapApiClient();
      final roadmap = await ApiStandardRoadmapRepository(client).load();

      expect(client.calls, <String>['GET /api/StandardRoadmap']);
      expect(roadmap.currentStudyLevelId, 12);
      expect(roadmap.currentStudyLevelName, 'N5');
      expect(roadmap.targetJlptLevelId, 24);
      expect(roadmap.learningMode, LearningMode.standard);
      expect(roadmap.lessons.map((lesson) => lesson.lessonId), <int>[
        8101,
        8107,
      ]);
      expect(roadmap.lessons.first.isCompleted, isTrue);
      expect(roadmap.lessons.last.progressPercent, 35);
      expect(roadmap.nextLessonId, 8107);
    },
  );

  test('empty server lesson collection is a valid Standard Roadmap', () async {
    final client = _RoadmapApiClient(empty: true);
    final roadmap = await ApiStandardRoadmapRepository(client).load();

    expect(roadmap.totalLessons, 0);
    expect(roadmap.completedLessons, 0);
    expect(roadmap.lessons, isEmpty);
    expect(roadmap.nextLessonId, isNull);
  });

  test(
    'rejects malformed API envelopes without fabricating lesson data',
    () async {
      final client = _RoadmapApiClient(malformed: true);

      await expectLater(
        ApiStandardRoadmapRepository(client).load(),
        throwsA(isA<UnknownError>()),
      );
    },
  );
}

class _RoadmapApiClient extends ApiClient {
  _RoadmapApiClient({this.empty = false, this.malformed = false})
    : super(Dio(), const ApiErrorMapper());

  final bool empty;
  final bool malformed;
  final List<String> calls = <String>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add('GET $path');
    final response = malformed
        ? <String, Object?>{
            'statusCode': 200,
            'isSuccess': true,
            'result': null,
          }
        : <String, Object?>{
            'statusCode': 200,
            'isSuccess': true,
            'result': <String, Object?>{
              'currentStudyLevelId': 12,
              'currentStudyLevelName': 'N5',
              'targetJlptLevelId': 24,
              'targetJlptLevelName': 'N4',
              'learningMode': 'STANDARD',
              'totalLessons': empty ? 0 : 2,
              'completedLessons': empty ? 0 : 1,
              'nextLessonId': empty ? null : 8107,
              'lessons': empty
                  ? <Object?>[]
                  : <Object?>[
                      <String, Object?>{
                        'lessonId': 8101,
                        'title': 'Real completed lesson',
                        'sortOrder': 1,
                        'progressPercent': 100,
                        'isCompleted': true,
                      },
                      <String, Object?>{
                        'lessonId': 8107,
                        'title': 'Real next lesson',
                        'sortOrder': 2,
                        'progressPercent': 35,
                        'isCompleted': false,
                      },
                    ],
            },
          };
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: response as T,
    );
  }
}
