import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';

import '../../support/test_auth_session.dart';

void main() {
  const request = LoginRequestDto(
    email: 'learner@example.com',
    password: 'secret',
  );

  test('learner login stores the source-backed access token', () async {
    final secureStore = TestSecureKeyValueStore();
    final repository = ApiAuthRepository(
      apiClient: _StubApiClient(_loginEnvelope(role: 'Learner')),
      tokenStorage: TokenStorage(secureStore),
    );

    final response = await repository.login(request, persistSession: true);

    expect(response.role, 'Learner');
    expect(secureStore.values['access_token'], 'access-token');
  });

  test('non-learner login is rejected before token storage', () async {
    final secureStore = TestSecureKeyValueStore();
    final repository = ApiAuthRepository(
      apiClient: _StubApiClient(_loginEnvelope(role: 'Admin')),
      tokenStorage: TokenStorage(secureStore),
    );

    await expectLater(
      repository.login(request, persistSession: true),
      throwsA(
        isA<UnsupportedUserRoleException>().having(
          (error) => error.role,
          'role',
          'Admin',
        ),
      ),
    );
    expect(secureStore.values, isEmpty);
  });
}

Map<String, Object?> _loginEnvelope({required String role}) {
  return <String, Object?>{
    'statusCode': 200,
    'isSuccess': true,
    'result': <String, Object?>{
      'accessToken': 'access-token',
      'userId': 42,
      'email': 'learner@example.com',
      'fullName': 'Nguyễn Minh Anh',
      'role': role,
    },
  };
}

class _StubApiClient extends ApiClient {
  _StubApiClient(this._body) : super(Dio(), const ApiErrorMapper());

  final Object? _body;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: _body as T,
    );
  }
}
