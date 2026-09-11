import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

enum AuthOperation { login, register, passwordRecovery }

String authErrorMessage(Object error, AuthOperation operation) {
  if (error is PasswordRecoveryUnavailableException) {
    return 'Tính năng lấy lại mật khẩu chưa được kết nối với máy chủ. '
        'Vui lòng liên hệ trung tâm trợ giúp.';
  }
  if (error is NetworkError) {
    return 'Không thể kết nối tới RikiPath. Vui lòng kiểm tra mạng và thử lại.';
  }
  if (error is UnauthorizedError) {
    return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
  }
  if (error is ValidationError) {
    if (operation == AuthOperation.login) {
      final normalizedMessage = error.message.toLowerCase();
      if (normalizedMessage.contains('email hoặc mật khẩu')) {
        return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
      }
      if (normalizedMessage.contains('xác thực email')) {
        return 'Vui lòng xác thực email trước khi đăng nhập.';
      }
    }
    return switch (operation) {
      AuthOperation.login =>
        'Thông tin đăng nhập chưa hợp lệ. Vui lòng kiểm tra lại.',
      AuthOperation.register =>
        'Thông tin đăng ký chưa hợp lệ hoặc email đã được sử dụng.',
      AuthOperation.passwordRecovery =>
        'Email chưa hợp lệ. Vui lòng kiểm tra lại.',
    };
  }
  if (error is ServerError) {
    return 'RikiPath đang gặp sự cố. Vui lòng thử lại sau ít phút.';
  }
  return 'Đã có lỗi ngoài dự kiến. Vui lòng thử lại.';
}
