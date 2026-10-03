import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.serverError,
    this.succeeded = false,
  });

  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? serverError;
  final bool succeeded;
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void clearFeedback() {
    if (!state.isLoading && !state.succeeded) state = const LoginState();
  }

  Future<bool> submit({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    if (state.isLoading) return false;

    final l10n = ref.read(appLocalizationsProvider);
    final emailError = AuthValidators.email(email, l10n);
    final passwordError = AuthValidators.loginPassword(password, l10n);
    if (emailError != null || passwordError != null) {
      state = LoginState(emailError: emailError, passwordError: passwordError);
      return false;
    }

    state = const LoginState(isLoading: true);
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .login(
            LoginRequestDto(email: email.trim(), password: password),
            persistSession: rememberSession,
          );
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(
            title: l10n.toastLoginSuccessTitle,
            description: l10n.toastLoginSuccessDescription,
          );
      ref
          .read(authSessionControllerProvider)
          .markAuthenticated(userId: account.userId, role: account.role);
      state = const LoginState(succeeded: true);
      return true;
    } catch (error) {
      final message = authErrorMessage(error, AuthOperation.login, l10n);
      state = LoginState(serverError: message);
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(title: l10n.loginFailedTitle, description: message);
      return false;
    }
  }
}
