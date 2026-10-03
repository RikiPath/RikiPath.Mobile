import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';

void main() {
  test('backend role mapping uses only the verified enum literals', () {
    expect(BackendUserRole.values.map((role) => role.apiValue), const <String>[
      'Learner',
      'ContentAuthor',
      'Mentor',
      'Admin',
    ]);
    expect(
      BackendUserRole.values
          .where((role) => role.isMobileSupported)
          .map((role) => role.apiValue),
      const <String>['Learner', 'Mentor'],
    );
    expect(BackendUserRole.fromApiValue('Consultant'), isNull);
    expect(BackendUserRole.fromApiValue('learner'), isNull);
    expect(BackendUserRole.fromApiValue(' Learner'), isNull);
    expect(BackendUserRole.fromApiValue('Learner '), isNull);
    expect(BackendUserRole.fromApiValue(''), isNull);
  });

  test('login request uses the exact backend JSON field names', () {
    const request = LoginRequestDto(
      email: 'learner@example.com',
      password: 'secret',
    );

    expect(request.toJson(), const <String, Object?>{
      'email': 'learner@example.com',
      'password': 'secret',
    });
  });

  test('register request includes only contract-defined JSON fields', () {
    const request = RegisterRequestDto(
      email: 'learner@example.com',
      password: 'secret',
      confirmPassword: 'secret',
      firstName: 'Minh Anh',
      lastName: 'Nguyễn',
    );

    expect(request.toJson(), const <String, Object?>{
      'email': 'learner@example.com',
      'password': 'secret',
      'confirmPassword': 'secret',
      'firstName': 'Minh Anh',
      'lastName': 'Nguyễn',
    });
  });

  test('login response reads the exact access-token response contract', () {
    final response = LoginResponseDto.fromJson(const <String, Object?>{
      'accessToken': 'access-token',
      'userId': 42,
      'email': 'learner@example.com',
      'fullName': 'Nguyễn Minh Anh',
      'role': 'Learner',
    });

    expect(response.accessToken, 'access-token');
    expect(response.userId, 42);
    expect(response.role, BackendUserRole.learner);
  });

  test('register response reads the userId used by email verification', () {
    final response = RegisterResponseDto.fromJson(const <String, Object?>{
      'userId': 42,
      'fullName': 'Nguyễn Minh Anh',
      'email': 'learner@example.com',
    });

    expect(response.userId, 42);
    expect(response.fullName, 'Nguyễn Minh Anh');
    expect(response.email, 'learner@example.com');
  });

  test('register response rejects a missing verification userId', () {
    expect(
      () => RegisterResponseDto.fromJson(const <String, Object?>{
        'fullName': 'Nguyễn Minh Anh',
        'email': 'learner@example.com',
      }),
      throwsFormatException,
    );
  });

  test('register response rejects non-positive and non-integer userId', () {
    for (final invalidUserId in <Object?>[null, 0, -1, 42.5, '42']) {
      expect(
        () => RegisterResponseDto.fromJson(<String, Object?>{
          'userId': invalidUserId,
          'fullName': 'Nguyá»…n Minh Anh',
          'email': 'learner@example.com',
        }),
        throwsFormatException,
        reason: 'userId=$invalidUserId must not open email verification',
      );
    }
  });

  test('login response rejects unknown, null, and malformed role values', () {
    for (final invalidRole in <Object?>[
      null,
      '',
      'learner',
      ' Learner',
      'Learner ',
      'FutureRole',
    ]) {
      expect(
        () => LoginResponseDto.fromJson(<String, Object?>{
          'accessToken': 'token',
          'userId': 42,
          'email': 'learner@example.com',
          'fullName': 'Nguyá»…n Minh Anh',
          'role': invalidRole,
        }),
        throwsFormatException,
      );
    }
  });

  test('verify-email request uses exact backend JSON field names', () {
    const request = VerifyEmailRequestDto(
      userId: 42,
      verificationCode: '123456',
    );

    expect(request.toJson(), const <String, Object?>{
      'userId': 42,
      'verificationCode': '123456',
    });
  });

  test('resend verification request uses only the verified email field', () {
    const request = ResendVerificationEmailRequestDto(
      email: 'learner@example.com',
    );

    expect(request.toJson(), const <String, Object?>{
      'email': 'learner@example.com',
    });
  });

  test('update-email request uses only newEmail', () {
    const request = UpdateEmailRequestDto(newEmail: 'new@example.com');

    expect(request.toJson(), const <String, Object?>{
      'newEmail': 'new@example.com',
    });
  });

  test('change-password request uses exact password fields', () {
    const request = ChangePasswordRequestDto(
      currentPassword: 'current-secret',
      newPassword: 'new-secret',
      confirmPassword: 'new-secret',
    );

    expect(request.toJson(), const <String, Object?>{
      'currentPassword': 'current-secret',
      'newPassword': 'new-secret',
      'confirmPassword': 'new-secret',
    });
  });
}
