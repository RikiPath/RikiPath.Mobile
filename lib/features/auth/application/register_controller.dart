import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(RegisterController.new);

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.agreementError,
    this.serverError,
    this.registeredAccount,
  });

  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? agreementError;
  final String? serverError;
  final RegisterResponseDto? registeredAccount;

  bool get succeeded => registeredAccount != null;
}

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  void clearFeedback() {
    if (!state.isLoading && !state.succeeded) state = const RegisterState();
  }

  void reset() => state = const RegisterState();

  Future<bool> submit({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    if (state.isLoading) return false;

    final emailError = AuthValidators.email(email);
    final passwordError = AuthValidators.registrationPassword(password);
    final confirmationError = AuthValidators.passwordConfirmation(
      confirmPassword,
      password,
    );
    final agreementError = acceptedTerms
        ? null
        : 'Vui lòng đồng ý với điều khoản trước khi đăng ký.';

    if (emailError != null ||
        passwordError != null ||
        confirmationError != null ||
        agreementError != null) {
      state = RegisterState(
        emailError: emailError,
        passwordError: passwordError,
        confirmPasswordError: confirmationError,
        agreementError: agreementError,
      );
      return false;
    }

    state = const RegisterState(isLoading: true);
    try {
      final name = _splitVietnameseFullName(fullName);
      final account = await ref
          .read(authRepositoryProvider)
          .register(
            RegisterRequestDto(
              email: email.trim(),
              password: password,
              confirmPassword: confirmPassword,
              firstName: name.firstName,
              lastName: name.lastName,
            ),
          );
      state = RegisterState(registeredAccount: account);
      return true;
    } catch (error) {
      state = RegisterState(
        serverError: authErrorMessage(error, AuthOperation.register),
      );
      return false;
    }
  }
}

({String? firstName, String? lastName}) _splitVietnameseFullName(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length == 1 && parts.single.isEmpty) {
    return (firstName: null, lastName: null);
  }
  if (parts.length == 1) {
    return (firstName: parts.single, lastName: null);
  }
  return (firstName: parts.skip(1).join(' '), lastName: parts.first);
}
