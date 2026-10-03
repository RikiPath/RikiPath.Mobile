abstract final class AuthApiPaths {
  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String resendVerificationEmail =
      '/api/Auth/resend-verification-email';
  static const String verifyEmail = '/api/Auth/verify-email';

  static String updateEmail(int userId) => '/api/Auth/update-email/$userId';

  static String changePassword(int userId) =>
      '/api/Auth/change-password/$userId';
}
