import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mock_test/data/api_mock_test_repository.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_api_paths.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';

void main() {
  test(
    'uses the current MockTest paths instead of the removed PracticeTest path',
    () {
      expect(MockTestApiPaths.start(7), '/api/MockTest/7/start');
      expect(MockTestApiPaths.submit(11), '/api/MockTest/attempts/11/submit');
      expect(MockTestApiPaths.result(11), '/api/MockTest/attempts/11');
      expect(
        MockTestApiPaths.detailedResult(11),
        '/api/MockTest/attempts/11/detailed',
      );
      expect(MockTestApiPaths.testsByLevel(3), '/api/MockTest/level/3/tests');
    },
  );

  test('maps only source-backed attempt status strings', () {
    expect(
      MockTestAttemptStatus.fromApiValue('in_progress'),
      MockTestAttemptStatus.inProgress,
    );
    expect(
      MockTestAttemptStatus.fromApiValue('completed'),
      MockTestAttemptStatus.completed,
    );
    expect(MockTestAttemptStatus.fromApiValue('pending'), isNull);
  });

  test(
    'submit repository serializes backend IDs and unanswered null',
    () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5265'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: <String, Object?>{
                  'isSuccess': true,
                  'result': <String, Object?>{
                    'attemptId': 9001,
                    'mockTestId': 731,
                    'status': 'completed',
                    'startedAt': '2026-10-19T08:30:00Z',
                    'submittedAt': '2026-10-19T08:50:00Z',
                    'totalScore': 50,
                    'wrongQuestionIds': <Object?>[1202],
                    'sections': <Object?>[],
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiMockTestRepository(
        ApiClient(dio, const ApiErrorMapper()),
      );

      await repository.submit(9001, const <MockTestAnswerSubmission>[
        MockTestAnswerSubmission(questionId: 1201, selectedOptionId: 4401),
        MockTestAnswerSubmission(questionId: 1202, selectedOptionId: null),
      ]);

      expect(captured.path, '/api/MockTest/attempts/9001/submit');
      expect(captured.method, 'POST');
      expect(captured.data, <String, Object?>{
        'answers': <Object?>[
          <String, Object?>{'questionId': 1201, 'selectedOptionId': 4401},
          <String, Object?>{'questionId': 1202, 'selectedOptionId': null},
        ],
      });
    },
  );

  test('production Mock Test flow is isolated from fixture grading', () {
    final liveSources = <String>[
      'lib/features/mock_test/application/mock_test_controller.dart',
      'lib/features/mock_test/data/api_mock_test_repository.dart',
      'lib/features/practice/presentation/mock_test_screen.dart',
      'lib/features/practice/presentation/mock_test_result_screen.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(liveSources, isNot(contains('DemoPracticeController')));
    expect(liveSources, isNot(contains('FixtureDemoPracticeRepository')));
    expect(liveSources, isNot(contains('correctOptionId')));
    expect(liveSources, isNot(contains('DemoMockResult.calculate')));
    expect(
      File(
        'lib/features/practice/data/fixture_demo_practice_repository.dart',
      ).existsSync(),
      isTrue,
    );
  });
}
