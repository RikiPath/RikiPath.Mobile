import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_dtos.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

abstract final class PlacementTestMapper {
  static PlacementTestStatus status(PlacementTestStatusDto dto) {
    _requirePlacementType(dto.attemptType);
    return PlacementTestStatus(
      attemptType: dto.attemptType,
      hasActiveAttempt: dto.hasActiveAttempt,
      activeAttemptId: dto.activeAttemptId,
      activeAttemptExpiresAt: dto.activeAttemptExpiresAt,
      hasCompletedPlacementTest: dto.hasCompletedPlacementTest,
      latestCompletedAttemptId: dto.latestCompletedAttemptId,
      latestSubmittedAt: dto.latestSubmittedAt,
      latestScorePercent: dto.latestScorePercent,
      assessedJlptLevelId: dto.assessedJlptLevelId,
      assessedJlptLevelName: dto.assessedJlptLevelName,
      recommendedTargetJlptLevelId: dto.recommendedTargetJlptLevelId,
      recommendedTargetJlptLevelName: dto.recommendedTargetJlptLevelName,
      targetJlptLevelId: dto.targetJlptLevelId,
      targetJlptLevelName: dto.targetJlptLevelName,
      dailyStudyMinutes: dto.dailyStudyMinutes,
      targetExamDate: dto.targetExamDate,
      isReadyForLearningPath: dto.isReadyForLearningPath,
      placementDecision: switch (dto.placementDecision.toUpperCase()) {
        'SKIPPED' => PlacementDecision.skipped,
        'COMPLETED' => PlacementDecision.completed,
        _ => PlacementDecision.notTaken,
      },
    );
  }

  static PlacementTestAttempt attempt(StartPlacementTestDto dto) {
    _requirePlacementType(dto.attemptType);
    if (dto.status != 'inProgress') {
      throw FormatException(
        'Unsupported active Placement Test status: ${dto.status}',
      );
    }
    return PlacementTestAttempt(
      id: dto.attemptId,
      attemptType: dto.attemptType,
      status: dto.status,
      isResumed: dto.isResumed,
      startedAt: dto.startedAt,
      expiresAt: dto.expiresAt,
      serverNow: dto.serverNow,
      timeLimitMinutes: dto.timeLimitMinutes,
      totalQuestions: dto.totalQuestions,
      questions: dto.questions
          .map(
            (q) => PlacementTestQuestion(
              id: q.questionId,
              mockTestId: q.mockTestId,
              mockTestSectionId: q.mockTestSectionId,
              sectionTitle: q.sectionTitle,
              sectionOrder: q.sectionOrder,
              jlptLevelId: q.jlptLevelId,
              jlptLevelName: q.jlptLevelName,
              order: q.order,
              content: q.content,
              audioUrl: q.audioUrl,
              imageUrl: q.imageUrl,
              options: q.options
                  .map(
                    (o) => PlacementTestOption(
                      id: o.optionId,
                      content: o.content,
                      order: o.order,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  static PlacementTestResult result(PlacementTestResultDto dto) {
    _requirePlacementType(dto.attemptType);
    final status = MockTestAttemptStatus.fromApiValue(dto.status);
    if (status == null) {
      throw FormatException('Unsupported Placement Test status: ${dto.status}');
    }
    return PlacementTestResult(
      attemptId: dto.attemptId,
      attemptType: dto.attemptType,
      status: status,
      startedAt: dto.startedAt,
      submittedAt: dto.submittedAt,
      totalScore: dto.totalScore,
      correctCount: dto.correctCount,
      totalQuestions: dto.totalQuestions,
      assessedJlptLevelId: dto.assessedJlptLevelId,
      assessedJlptLevelName: dto.assessedJlptLevelName,
      recommendedTargetJlptLevelId: dto.recommendedTargetJlptLevelId,
      recommendedTargetJlptLevelName: dto.recommendedTargetJlptLevelName,
      wrongQuestionIds: dto.wrongQuestionIds,
      levelBreakdowns: dto.levelBreakdowns
          .map(
            (item) => PlacementLevelBreakdown(
              jlptLevelId: item.jlptLevelId,
              jlptLevelName: item.jlptLevelName,
              correctCount: item.correctCount,
              totalCount: item.totalCount,
              scorePercent: item.scorePercent,
            ),
          )
          .toList(growable: false),
      sections: dto.sections
          .map(
            (s) => PlacementSectionResult(
              mockTestSectionId: s.mockTestSectionId,
              sectionTitle: s.sectionTitle,
              languageSkillName: s.languageSkillName,
              correctCount: s.correctCount,
              totalCount: s.totalCount,
              score: s.score,
            ),
          )
          .toList(growable: false),
    );
  }

  static void _requirePlacementType(String attemptType) {
    if (attemptType != 'placement') {
      throw FormatException(
        'Unsupported Placement Test attemptType: $attemptType',
      );
    }
  }
}
