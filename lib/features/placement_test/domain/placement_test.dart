import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

@immutable
class PlacementTestStatus {
  const PlacementTestStatus({
    required this.hasCompletedPlacementTest,
    this.attemptType = 'placement',
    this.hasActiveAttempt = false,
    this.activeAttemptId,
    this.activeAttemptExpiresAt,
    this.latestCompletedAttemptId,
    this.latestSubmittedAt,
    this.latestScorePercent,
    this.assessedJlptLevelId,
    this.assessedJlptLevelName,
    this.recommendedTargetJlptLevelId,
    this.recommendedTargetJlptLevelName,
    this.targetJlptLevelId,
    this.targetJlptLevelName,
    this.dailyStudyMinutes = 0,
    this.targetExamDate,
    this.isReadyForLearningPath = false,
    this.placementDecision = PlacementDecision.notTaken,
  });

  final String attemptType;
  final bool hasActiveAttempt;
  final int? activeAttemptId;
  final DateTime? activeAttemptExpiresAt;
  final bool hasCompletedPlacementTest;
  final int? latestCompletedAttemptId;
  int? get latestAttemptId => latestCompletedAttemptId;
  final DateTime? latestSubmittedAt;
  final double? latestScorePercent;
  final int? assessedJlptLevelId;
  final String? assessedJlptLevelName;
  final int? recommendedTargetJlptLevelId;
  final String? recommendedTargetJlptLevelName;
  final int? targetJlptLevelId;
  final String? targetJlptLevelName;
  final int dailyStudyMinutes;
  final DateTime? targetExamDate;
  final bool isReadyForLearningPath;
  final PlacementDecision placementDecision;

  PlacementTestStatus copyWith({
    bool? hasActiveAttempt,
    int? activeAttemptId,
    DateTime? activeAttemptExpiresAt,
    bool? hasCompletedPlacementTest,
    int? latestCompletedAttemptId,
    DateTime? latestSubmittedAt,
    double? latestScorePercent,
    int? assessedJlptLevelId,
    String? assessedJlptLevelName,
    int? recommendedTargetJlptLevelId,
    String? recommendedTargetJlptLevelName,
    int? targetJlptLevelId,
    String? targetJlptLevelName,
    int? dailyStudyMinutes,
    DateTime? targetExamDate,
    bool? isReadyForLearningPath,
    PlacementDecision? placementDecision,
    bool clearActiveAttempt = false,
  }) {
    return PlacementTestStatus(
      attemptType: attemptType,
      hasActiveAttempt: hasActiveAttempt ?? this.hasActiveAttempt,
      activeAttemptId: clearActiveAttempt
          ? null
          : activeAttemptId ?? this.activeAttemptId,
      activeAttemptExpiresAt: clearActiveAttempt
          ? null
          : activeAttemptExpiresAt ?? this.activeAttemptExpiresAt,
      hasCompletedPlacementTest:
          hasCompletedPlacementTest ?? this.hasCompletedPlacementTest,
      latestCompletedAttemptId:
          latestCompletedAttemptId ?? this.latestCompletedAttemptId,
      latestSubmittedAt: latestSubmittedAt ?? this.latestSubmittedAt,
      latestScorePercent: latestScorePercent ?? this.latestScorePercent,
      assessedJlptLevelId: assessedJlptLevelId ?? this.assessedJlptLevelId,
      assessedJlptLevelName:
          assessedJlptLevelName ?? this.assessedJlptLevelName,
      recommendedTargetJlptLevelId:
          recommendedTargetJlptLevelId ?? this.recommendedTargetJlptLevelId,
      recommendedTargetJlptLevelName:
          recommendedTargetJlptLevelName ?? this.recommendedTargetJlptLevelName,
      targetJlptLevelId: targetJlptLevelId ?? this.targetJlptLevelId,
      targetJlptLevelName: targetJlptLevelName ?? this.targetJlptLevelName,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      targetExamDate: targetExamDate ?? this.targetExamDate,
      isReadyForLearningPath:
          isReadyForLearningPath ?? this.isReadyForLearningPath,
      placementDecision: placementDecision ?? this.placementDecision,
    );
  }
}

