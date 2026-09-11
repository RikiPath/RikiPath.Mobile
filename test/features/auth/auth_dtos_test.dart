import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';

void main() {
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
    expect(response.role, 'Learner');
  });
}
