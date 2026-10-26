import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_dtos.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_mapper.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';

void main() {
  test('catalog parser preserves backend IDs and published metadata', () {
    final summaries = readMockTestSummaries(<String, Object?>{
      'isSuccess': true,
      'result': <Object?>[
        <String, Object?>{
          'mockTestId': 731,
          'title': 'N3 Live Test',
          'description': 'Published test',
          'jlptLevelName': 'N3',
          'timeLimitMinutes': 45,
        },
      ],
    });

    final mapped = MockTestMapper.summary(summaries.single);
    expect(mapped.id, 731);
    expect(mapped.title, 'N3 Live Test');
    expect(mapped.jlptLevelName, 'N3');
    expect(mapped.timeLimitMinutes, 45);
  });

  test('empty catalog response remains a legitimate empty list', () {
    expect(
      readMockTestSummaries(<String, Object?>{
        'isSuccess': true,
        'result': <Object?>[],
      }),
      isEmpty,
    );
  });

  test('start parser maps real attempt, question, section and option IDs', () {
    final dto = readStartAttempt(<String, Object?>{
      'isSuccess': true,
      'result': <String, Object?>{
        'attemptId': 9001,
        'mockTestId': 731,
        'startedAt': '2026-10-19T08:30:00Z',
        'timeLimitMinutes': 45,
        'previouslyWrongQuestionIds': <Object?>[1202],
        'questions': <Object?>[
          <String, Object?>{
            'questionId': 1202,
            'mockTestSectionId': 82,
            'sectionTitle': 'Grammar',
            'sectionOrder': 1,
            'order': 2,
            'content': 'Choose the answer.',
            'audioUrl': null,
            'imageUrl': 'https://cdn.example/question.png',
            'options': <Object?>[
              <String, Object?>{
                'optionId': 4402,
                'content': 'Answer B',
                'order': 2,
              },
              <String, Object?>{
                'optionId': 4401,
                'content': 'Answer A',
                'order': 1,
              },
            ],
          },
        ],
      },
    });

    final attempt = MockTestMapper.attempt(dto);
    expect(attempt.id, 9001);
    expect(attempt.mockTestId, 731);
    expect(attempt.previouslyWrongQuestionIds, <int>[1202]);
    expect(attempt.questions.single.id, 1202);
    expect(attempt.questions.single.mockTestSectionId, 82);
    expect(attempt.questions.single.options.map((option) => option.id), <int>[
      4402,
      4401,
    ]);
    expect(
      attempt.remainingAt(DateTime.utc(2026, 10, 19, 9)),
      const Duration(minutes: 15),
    );
  });

  test(
    'result parser uses backend status and scores without recalculation',
    () {
      final dto = readAttemptResult(<String, Object?>{
        'isSuccess': true,
        'result': <String, Object?>{
          'attemptId': 9001,
          'mockTestId': 731,
          'status': 'completed',
          'startedAt': '2026-10-19T08:30:00Z',
          'submittedAt': '2026-10-19T08:50:00Z',
          'totalScore': 72.5,
          'wrongQuestionIds': <Object?>[1202],
          'sections': <Object?>[
            <String, Object?>{
              'mockTestSectionId': 82,
              'sectionTitle': 'Grammar',
              'languageSkillName': 'Language Knowledge',
              'correctCount': 3,
              'totalCount': 4,
              'score': 75.0,
            },
          ],
        },
      });

      final result = MockTestMapper.result(dto);
      expect(result.status, MockTestAttemptStatus.completed);
      expect(result.totalScore, 72.5);
      expect(result.correctCount, 3);
      expect(result.totalCount, 4);
      expect(result.sections.single.score, 75);
      expect(result.wrongQuestionIds, <int>[1202]);
    },
  );

  test('detailed parser preserves selected and correct option truth', () {
    final dto = readDetailedAttemptResult(<String, Object?>{
      'isSuccess': true,
      'result': <String, Object?>{
        'attemptId': 9001,
        'mockTestId': 731,
        'totalScore': 50,
        'questions': <Object?>[
          <String, Object?>{
            'questionId': 1202,
            'questionText': 'Choose the answer.',
            'selectedOptionId': 4402,
            'isCorrect': false,
            'explanation': 'A is correct.',
            'options': <Object?>[
              <String, Object?>{
                'optionId': 4401,
                'optionText': 'Answer A',
                'isCorrect': true,
              },
              <String, Object?>{
                'optionId': 4402,
                'optionText': 'Answer B',
                'isCorrect': false,
              },
            ],
          },
        ],
      },
    });

    final detailed = MockTestMapper.detailed(dto);
    final question = detailed.questions.single;
    expect(question.questionId, 1202);
    expect(question.selectedOptionId, 4402);
    expect(question.isCorrect, isFalse);
    expect(question.options.singleWhere((option) => option.isCorrect).id, 4401);
    expect(question.explanation, 'A is correct.');
  });

  test('unsupported result status fails closed', () {
    final dto = AttemptResultDto(
      attemptId: 1,
      mockTestId: 2,
      status: 'pending',
      startedAt: DateTime.utc(2026),
      submittedAt: null,
      totalScore: 0,
      wrongQuestionIds: const <int>[],
      sections: const <MockTestSectionResultDto>[],
    );

    expect(() => MockTestMapper.result(dto), throwsFormatException);
  });

  test('malformed successful envelope fails closed', () {
    expect(
      () => readMockTestSummaries(<String, Object?>{
        'isSuccess': true,
        'result': <Object?>[
          <String, Object?>{'mockTestId': 'fixture-id'},
        ],
      }),
      throwsFormatException,
    );
  });
}
