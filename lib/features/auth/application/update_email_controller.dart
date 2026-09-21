import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

final updateEmailControllerProvider =
    NotifierProvider<UpdateEmailController, UpdateEmailState>(
      UpdateEmailController.new,
    );

class UpdateEmailState {
  const UpdateEmailState({
    this.isLoading = false,
    this.emailError,
    this.serverError,
    this.succeeded = false,
  });

  final bool isLoading;
  final String? emailError;
  final String? serverError;
  final bool succeeded;
}

class UpdateEmailController extends Notifier<UpdateEmailState> {
  @override
  UpdateEmailState build() => const UpdateEmailState();

  void clearFeedback() {
    if (!state.isLoading) state = const UpdateEmailState();
  }

  Future<bool> submit(String newEmail) async {
    if (state.isLoading) return false;

    final l10n = ref.read(appLocalizationsProvider);
    final emailError = AuthValidators.email(newEmail, l10n);
    if (emailError != null) {
      state = UpdateEmailState(emailError: emailError);
      return false;
    }

    final session = ref.read(authSessionControllerProvider);
    final userId = session.currentUserId;
    if (session.value != AuthSessionState.authenticated || userId == null) {
      state = UpdateEmailState(serverError: l10n.authErrorSessionMissingUserId);
      return false;
    }

    state = const UpdateEmailState(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateEmail(
            userId,
            UpdateEmailRequestDto(newEmail: newEmail.trim()),
          );
      state = const UpdateEmailState(succeeded: true);
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: l10n.toastEmailUpdateSuccessTitle);
      return true;
    } catch (error) {
      state = UpdateEmailState(
        serverError: authErrorMessage(error, AuthOperation.updateEmail, l10n),
      );
      return false;
    }
  }
}
