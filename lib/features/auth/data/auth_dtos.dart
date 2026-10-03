import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';

class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, Object?> toJson() => <String, Object?>{
    'email': email,
    'password': password,
  };
}

class RegisterRequestDto {
  const RegisterRequestDto({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.firstName,
    this.lastName,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String? firstName;
  final String? lastName;

  Map<String, Object?> toJson() => <String, Object?>{
    'email': email,
    'password': password,
    'confirmPassword': confirmPassword,
    'firstName': firstName,
    'lastName': lastName,
  };
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory LoginResponseDto.fromJson(Map<String, Object?> json) {
    final roleValue = _requiredString(json, 'role');
    final role = BackendUserRole.fromApiValue(roleValue);
    if (role == null) {
      throw FormatException('Unknown backend role: $roleValue.');
    }
    return LoginResponseDto(
      accessToken: _requiredString(json, 'accessToken'),
      userId: _requiredInt(json, 'userId'),
      email: _requiredString(json, 'email'),
      fullName: _requiredString(json, 'fullName'),
      role: role,
    );
  }

  final String accessToken;
  final int userId;
  final String email;
  final String fullName;
  final BackendUserRole role;
}

class RegisterResponseDto {
  const RegisterResponseDto({
    required this.fullName,
    required this.email,
    required this.userId,
  });

  factory RegisterResponseDto.fromJson(Map<String, Object?> json) {
    return RegisterResponseDto(
      fullName: _requiredString(json, 'fullName'),
      email: _requiredString(json, 'email'),
      userId: _requiredInt(json, 'userId'),
    );
  }

  final String fullName;
  final String email;
  final int userId;
}

class VerifyEmailRequestDto {
  const VerifyEmailRequestDto({
    required this.userId,
    required this.verificationCode,
  });

  final int userId;
  final String verificationCode;

  Map<String, Object?> toJson() => <String, Object?>{
    'userId': userId,
    'verificationCode': verificationCode,
  };
}

class ResendVerificationEmailRequestDto {
  const ResendVerificationEmailRequestDto({required this.email});

  final String email;

  Map<String, Object?> toJson() => <String, Object?>{'email': email};
}

class UpdateEmailRequestDto {
  const UpdateEmailRequestDto({required this.newEmail});

  final String newEmail;

  Map<String, Object?> toJson() => <String, Object?>{'newEmail': newEmail};
}

class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  Map<String, Object?> toJson() => <String, Object?>{
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int && value > 0) return value;
  throw FormatException('Expected a positive integer field named $field.');
}
