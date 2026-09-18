import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
    );

enum ForgotPasswordStage { form, submitting, success }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.stage = ForgotPasswordStage.form,
    this.emailError,
    this.serverError,
    this.submittedEmail,
  });

  final ForgotPasswordStage stage;
  final String? emailError;
  final String? serverError;
  final String? submittedEmail;

  bool get isLoading => stage == ForgotPasswordStage.submitting;
  bool get succeeded => stage == ForgotPasswordStage.success;
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void clearFeedback() {
    if (!state.isLoading && !state.succeeded) {
      state = const ForgotPasswordState();
    }
  }

  void reset() => state = const ForgotPasswordState();

  Future<bool> submit(String email) async {
    if (state.isLoading) return false;

    final emailError = AuthValidators.email(email);
    if (emailError != null) {
      state = ForgotPasswordState(emailError: emailError);
      return false;
    }

    final normalizedEmail = email.trim();
    state = const ForgotPasswordState(stage: ForgotPasswordStage.submitting);
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(normalizedEmail);
      state = ForgotPasswordState(
        stage: ForgotPasswordStage.success,
        submittedEmail: normalizedEmail,
      );
      return true;
    } catch (error) {
      state = ForgotPasswordState(
        serverError: authErrorMessage(error, AuthOperation.passwordRecovery),
      );
      return false;
    }
  }
}
