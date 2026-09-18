import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/data/auth_api_paths.dart';
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
    final apiClient = _StubApiClient(_loginEnvelope(role: 'Learner'));
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStorage: TokenStorage(secureStore),
    );

    final response = await repository.login(request, persistSession: true);

    expect(apiClient.lastPath, AuthApiPaths.login);
    expect(apiClient.lastData, request.toJson());
    expect(response.role, 'Learner');
    expect(secureStore.values['access_token'], 'access-token');
    expect(secureStore.values['authenticated_user_id'], '42');
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

  test(
    'register uses the exact endpoint and does not create an auth session',
    () async {
      const registerRequest = RegisterRequestDto(
        email: 'learner@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        firstName: 'Minh Anh',
        lastName: 'Nguyễn',
      );
      final secureStore = TestSecureKeyValueStore();
      final tokenStorage = TokenStorage(secureStore);
      final apiClient = _StubApiClient(_registerEnvelope());
      final repository = ApiAuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final response = await repository.register(registerRequest);

      expect(apiClient.lastPath, AuthApiPaths.register);
      expect(apiClient.lastData, registerRequest.toJson());
      expect(response.fullName, 'Nguyễn Minh Anh');
      expect(response.email, 'learner@example.com');
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(secureStore.values, isEmpty);
    },
  );

  test('unexpected login body is rejected without storing a token', () async {
    final secureStore = TestSecureKeyValueStore();
    final repository = ApiAuthRepository(
      apiClient: _StubApiClient(const <String, Object?>{
        'statusCode': 200,
        'isSuccess': true,
        'result': <String, Object?>{'accessToken': 'access-token'},
      }),
      tokenStorage: TokenStorage(secureStore),
    );

    await expectLater(
      repository.login(request, persistSession: true),
      throwsA(isA<UnknownError>()),
    );
    expect(secureStore.values, isEmpty);
  });

  test('verify email posts the exact source-backed request', () async {
    const verifyRequest = VerifyEmailRequestDto(
      userId: 42,
      verificationCode: '123456',
    );
    final apiClient = _StubApiClient(_successEnvelope());
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStorage: TokenStorage(TestSecureKeyValueStore()),
    );

    await repository.verifyEmail(verifyRequest);

    expect(apiClient.lastMethod, 'POST');
    expect(apiClient.lastPath, AuthApiPaths.verifyEmail);
    expect(apiClient.lastData, verifyRequest.toJson());
  });

  test(
    'update email uses the authenticated user path and exact body',
    () async {
      const updateRequest = UpdateEmailRequestDto(newEmail: 'new@example.com');
      final secureStore = TestSecureKeyValueStore(
        accessToken: 'access-token',
        userId: 42,
      );
      final apiClient = _StubApiClient(_successEnvelope());
      final repository = ApiAuthRepository(
        apiClient: apiClient,
        tokenStorage: TokenStorage(secureStore),
      );

      await repository.updateEmail(42, updateRequest);

      expect(apiClient.lastMethod, 'PUT');
      expect(apiClient.lastPath, AuthApiPaths.updateEmail(42));
      expect(apiClient.lastData, updateRequest.toJson());
      expect(secureStore.values['access_token'], 'access-token');
      expect(secureStore.values['authenticated_user_id'], '42');
    },
  );

  test(
    'change password neither stores passwords nor replaces session',
    () async {
      const changeRequest = ChangePasswordRequestDto(
        currentPassword: 'current-secret',
        newPassword: 'new-secret',
        confirmPassword: 'new-secret',
      );
      final secureStore = TestSecureKeyValueStore(
        accessToken: 'access-token',
        userId: 42,
      );
      final apiClient = _StubApiClient(_successEnvelope());
      final repository = ApiAuthRepository(
        apiClient: apiClient,
        tokenStorage: TokenStorage(secureStore),
      );

      await repository.changePassword(42, changeRequest);

      expect(apiClient.lastMethod, 'POST');
      expect(apiClient.lastPath, AuthApiPaths.changePassword(42));
      expect(apiClient.lastData, changeRequest.toJson());
      expect(secureStore.values, const <String, String>{
        'access_token': 'access-token',
        'authenticated_user_id': '42',
      });
    },
  );
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

Map<String, Object?> _registerEnvelope() {
  return const <String, Object?>{
    'statusCode': 201,
    'isSuccess': true,
    'result': <String, Object?>{
      'fullName': 'Nguyễn Minh Anh',
      'email': 'learner@example.com',
    },
  };
}

Map<String, Object?> _successEnvelope() {
  return const <String, Object?>{'statusCode': 200, 'isSuccess': true};
}

class _StubApiClient extends ApiClient {
  _StubApiClient(this._body) : super(Dio(), const ApiErrorMapper());

  final Object? _body;
  String? lastPath;
  Object? lastData;
  String? lastMethod;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastData = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: _body as T,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastData = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: _body as T,
    );
  }
}
