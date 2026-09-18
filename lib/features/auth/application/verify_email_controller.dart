import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/application/auth_validators.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

final verifyEmailControllerProvider =
    NotifierProvider<VerifyEmailController, VerifyEmailState>(
      VerifyEmailController.new,
    );

class VerifyEmailState {
  const VerifyEmailState({
    this.isLoading = false,
    this.codeError,
    this.serverError,
    this.succeeded = false,
  });

  final bool isLoading;
  final String? codeError;
  final String? serverError;
  final bool succeeded;
}

class VerifyEmailController extends Notifier<VerifyEmailState> {
  @override
  VerifyEmailState build() => const VerifyEmailState();

  void clearFeedback() {
    if (!state.isLoading && !state.succeeded) {
      state = const VerifyEmailState();
    }
  }

  void reset() => state = const VerifyEmailState();

  Future<bool> submit({
    required int? userId,
    required String verificationCode,
  }) async {
    if (state.isLoading) return false;
    if (userId == null) {
      state = const VerifyEmailState(
        serverError:
            'Máy chủ chưa cung cấp mã tài khoản cần thiết để xác thực email.',
      );
      return false;
    }

    final codeError = AuthValidators.verificationCode(verificationCode);
    if (codeError != null) {
      state = VerifyEmailState(codeError: codeError);
      return false;
    }

    state = const VerifyEmailState(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmail(
            VerifyEmailRequestDto(
              userId: userId,
              verificationCode: verificationCode.trim(),
            ),
          );
      state = const VerifyEmailState(succeeded: true);
      return true;
    } catch (error) {
      state = VerifyEmailState(
        serverError: authErrorMessage(error, AuthOperation.verifyEmail),
      );
      return false;
    }
  }
}