@immutable
class PlacementTestOption {
  const PlacementTestOption({
    required this.id,
    required this.content,
    required this.order,
  });

  final int id;
  final String content;
  final int order;
}

@immutable
class PlacementTestQuestion {
  const PlacementTestQuestion({
    required this.id,
    required this.mockTestId,
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.sectionOrder,
    required this.jlptLevelId,
    required this.jlptLevelName,
    required this.order,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    required this.options,
  });

  final int id;
  final int mockTestId;
  final int mockTestSectionId;
  final String sectionTitle;
  final int sectionOrder;
  final int jlptLevelId;
  final String jlptLevelName;
  final int order;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final List<PlacementTestOption> options;
}

@immutable
class PlacementTestAttempt {
  const PlacementTestAttempt({
    required this.id,
    required this.startedAt,
    required this.timeLimitMinutes,
    required this.totalQuestions,
    required this.questions,
    this.attemptType = 'placement',
    this.status = 'inProgress',
    this.isResumed = false,
    this.expiresAt,
    this.serverNow,
    this.serverElapsedAtSync = Duration.zero,
    this.answers = const <int, int>{},
    this.currentQuestionIndex = 0,
  });

  final int id;
  final String attemptType;
  final String status;
  final bool isResumed;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime? serverNow;
  final Duration serverElapsedAtSync;
  final int timeLimitMinutes;
  final int totalQuestions;
  final List<PlacementTestQuestion> questions;
  final Map<int, int> answers;
  final int currentQuestionIndex;

  DateTime get deadline =>
      (expiresAt ?? startedAt.add(Duration(minutes: timeLimitMinutes))).toUtc();

  Duration remainingAtElapsed(Duration elapsed) {
    final serverElapsed = elapsed - serverElapsedAtSync;
    final remaining =
        deadline.difference((serverNow ?? startedAt).toUtc()) - serverElapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  PlacementTestAttempt copyWith({
    Map<int, int>? answers,
    int? currentQuestionIndex,
    Duration? serverElapsedAtSync,
  }) {
    return PlacementTestAttempt(
      id: id,
      attemptType: attemptType,
      status: status,
      isResumed: isResumed,
      startedAt: startedAt,
      expiresAt: expiresAt,
      serverNow: serverNow,
      serverElapsedAtSync: serverElapsedAtSync ?? this.serverElapsedAtSync,
      timeLimitMinutes: timeLimitMinutes,
      totalQuestions: totalQuestions,
      questions: questions,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}

@immutable
class PlacementTestAnswerSubmission {
  const PlacementTestAnswerSubmission({
    required this.questionId,
    required this.selectedOptionId,
  });

  final int questionId;
  final int? selectedOptionId;
}

@immutable
class PlacementLevelBreakdown {
  const PlacementLevelBreakdown({
    required this.jlptLevelId,
    required this.jlptLevelName,
    required this.correctCount,
    required this.totalCount,
    required this.scorePercent,
  });

  final int jlptLevelId;
  final String jlptLevelName;
  final int correctCount;
  final int totalCount;
  final double scorePercent;
}

@immutable
class PlacementSectionResult {
  const PlacementSectionResult({
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
class PlacementTestResult {
  const PlacementTestResult({
    required this.attemptId,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.totalScore,
    required this.correctCount,
    required this.totalQuestions,
    required this.assessedJlptLevelId,
    required this.assessedJlptLevelName,
    required this.recommendedTargetJlptLevelId,
    required this.recommendedTargetJlptLevelName,
    required this.wrongQuestionIds,
    required this.levelBreakdowns,
    required this.sections,
    this.attemptType = 'placement',
  });

  final int attemptId;
  final String attemptType;
  final MockTestAttemptStatus status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double totalScore;
  final int correctCount;
  final int totalQuestions;
  final int assessedJlptLevelId;
  final String assessedJlptLevelName;
  final int recommendedTargetJlptLevelId;
  final String recommendedTargetJlptLevelName;
  final List<int> wrongQuestionIds;
  final List<PlacementLevelBreakdown> levelBreakdowns;
  final List<PlacementSectionResult> sections;
}
