import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/data/analytics_api_paths.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

void main() {
  group('Analytics Monthly Progress & Study History', () {
    test(
      'learnerSkillMonthlyProvider parses verified skill-monthly endpoint',
      () async {
        late String capturedPath;
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedPath = options.path;
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, Object?>{
                    'isSuccess': true,
                    'result': <String, Object?>{
                      'assessedJlptLevel': 'N4',
                      'targetJlptLevel': 'N3',
                      'totalAttempts': 12,
                      'currentOverallScorePercent': 78.5,
                      'summary': 'Tiến bộ ổn định ở Kanji và Ngữ pháp',
                      'skills': [
                        <String, Object?>{
                          'languageSkillName': 'Kanji',
                          'currentAssessment': 'Khá',
                          'currentScorePercent': 84.0,
                          'changeFromPreviousRecordedMonth': 6.5,
                          'comparedMonth': '2026-10',
                          'totalAttempts': 5,
                          'monthlyScores': [
                            <String, Object?>{
                              'month': '2026-10',
                              'scorePercent': 77.5,
                              'attemptCount': 2,
                            },
                            <String, Object?>{
                              'month': '2026-11',
                              'scorePercent': 84.0,
                              'attemptCount': 3,
                            },
                          ],
                        },
                      ],
                    },
                  },
                ),
              );
            },
          ),
        );

        final container = ProviderContainer(
          overrides: [
            authenticatedUserIdProvider.overrideWithValue(1),
            apiClientProvider.overrideWithValue(
              ApiClient(dio, const ApiErrorMapper()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final summary = await container.read(learnerSkillMonthlyProvider.future);
        expect(capturedPath, '/api/Analytics/skill-monthly?months=12');
        expect(summary.assessedJlptLevel, 'N4');
        expect(summary.targetJlptLevel, 'N3');
        expect(summary.currentOverallScorePercent, 78.5);
        expect(summary.skills.single.languageSkillName, 'Kanji');
        expect(summary.skills.single.changeFromPreviousMonth, 6.5);
        expect(summary.skills.single.monthlyScores, hasLength(2));
      },
    );

    test(
      'learnerStudyHistoryProvider aggregates MockTest, Practice & Homework reports',
      () async {
        final paths = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              paths.add(options.path);
              if (options.path == AnalyticsApiPaths.mockTestHistory) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': [
                        <String, Object?>{
                          'attemptId': 31,
                          'mockTestId': 5,
                          'title': 'Đề thi thử N4 #1',
                          'jlptLevelName': 'N4',
                          'totalScore': 82.0,
                          'submittedAt': '2026-11-17T08:00:00Z',
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              if (options.path == AnalyticsApiPaths.practiceHistory) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': [
                        <String, Object?>{
                          'id': 91,
                          'type': 'Writing',
                          'overallScore': 76.0,
                          'textContent': '毎日日本語を勉強しています。',
                          'submittedAt': '2026-11-17T09:00:00Z',
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              if (options.path.startsWith('/api/homework/report')) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{
                        'assignedCount': 4,
                        'submittedCount': 3,
                        'homeworkPercent': 75.0,
                        'sessionCount': 10,
                        'attendedCount': 9,
                        'attendancePercent': 90.0,
                      },
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final container = ProviderContainer(
          overrides: [
            authenticatedUserIdProvider.overrideWithValue(1),
            apiClientProvider.overrideWithValue(
              ApiClient(dio, const ApiErrorMapper()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final history = await container.read(learnerStudyHistoryProvider.future);
        expect(paths, contains(AnalyticsApiPaths.mockTestHistory));
        expect(paths, contains(AnalyticsApiPaths.practiceHistory));
        expect(paths.any((p) => p.startsWith('/api/homework/report')), isTrue);
        expect(history.mockTests.single.title, 'Đề thi thử N4 #1');
        expect(history.practices.single.type, 'Luyện viết AI');
        expect(history.practices.single.overallScore, 76.0);
        expect(history.homeworkReport?.homeworkPercent, 75.0);
        expect(history.homeworkReport?.attendedCount, 9);
      },
    );
  });
}
