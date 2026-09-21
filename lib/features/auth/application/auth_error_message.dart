import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

enum AuthOperation {
  login,
  register,
  verifyEmail,
  updateEmail,
  changePassword,
  passwordRecovery,
}

String authErrorMessage(
  Object error,
  AuthOperation operation, [
  AppLocalizations? localizations,
]) {
  final l10n = localizations ?? AppLocalizationsVi();
  if (error is PasswordRecoveryUnavailableException) {
    return l10n.authErrorPasswordRecoveryUnavailable;
  }
  if (error is UnsupportedUserRoleException) {
    return l10n.authErrorUnsupportedRole;
  }
  if (error is NetworkError) {
    return l10n.authErrorNetwork;
  }
  if (error is UnauthorizedError) {
    return operation == AuthOperation.login
        ? l10n.authErrorInvalidCredentials
        : l10n.authErrorSessionExpired;
  }
  if (error is ForbiddenError) {
    return l10n.authErrorForbidden;
  }
  if (error is NotFoundError) {
    return l10n.authErrorNotFound;
  }
  if (error is ValidationError) {
    if (operation == AuthOperation.login) {
      final normalizedMessage = error.message.toLowerCase();
      if (normalizedMessage.contains('email hoặc mật khẩu')) {
        return l10n.authErrorInvalidCredentials;
      }
      if (normalizedMessage.contains('xác thực email')) {
        return l10n.authErrorEmailNotVerified;
      }
    }
    return switch (operation) {
      AuthOperation.login => l10n.authErrorLoginValidation,
      AuthOperation.register => l10n.authErrorRegisterValidation,
      AuthOperation.verifyEmail => l10n.authErrorVerifyValidation,
      AuthOperation.updateEmail => l10n.authErrorUpdateEmailValidation,
      AuthOperation.changePassword => l10n.authErrorChangePasswordValidation,
      AuthOperation.passwordRecovery => l10n.authErrorRecoveryValidation,
    };
  }
  if (error is ServerError) {
    return l10n.authErrorServer;
  }
  return l10n.authErrorUnknown;
}
