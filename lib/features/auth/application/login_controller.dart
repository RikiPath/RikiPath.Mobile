import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final emailError = AuthValidators.email(email);
    final passwordError = AuthValidators.loginPassword(password);
    if (emailError != null || passwordError != null) {
      state = LoginState(emailError: emailError, passwordError: passwordError);
      return false;
    }

    state = const LoginState(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .login(
            LoginRequestDto(email: email.trim(), password: password),
            persistSession: rememberSession,
          );
      ref.read(authSessionControllerProvider).markAuthenticated();
      state = const LoginState(succeeded: true);
      return true;
    } catch (error) {
      state = LoginState(
        serverError: authErrorMessage(error, AuthOperation.login),
      );
      return false;
    }
  }
}
