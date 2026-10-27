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
      dailyStudyMinutes: dto.dailyStudyMinutes,
      emailNotificationsEnabled: dto.emailNotificationsEnabled,
      systemNotificationsEnabled: dto.systemNotificationsEnabled,
    );
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
