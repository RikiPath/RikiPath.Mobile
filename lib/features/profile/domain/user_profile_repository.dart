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
