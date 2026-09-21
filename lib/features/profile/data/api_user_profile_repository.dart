import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/profile/data/user_profile_api_paths.dart';
import 'package:rikipath_mobile/features/profile/data/user_profile_dtos.dart';
import 'package:rikipath_mobile/features/profile/data/user_profile_mapper.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

class ApiUserProfileRepository implements UserProfileRepository {
  const ApiUserProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<UserProfile> loadProfile() async {
    final response = await _apiClient.get<Object?>(UserProfileApiPaths.me);
    return _readProfile(response.data);
  }

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final request = UpdateProfileRequestDto(
      firstName: firstName,
      lastName: lastName,
    );
    final response = await _apiClient.put<Object?>(
      UserProfileApiPaths.me,
      data: request.toJson(),
    );
    return _readProfile(response.data);
  }

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async {
    final formData = FormData.fromMap(<String, Object?>{
      'avatarFile': MultipartFile.fromBytes(
        upload.bytes,
        filename: upload.fileName,
        contentType: DioMediaType.parse(upload.contentType),
      ),
    });
    final response = await _apiClient.post<Object?>(
      UserProfileApiPaths.avatar,
      data: formData,
    );
    return _readProfile(response.data);
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    final request = SetJlptGoalRequestDto(
      targetJlptLevelId: targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
    );
    final response = await _apiClient.post<Object?>(
      UserProfileApiPaths.jlptGoal,
      data: request.toJson(),
    );
    return _readProfile(response.data);
  }

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async {
    final request = UpdateNotificationSettingsRequestDto(
      emailNotificationsEnabled: emailNotificationsEnabled,
      systemNotificationsEnabled: systemNotificationsEnabled,
    );
    final response = await _apiClient.put<Object?>(
      UserProfileApiPaths.notificationSettings,
      data: request.toJson(),
    );
    return _readProfile(response.data);
  }

  UserProfile _readProfile(Object? body) {
    try {
      return UserProfileMapper.fromRemote(UserProfileDto.fromEnvelope(body));
    } on FormatException {
      throw const UnknownError(
        message: 'The user profile response did not match the API contract.',
      );
    }
  }
}
