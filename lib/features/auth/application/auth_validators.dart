import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String value, [AppLocalizations? localizations]) {
    final l10n = localizations ?? AppLocalizationsVi();
    final normalized = value.trim();
    if (normalized.isEmpty) return l10n.validationEmailRequired;
    if (!_emailPattern.hasMatch(normalized)) {
      return l10n.validationEmailInvalid;
    }
    return null;
  }

  static String? loginPassword(
    String value, [
    AppLocalizations? localizations,
  ]) {
    final l10n = localizations ?? AppLocalizationsVi();
    if (value.isEmpty) return l10n.validationPasswordRequired;
    return null;
  }

  static String? registrationPassword(
    String value, [
    AppLocalizations? localizations,
  ]) {
    final l10n = localizations ?? AppLocalizationsVi();
    if (value.isEmpty) return l10n.validationPasswordRequired;
    if (value.length < 6) return l10n.validationPasswordLength;
    return null;
  }

  static String? passwordConfirmation(
    String value,
    String password, [
    AppLocalizations? localizations,
  ]) {
    final l10n = localizations ?? AppLocalizationsVi();
    if (value.isEmpty) return l10n.validationConfirmPasswordRequired;
    if (value != password) return l10n.validationPasswordMismatch;
    return null;
  }

  static String? verificationCode(
    String value, [
    AppLocalizations? localizations,
  ]) {
    final l10n = localizations ?? AppLocalizationsVi();
    final normalized = value.trim();
    if (normalized.isEmpty) return l10n.validationVerificationCodeRequired;
    if (!RegExp(r'^\d{6}$').hasMatch(normalized)) {
      return l10n.validationVerificationCodeLength;
    }
    return null;
  }
}
