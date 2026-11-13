import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_dtos.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_mapper.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';

void main() {
  group('Structured Mock Test Question Contract', () {
    test('parses MultipleChoice question with options and response', () {
      final json = <String, Object?>{
        'questionId': 2001,
        'mockTestSectionId': 10,
        'sectionTitle': 'Vocabulary',
        'sectionOrder': 1,
        'order': 1,
        'selectedOptionId': null,
        'questionType': 'MultipleChoice',
        'response': [5001, 5003],
        'content': 'Chọn các từ đồng nghĩa.',
        'audioUrl': null,
        'imageUrl': null,
        'options': [
          {'optionId': 5001, 'content': 'Từ A', 'order': 1},
          {'optionId': 5002, 'content': 'Từ B', 'order': 2},
          {'optionId': 5003, 'content': 'Từ C', 'order': 3},
        ],
      };

      final dto = StartAttemptQuestionDto.fromJson(json);
      expect(dto.questionType, 'MultipleChoice');
      expect(dto.response, [5001, 5003]);

      final startDto = StartAttemptDto(
        attemptId: 99,
        mockTestId: 101,
        startedAt: DateTime.now().toUtc(),
        timeLimitMinutes: 30,
        previouslyWrongQuestionIds: const [],
        questions: [dto],
      );

      final attempt = MockTestMapper.attempt(startDto);
      expect(attempt.structuredAnswers[2001], [5001, 5003]);
      expect(attempt.isQuestionAnswered(2001), isTrue);
    });

    test('parses Ordering question with interactionData tokens', () {
      final json = <String, Object?>{
        'questionId': 2002,
        'mockTestSectionId': 11,
        'sectionTitle': 'Grammar',
        'sectionOrder': 2,
        'order': 2,
        'selectedOptionId': null,
        'questionType': 'Ordering',
        'interactionData': {
          'tokens': ['私', 'は', '学生', 'です'],
        },
        'content': 'Sắp xếp các từ thành câu đúng.',
        'audioUrl': null,
        'imageUrl': null,
        'options': <Object?>[],
      };

      final dto = StartAttemptQuestionDto.fromJson(json);
      expect(dto.questionType, 'Ordering');
      expect(dto.interactionData?['tokens'], ['私', 'は', '学生', 'です']);

      final liveQuestion = MockTestMapper.attempt(
        StartAttemptDto(
          attemptId: 99,
          mockTestId: 101,
          startedAt: DateTime.now().toUtc(),
          timeLimitMinutes: 30,
          previouslyWrongQuestionIds: const [],
          questions: [dto],
        ),
      ).questions.first;

      expect(liveQuestion.questionType, 'Ordering');
      expect(liveQuestion.interactionData?['tokens'], ['私', 'は', '学生', 'です']);
    });

    test('MockTestAnswerSubmission serializes both single choice and structured responses correctly', () {
      const single = MockTestAnswerSubmission(
        questionId: 101,
        selectedOptionId: 501,
      );
      expect(single.toJson(), {
        'questionId': 101,
        'selectedOptionId': 501,
      });

      const multiple = MockTestAnswerSubmission(
        questionId: 102,
        response: [501, 503],
      );
      expect(multiple.toJson(), {
        'questionId': 102,
        'selectedOptionId': null,
        'response': [501, 503],
      });

      const ordering = MockTestAnswerSubmission(
        questionId: 103,
        response: ['A', 'B', 'C'],
      );
      expect(ordering.toJson(), {
        'questionId': 103,
        'selectedOptionId': null,
        'response': ['A', 'B', 'C'],
      });
    });

    test('parses Detailed Result for structured questions with answerKey and response', () {
      final json = <String, Object?>{
        'attemptId': 99,
        'mockTestId': 101,
        'totalScore': 80.0,
        'questions': [
          {
            'questionId': 2002,
            'questionText': 'Sắp xếp câu',
            'questionType': 'Ordering',
            'response': ['私', 'は', '学生', 'です'],
            'answerKey': ['私', 'は', '学生', 'です'],
            'selectedOptionId': null,
            'isCorrect': true,
            'explanation': 'Đúng ngữ pháp.',
            'options': <Object?>[],
          },
        ],
      };

      final detailed = MockTestMapper.detailed(DetailedAttemptResultDto.fromJson(json));
      expect(detailed.questions.first.questionType, 'Ordering');
      expect(detailed.questions.first.isCorrect, isTrue);
      expect(detailed.questions.first.response, ['私', 'は', '学生', 'です']);
      expect(detailed.questions.first.answerKey, ['私', 'は', '学生', 'です']);
    });
  });
}
