import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/analytics/data/api_analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/data/analytics_api_paths.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';

void main() {
  test('uses verified learner analytics endpoints', () {
    expect(AnalyticsApiPaths.studyStreak, '/api/Analytics/study-streak');
    expect(
      AnalyticsApiPaths.completionStats,
      '/api/Analytics/completion-stats',
    );
    expect(AnalyticsApiPaths.skillBreakdown, '/api/Analytics/skill-breakdown');
  });

  test('keeps successful analytics sections when one endpoint fails', () async {
    final repository = ApiAnalyticsRepository(
      _PartialAnalyticsClient(<String, Object?>{
        AnalyticsApiPaths.studyStreak: <String, Object?>{
          'result': <String, Object?>{'currentStreakDays': 4},
        },
        AnalyticsApiPaths.completionStats: <String, Object?>{
          'result': <String, Object?>{
            'completedLessons': 7,
            'totalLessons': 20,
          },
        },
      }),
    );

    final analytics = await repository.loadLearnerAnalytics();

    expect(analytics.streakDays, 4);
    expect(analytics.completedLessons, 7);
    expect(analytics.totalLessons, 20);
    expect(analytics.skills, isEmpty);
    expect(analytics.unavailableSections, contains(AnalyticsSection.skills));
  });

  test(
    'maps the verified skill score contract without synthetic counts',
    () async {
      final repository = ApiAnalyticsRepository(
        _PartialAnalyticsClient(<String, Object?>{
          AnalyticsApiPaths.studyStreak: <String, Object?>{
            'result': <String, Object?>{'currentStreakDays': 4},
          },
          AnalyticsApiPaths.completionStats: <String, Object?>{
            'result': <String, Object?>{
              'completedLessons': 7,
              'totalLessons': 20,
            },
          },
          AnalyticsApiPaths.skillBreakdown: <String, Object?>{
            'result': <Object?>[
              <String, Object?>{
                'languageSkillName': 'Kanji',
                'averageScore': 82.5,
                'attemptCount': 3,
              },
            ],
          },
        }),
      );

      final analytics = await repository.loadLearnerAnalytics();

      expect(analytics.skills, hasLength(1));
      expect(analytics.skills.single.skill, 'Kanji');
      expect(analytics.skills.single.averageScore, 82.5);
      expect(analytics.skills.single.attemptCount, 3);
      expect(analytics.skills.single.progress, 0.825);
    },
  );

  test(
    'malformed section is unavailable while valid sections survive',
    () async {
      final repository = ApiAnalyticsRepository(
        _PartialAnalyticsClient(<String, Object?>{
          AnalyticsApiPaths.studyStreak: <String, Object?>{
            'result': <String, Object?>{'currentStreakDays': 'four'},
          },
          AnalyticsApiPaths.completionStats: <String, Object?>{
            'result': <String, Object?>{
              'completedLessons': 2,
              'totalLessons': 8,
            },
          },
          AnalyticsApiPaths.skillBreakdown: <String, Object?>{
            'result': <Object?>[],
          },
        }),
      );

      final analytics = await repository.loadLearnerAnalytics();

      expect(analytics.unavailableSections, {AnalyticsSection.streak});
      expect(analytics.completedLessons, 2);
      expect(analytics.totalLessons, 8);
    },
  );

  test(
    'all malformed analytics sections fail with a controlled error',
    () async {
      final repository = ApiAnalyticsRepository(
        _PartialAnalyticsClient(<String, Object?>{
          AnalyticsApiPaths.studyStreak: const <String, Object?>{},
          AnalyticsApiPaths.completionStats: const <String, Object?>{},
          AnalyticsApiPaths.skillBreakdown: const <String, Object?>{},
        }),
      );

      await expectLater(
        repository.loadLearnerAnalytics(),
        throwsA(isA<UnknownError>()),
      );
    },
  );

  test('invalid score does not become a generated zero metric', () async {
    final repository = ApiAnalyticsRepository(
      _PartialAnalyticsClient(<String, Object?>{
        AnalyticsApiPaths.studyStreak: <String, Object?>{
          'result': <String, Object?>{'currentStreakDays': 1},
        },
        AnalyticsApiPaths.completionStats: <String, Object?>{
          'result': <String, Object?>{'completedLessons': 1, 'totalLessons': 1},
        },
        AnalyticsApiPaths.skillBreakdown: <String, Object?>{
          'result': <Object?>[
            <String, Object?>{
              'languageSkillName': 'Reading',
              'averageScore': 120,
              'attemptCount': 1,
            },
          ],
        },
      }),
    );

    final analytics = await repository.loadLearnerAnalytics();

    expect(analytics.skills, isEmpty);
    expect(analytics.unavailableSections, contains(AnalyticsSection.skills));
  });

  test(
    'one malformed skill record does not erase valid sibling data',
    () async {
      final repository = ApiAnalyticsRepository(
        _PartialAnalyticsClient(<String, Object?>{
          AnalyticsApiPaths.studyStreak: <String, Object?>{
            'result': <String, Object?>{'currentStreakDays': 1},
          },
          AnalyticsApiPaths.completionStats: <String, Object?>{
            'result': <String, Object?>{
              'completedLessons': 1,
              'totalLessons': 2,
            },
          },
          AnalyticsApiPaths.skillBreakdown: <String, Object?>{
            'result': <Object?>[
              <String, Object?>{'languageSkillName': '', 'averageScore': 20},
              <String, Object?>{
                'languageSkillName': 'Listening',
                'averageScore': 75,
                'attemptCount': 4,
              },
            ],
          },
        }),
      );

      final analytics = await repository.loadLearnerAnalytics();

      expect(analytics.skills.single.skill, 'Listening');
      expect(analytics.isAvailable(AnalyticsSection.skills), isTrue);
    },
  );
}

class _PartialAnalyticsClient extends ApiClient {
  _PartialAnalyticsClient(this.responses)
    : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (!responses.containsKey(path)) {
      throw StateError('Unavailable analytics section');
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responses[path] as T,
    );
  }
}
