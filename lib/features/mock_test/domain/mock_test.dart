import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';

@immutable
class LiveMockTestSummary {
  const LiveMockTestSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.jlptLevelName,
    required this.timeLimitMinutes,
  });

  final int id;
  final String title;
  final String description;
  final String jlptLevelName;
  final int timeLimitMinutes;
}

@immutable
class LiveMockTestOption {
  const LiveMockTestOption({
    required this.id,
    required this.content,
    required this.order,
  });

  final int id;
  final String content;
  final int order;
}

@immutable
class LiveMockTestQuestion {
  const LiveMockTestQuestion({
    required this.id,
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.sectionOrder,
    required this.order,
    required this.content,
    this.questionType = 'SingleChoice',
    this.interactionData,
    required this.audioUrl,
    required this.imageUrl,
    required this.options,
  });

  final int id;
  final int mockTestSectionId;
  final String sectionTitle;
  final int sectionOrder;
  final int order;
  final String content;
  final String questionType;
  final Map<String, Object?>? interactionData;
  final String? audioUrl;
  final String? imageUrl;
  final List<LiveMockTestOption> options;
}

@immutable
class LiveMockTestAttempt {
  const LiveMockTestAttempt({
    required this.id,
    required this.mockTestId,
    required this.startedAt,
    required this.timeLimitMinutes,
    required this.previouslyWrongQuestionIds,
    required this.questions,
    this.answers = const <int, int>{},
    this.structuredAnswers = const <int, Object?>{},
    this.currentQuestionIndex = 0,
  });

  final int id;
  final int mockTestId;
  final DateTime startedAt;
  final int timeLimitMinutes;
  final List<int> previouslyWrongQuestionIds;
  final List<LiveMockTestQuestion> questions;
  final Map<int, int> answers;
  final Map<int, Object?> structuredAnswers;
  final int currentQuestionIndex;

  DateTime get deadline =>
      startedAt.toUtc().add(Duration(minutes: timeLimitMinutes));

  Duration remainingAt(DateTime now) {
    final remaining = deadline.difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isQuestionAnswered(int questionId) {
    if (answers.containsKey(questionId)) return true;
    final structured = structuredAnswers[questionId];
    if (structured == null) return false;
    if (structured is List && structured.isNotEmpty) return true;
    if (structured is String && structured.trim().isNotEmpty) return true;
    if (structured is Map && structured.isNotEmpty) return true;
    return false;
  }

  LiveMockTestAttempt copyWith({
    Map<int, int>? answers,
    Map<int, Object?>? structuredAnswers,
    int? currentQuestionIndex,
  }) {
    return LiveMockTestAttempt(
      id: id,
      mockTestId: mockTestId,
      startedAt: startedAt,
      timeLimitMinutes: timeLimitMinutes,
      previouslyWrongQuestionIds: previouslyWrongQuestionIds,
      questions: questions,
      answers: answers ?? this.answers,
      structuredAnswers: structuredAnswers ?? this.structuredAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}

@immutable
class MockTestAnswerSubmission {
  const MockTestAnswerSubmission({
    required this.questionId,
    this.selectedOptionId,
    this.response,
  });

  final int questionId;
  final int? selectedOptionId;
  final Object? response;

  Map<String, Object?> toJson() => <String, Object?>{
    'questionId': questionId,
    'selectedOptionId': selectedOptionId,
    if (response != null) 'response': response,
  };
}

@immutable
class LiveMockTestSectionResult {
  const LiveMockTestSectionResult({
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.languageSkillName,
    required this.correctCount,
    required this.totalCount,
    required this.score,
  });

  final int mockTestSectionId;
  final String sectionTitle;
  final String languageSkillName;
  final int correctCount;
  final int totalCount;
  final double score;
}

@immutable
class LiveMockTestResult {
  const LiveMockTestResult({
    required this.attemptId,
    required this.mockTestId,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.totalScore,
    required this.wrongQuestionIds,
    required this.sections,
  });

  final int attemptId;
  final int mockTestId;
  final MockTestAttemptStatus status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double totalScore;
  final List<int> wrongQuestionIds;
  final List<LiveMockTestSectionResult> sections;

  int get correctCount =>
      sections.fold(0, (total, section) => total + section.correctCount);

  int get totalCount =>
      sections.fold(0, (total, section) => total + section.totalCount);
}

@immutable
class LiveMockTestReviewOption {
  const LiveMockTestReviewOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  final int id;
  final String text;
  final bool isCorrect;
}

@immutable
class LiveMockTestQuestionReview {
  const LiveMockTestQuestionReview({
    required this.questionId,
    required this.questionText,
    this.questionType = 'SingleChoice',
    this.response,
    this.answerKey,
    required this.options,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.explanation,
  });

  final int questionId;
  final String questionText;
  final String questionType;
  final Object? response;
  final Object? answerKey;
  final List<LiveMockTestReviewOption> options;
  final int? selectedOptionId;
  final bool isCorrect;
  final String? explanation;
}

@immutable
class LiveMockTestDetailedResult {
  const LiveMockTestDetailedResult({
    required this.attemptId,
    required this.mockTestId,
    required this.totalScore,
    required this.questions,
  });

  final int attemptId;
  final int mockTestId;
  final double totalScore;
  final List<LiveMockTestQuestionReview> questions;
}
