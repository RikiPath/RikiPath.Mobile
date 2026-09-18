import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

final changePasswordControllerProvider =
    NotifierProvider<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );

class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.currentPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.serverError,
    this.succeeded = false,
  });

  final bool isLoading;
  final String? currentPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final String? serverError;
  final bool succeeded;
}

class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  void clearFeedback() {
    if (!state.isLoading) state = const ChangePasswordState();
  }

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.isLoading) return false;

    final currentPasswordError = AuthValidators.loginPassword(currentPassword);
    final newPasswordError = AuthValidators.registrationPassword(newPassword);
    final confirmPasswordError = AuthValidators.passwordConfirmation(
      confirmPassword,
      newPassword,
    );
    if (currentPasswordError != null ||
        newPasswordError != null ||
        confirmPasswordError != null) {
      state = ChangePasswordState(
        currentPasswordError: currentPasswordError,
        newPasswordError: newPasswordError,
        confirmPasswordError: confirmPasswordError,
      );
      return false;
    }

    final session = ref.read(authSessionControllerProvider);
    final userId = session.currentUserId;
    if (session.value != AuthSessionState.authenticated || userId == null) {
      state = const ChangePasswordState(
        serverError:
            'Không tìm thấy mã tài khoản trong phiên hiện tại. Vui lòng đăng nhập lại.',
      );
      return false;
    }

    state = const ChangePasswordState(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            userId,
            ChangePasswordRequestDto(
              currentPassword: currentPassword,
              newPassword: newPassword,
              confirmPassword: confirmPassword,
            ),
          );
      state = const ChangePasswordState(succeeded: true);
      return true;
    } catch (error) {
      state = ChangePasswordState(
        serverError: authErrorMessage(error, AuthOperation.changePassword),
      );
      return false;
    }
  }
}
