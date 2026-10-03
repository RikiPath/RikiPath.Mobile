import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/auth/application/auth_error_message.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

void main() {
  test('invalid credentials are mapped without exposing a raw exception', () {
    final message = authErrorMessage(
      const UnauthorizedError(),
      AuthOperation.login,
    );

    expect(message, contains('Email hoặc mật khẩu không đúng'));
    expect(message, isNot(contains('UnauthorizedError')));
  });

  test('network failure is mapped to learner-friendly Vietnamese', () {
    final message = authErrorMessage(const NetworkError(), AuthOperation.login);

    expect(message, contains('kiểm tra mạng'));
  });

  test('source-backed unverified-email response is safely classified', () {
    final message = authErrorMessage(
      const ValidationError(
        message: 'Vui lòng xác thực email trước khi đăng nhập.',
      ),
      AuthOperation.login,
    );

    expect(message, 'Vui lòng xác thực email trước khi đăng nhập.');
  });

  test('server failure is mapped without an HTTP body or stack trace', () {
    final message = authErrorMessage(
      const ServerError(statusCode: 500),
      AuthOperation.register,
    );

    expect(message, contains('RikiPath đang gặp sự cố'));
    expect(message, isNot(contains('500')));
  });

  test('resend validation uses dedicated safe feedback', () {
    final message = authErrorMessage(
      const ValidationError(message: 'raw backend resend detail'),
      AuthOperation.resendVerification,
    );

    expect(message, AppLocalizationsVi().authErrorResendValidation);
    expect(message, isNot(contains('raw backend')));
  });

  test('resend hourly limit uses dedicated localized feedback', () {
    final message = authErrorMessage(
      const ValidationError(
        message: 'Bạn đã vượt quá số lần gửi lại email trong 1 giờ.',
      ),
      AuthOperation.resendVerification,
    );

    expect(message, AppLocalizationsVi().authErrorResendRateLimited);
    expect(message, isNot(contains('1 giờ')));
  });

  test('unavailable password recovery has a learner-facing message', () {
    final message = authErrorMessage(
      const PasswordRecoveryUnavailableException(),
      AuthOperation.passwordRecovery,
    );

    expect(message, contains('chưa khả dụng trong ứng dụng'));
  });

  test('unsupported backend roles get a learner-app message', () {
    final message = authErrorMessage(
      const UnsupportedUserRoleException('Admin'),
      AuthOperation.login,
    );

    expect(
      message,
      'Ứng dụng di động hiện chỉ hỗ trợ tài khoản Học viên và Mentor.',
    );
    expect(message, isNot(contains('Admin')));
  });

  test('unknown failures do not expose exception details', () {
    final message = authErrorMessage(
      Exception('DioException: raw body'),
      AuthOperation.login,
    );

    expect(message, 'Đã có lỗi ngoài dự kiến. Vui lòng thử lại.');
  });
}
