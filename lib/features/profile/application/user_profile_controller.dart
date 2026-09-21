import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/data/api_user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return ApiUserProfileRepository(ref.watch(apiClientProvider));
});

final userProfileControllerProvider =
    AsyncNotifierProvider.autoDispose<UserProfileController, UserProfileState>(
      UserProfileController.new,
      retry: (_, _) => null,
    );

class UserProfileController extends AsyncNotifier<UserProfileState> {
  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  @override
  Future<UserProfileState> build() async {
    final profile = await ref
        .watch(userProfileRepositoryProvider)
        .loadProfile();
    return UserProfileState(profile: profile);
  }

  Future<void> retry() async {
    state = const AsyncLoading<UserProfileState>();
    state = await AsyncValue.guard(() async {
      final profile = await _repository.loadProfile();
      return UserProfileState(profile: profile);
    });
  }

  Future<bool> updateName({
    required String firstName,
    required String lastName,
  }) {
    return _mutate(
      flag: ProfileMutation.profile,
      request: () => _repository.updateProfile(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      ),
    );
  }

  Future<bool> uploadAvatar(ProfileAvatarUpload upload) {
    return _mutate(
      flag: ProfileMutation.avatar,
      request: () => _repository.uploadAvatar(upload),
    );
  }

  Future<bool> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) {
    return _mutate(
      flag: ProfileMutation.jlptGoal,
      request: () => _repository.setJlptGoal(
        targetJlptLevelId: targetJlptLevelId,
        dailyStudyMinutes: dailyStudyMinutes,
      ),
    );
  }

  Future<bool> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) {
    return _mutate(
      flag: ProfileMutation.notifications,
      request: () => _repository.updateNotificationSettings(
        emailNotificationsEnabled: emailNotificationsEnabled,
        systemNotificationsEnabled: systemNotificationsEnabled,
      ),
    );
  }

  void clearMutationError() {
    final current = state.value;
    if (current == null || current.mutationError == null) return;
    state = AsyncData(current.copyWith(clearMutationError: true));
  }

  Future<bool> _mutate({
    required ProfileMutation flag,
    required Future<UserProfile> Function() request,
  }) async {
    final current = state.value;
    if (current == null || current.activeMutation != null) return false;

    state = AsyncData(
      current.copyWith(activeMutation: flag, clearMutationError: true),
    );
    try {
      final profile = await request();
      state = AsyncData(UserProfileState(profile: profile));
      final l10n = ref.read(appLocalizationsProvider);
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(
            title: switch (flag) {
              ProfileMutation.profile => l10n.toastProfileUpdateSuccessTitle,
              ProfileMutation.avatar => l10n.toastAvatarUploadSuccessTitle,
              ProfileMutation.jlptGoal => l10n.toastJlptGoalUpdateSuccessTitle,
              ProfileMutation.notifications =>
                l10n.toastNotificationUpdateSuccessTitle,
            },
          );
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(mutationError: error, clearActiveMutation: true),
      );
      final l10n = ref.read(appLocalizationsProvider);
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: l10n.toastActionFailedTitle,
            description: userProfileErrorMessage(error, l10n),
          );
      return false;
    }
  }
}

enum ProfileMutation { profile, avatar, jlptGoal, notifications }

class UserProfileState {
  const UserProfileState({
    required this.profile,
    this.activeMutation,
    this.mutationError,
  });

  final UserProfile profile;
  final ProfileMutation? activeMutation;
  final Object? mutationError;

  UserProfileState copyWith({
    ProfileMutation? activeMutation,
    Object? mutationError,
    bool clearActiveMutation = false,
    bool clearMutationError = false,
  }) {
    return UserProfileState(
      profile: profile,
      activeMutation: clearActiveMutation
          ? null
          : activeMutation ?? this.activeMutation,
      mutationError: clearMutationError
          ? null
          : mutationError ?? this.mutationError,
    );
  }
}
