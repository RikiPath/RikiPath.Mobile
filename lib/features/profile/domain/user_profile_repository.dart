import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile> loadProfile();

  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  });

  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload);

  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  });

  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  });
}

abstract interface class TargetExamDateProfileRepository {
  Future<UserProfile> setJlptGoalWithExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime targetExamDate,
  });
}

abstract interface class ClearTargetExamDateProfileRepository {
  Future<UserProfile> clearJlptGoalExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  });
}

abstract interface class StudyLevelProfileRepository {
  Future<UserProfile> switchStudyLevel({required int currentStudyLevelId});
}

abstract interface class AtomicLearningGoalProfileRepository {
  Future<UserProfile> saveLearningGoal({
    required int currentStudyLevelId,
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime? targetExamDate,
    required int? certifiedJlptLevelId,
    required int expectedVersion,
  });
}
