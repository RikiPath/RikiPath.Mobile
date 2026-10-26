import 'package:rikipath_mobile/features/mock_test/data/mock_test_dtos.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';

abstract final class MockTestMapper {
  static LiveMockTestSummary summary(MockTestSummaryDto dto) {
    return LiveMockTestSummary(
      id: dto.mockTestId,
      title: dto.title,
      description: dto.description,
      jlptLevelName: dto.jlptLevelName,
      timeLimitMinutes: dto.timeLimitMinutes,
    );
  }

  static LiveMockTestAttempt attempt(StartAttemptDto dto) {
    return LiveMockTestAttempt(
      id: dto.attemptId,
      mockTestId: dto.mockTestId,
      startedAt: dto.startedAt,
      timeLimitMinutes: dto.timeLimitMinutes,
      previouslyWrongQuestionIds: dto.previouslyWrongQuestionIds,
      questions: dto.questions.map(_question).toList(growable: false),
    );
  }

  static LiveMockTestResult result(AttemptResultDto dto) {
    final status = MockTestAttemptStatus.fromApiValue(dto.status);
    if (status == null) {
      throw FormatException('Unsupported Mock Test status: ${dto.status}');
    }
    return LiveMockTestResult(
      attemptId: dto.attemptId,
      mockTestId: dto.mockTestId,
      status: status,
      startedAt: dto.startedAt,
      submittedAt: dto.submittedAt,
      totalScore: dto.totalScore,
      wrongQuestionIds: dto.wrongQuestionIds,
      sections: dto.sections
          .map(
            (section) => LiveMockTestSectionResult(
              mockTestSectionId: section.mockTestSectionId,
              sectionTitle: section.sectionTitle,
              languageSkillName: section.languageSkillName,
              correctCount: section.correctCount,
              totalCount: section.totalCount,
              score: section.score,
            ),
          )
          .toList(growable: false),
    );
  }

  static LiveMockTestDetailedResult detailed(DetailedAttemptResultDto dto) {
    return LiveMockTestDetailedResult(
      attemptId: dto.attemptId,
      mockTestId: dto.mockTestId,
      totalScore: dto.totalScore,
      questions: dto.questions
          .map(
            (question) => LiveMockTestQuestionReview(
              questionId: question.questionId,
              questionText: question.questionText,
              options: question.options
                  .map(
                    (option) => LiveMockTestReviewOption(
                      id: option.optionId,
                      text: option.optionText,
                      isCorrect: option.isCorrect,
                    ),
                  )
                  .toList(growable: false),
              selectedOptionId: question.selectedOptionId,
              isCorrect: question.isCorrect,
              explanation: question.explanation,
            ),
          )
          .toList(growable: false),
    );
  }

  static LiveMockTestQuestion _question(StartAttemptQuestionDto dto) {
    return LiveMockTestQuestion(
      id: dto.questionId,
      mockTestSectionId: dto.mockTestSectionId,
      sectionTitle: dto.sectionTitle,
      sectionOrder: dto.sectionOrder,
      order: dto.order,
      content: dto.content,
      audioUrl: dto.audioUrl,
      imageUrl: dto.imageUrl,
      options: dto.options
          .map(
            (option) => LiveMockTestOption(
              id: option.optionId,
              content: option.content,
              order: option.order,
            ),
          )
          .toList(growable: false),
    );
  }
}
