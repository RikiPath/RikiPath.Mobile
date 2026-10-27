import 'package:rikipath_mobile/features/profile/data/user_profile_dtos.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

abstract final class UserProfileMapper {
  static UserProfile fromRemote(UserProfileDto dto) {
    return UserProfile(
      userId: dto.userId,
      email: dto.email,
      firstName: dto.firstName,
      lastName: dto.lastName,
      avatarUrl: _nonEmpty(dto.avatarUrl),
      role: dto.role,
      isEmailVerified: dto.isEmailVerified,
      targetJlptLevelId: dto.targetJlptLevelId,
      targetJlptLevelName: _nonEmpty(dto.targetJlptLevelName),
      startingJlptLevelId: dto.startingJlptLevelId ?? dto.targetJlptLevelId,
      startingJlptLevelName:
          _nonEmpty(dto.startingJlptLevelName) ??
          _nonEmpty(dto.targetJlptLevelName),
      currentStudyLevelId:
          dto.currentStudyLevelId ??
          dto.startingJlptLevelId ??
          dto.targetJlptLevelId,
      currentStudyLevelName:
          _nonEmpty(dto.currentStudyLevelName) ??
          _nonEmpty(dto.startingJlptLevelName) ??
          _nonEmpty(dto.targetJlptLevelName),
      learningMode: dto.learningMode.toUpperCase() == 'AI_PERSONALIZED'
          ? LearningMode.aiPersonalized
          : LearningMode.standard,
      assessedJlptLevelId: dto.assessedJlptLevelId,
      assessedJlptLevelName: _nonEmpty(dto.assessedJlptLevelName),
      placementDecision: switch (dto.placementDecision.toUpperCase()) {
        'SKIPPED' => PlacementDecision.skipped,
        'COMPLETED' => PlacementDecision.completed,
        _ => PlacementDecision.notTaken,
      },
      dailyStudyMinutes: dto.dailyStudyMinutes,
      targetExamDate: dto.targetExamDate,
      emailNotificationsEnabled: dto.emailNotificationsEnabled,
      systemNotificationsEnabled: dto.systemNotificationsEnabled,
    );
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
