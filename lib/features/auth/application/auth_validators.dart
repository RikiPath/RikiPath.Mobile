abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Vui lòng nhập email.';
    if (!_emailPattern.hasMatch(normalized)) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại định dạng.';
    }
    return null;
  }

  static String? loginPassword(String value) {
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    return null;
  }

  static String? registrationPassword(String value) {
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    return null;
  }

  static String? passwordConfirmation(String value, String password) {
    if (value.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (value != password) return 'Mật khẩu xác nhận không khớp.';
    return null;
  }

  static String? verificationCode(String value) {
    if (value.trim().isEmpty) return 'Vui lòng nhập mã xác thực.';
    return null;
  }
}
