import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

const verifyEmailResendCooldown = Duration(seconds: 60);

typedef VerifyEmailClock = DateTime Function();

final verifyEmailClockProvider = Provider<VerifyEmailClock>(
  (ref) => DateTime.now,
);

final verifyEmailControllerProvider =
    NotifierProvider.autoDispose<VerifyEmailController, VerifyEmailState>(
      VerifyEmailController.new,
    );

class VerifyEmailState {
  const VerifyEmailState({
    this.isLoading = false,
    this.isResending = false,
    this.codeError,
    this.serverError,
    this.resendError,
    this.resendSucceeded = false,
    this.resendCooldownSeconds = 0,
    this.succeeded = false,
  });

  final bool isLoading;
  final bool isResending;
  final String? codeError;
  final String? serverError;
  final String? resendError;
  final bool resendSucceeded;
  final int resendCooldownSeconds;
  final bool succeeded;

  bool get isBusy => isLoading || isResending;
}

class VerifyEmailController extends Notifier<VerifyEmailState> {
  Timer? _resendCooldownTimer;
  DateTime? _resendAvailableAt;
  String? _cooldownEmail;

  @override
  VerifyEmailState build() {
    ref.onDispose(() => _resendCooldownTimer?.cancel());
    return const VerifyEmailState();
  }

  void clearFeedback() {
    if (!state.isBusy && !state.succeeded) {
      state = VerifyEmailState(
        resendSucceeded: state.resendSucceeded,
        resendCooldownSeconds: state.resendCooldownSeconds,
      );
    }
  }

  void reset() {
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = null;
    _resendAvailableAt = null;
    _cooldownEmail = null;
    state = const VerifyEmailState();
  }

  void startInitialCooldown({required String? email}) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) return;

    if (_cooldownEmail != normalizedEmail) {
      _resendCooldownTimer?.cancel();
      _resendCooldownTimer = null;
      _resendAvailableAt = null;
      _cooldownEmail = normalizedEmail;
      state = const VerifyEmailState();
    }

    _resendAvailableAt ??= _now().add(verifyEmailResendCooldown);
    _publishCooldown();
    _startResendCooldownTicker();
  }

  void refreshCooldown() {
    if (_resendAvailableAt == null) return;
    _publishCooldown();
    if (state.resendCooldownSeconds > 0) {
      _startResendCooldownTicker();
    }
  }

  Future<bool> submit({
    required int? userId,
    required String verificationCode,
  }) async {
    if (state.isBusy) return false;
    final l10n = ref.read(appLocalizationsProvider);
    if (userId == null || userId <= 0) {
      state = VerifyEmailState(
        serverError: l10n.authErrorVerifyMissingUserId,
        resendSucceeded: state.resendSucceeded,
        resendCooldownSeconds: state.resendCooldownSeconds,
      );
      return false;
    }

    final codeError = AuthValidators.verificationCode(verificationCode, l10n);
    if (codeError != null) {
      state = VerifyEmailState(
        codeError: codeError,
        resendSucceeded: state.resendSucceeded,
        resendCooldownSeconds: state.resendCooldownSeconds,
      );
      return false;
    }

    state = VerifyEmailState(
      isLoading: true,
      resendSucceeded: state.resendSucceeded,
      resendCooldownSeconds: state.resendCooldownSeconds,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmail(
            VerifyEmailRequestDto(
              userId: userId,
              verificationCode: verificationCode.trim(),
            ),
          );
      if (!ref.mounted) return false;
      _resendCooldownTimer?.cancel();
      _resendCooldownTimer = null;
      _resendAvailableAt = null;
      state = const VerifyEmailState(succeeded: true);
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = VerifyEmailState(
        serverError: authErrorMessage(error, AuthOperation.verifyEmail, l10n),
        resendSucceeded: state.resendSucceeded,
        resendCooldownSeconds: state.resendCooldownSeconds,
      );
      return false;
    }
  }

  Future<bool> resend({required String? email}) async {
    if (state.isBusy || state.resendCooldownSeconds > 0) return false;

    final l10n = ref.read(appLocalizationsProvider);
    if (email == null || AuthValidators.email(email, l10n) != null) {
      state = VerifyEmailState(
        codeError: state.codeError,
        resendError: l10n.authErrorResendMissingEmail,
      );
      return false;
    }

    state = VerifyEmailState(isResending: true, codeError: state.codeError);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerificationEmail(
            ResendVerificationEmailRequestDto(email: email.trim()),
          );
      if (!ref.mounted) return false;
      _setResendDeadline();
      state = VerifyEmailState(
        codeError: state.codeError,
        resendSucceeded: true,
        resendCooldownSeconds: _remainingCooldownSeconds(),
      );
      _startResendCooldownTicker();
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final shouldUseConservativeCooldown =
          error is NetworkError ||
          error is ServerError ||
          error is UnknownError;
      if (shouldUseConservativeCooldown) {
        _setResendDeadline();
      }
      state = VerifyEmailState(
        codeError: state.codeError,
        resendError: authErrorMessage(
          error,
          AuthOperation.resendVerification,
          l10n,
        ),
        resendCooldownSeconds: shouldUseConservativeCooldown
            ? _remainingCooldownSeconds()
            : 0,
      );
      if (shouldUseConservativeCooldown) {
        _startResendCooldownTicker();
      }
      return false;
    }
  }

  DateTime _now() => ref.read(verifyEmailClockProvider)();

  void _setResendDeadline() {
    _resendAvailableAt = _now().add(verifyEmailResendCooldown);
  }

  int _remainingCooldownSeconds() {
    final availableAt = _resendAvailableAt;
    if (availableAt == null) return 0;
    final milliseconds = availableAt.difference(_now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / Duration.millisecondsPerSecond).ceil();
  }

  void _publishCooldown() {
    final remaining = _remainingCooldownSeconds();
    if (remaining == 0) {
      _resendAvailableAt = null;
    }
    state = VerifyEmailState(
      isLoading: state.isLoading,
      isResending: state.isResending,
      codeError: state.codeError,
      serverError: state.serverError,
      resendError: state.resendError,
      resendSucceeded: state.resendSucceeded,
      resendCooldownSeconds: remaining,
      succeeded: state.succeeded,
    );
  }

  void _startResendCooldownTicker() {
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        _resendCooldownTimer = null;
        return;
      }
      _publishCooldown();
      if (state.resendCooldownSeconds == 0) {
        timer.cancel();
        _resendCooldownTimer = null;
      }
    });
  }
}
