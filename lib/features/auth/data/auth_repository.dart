import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/data/auth_api_paths.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/domain/jwt_session_claims.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

abstract interface class AuthRepository {
  Future<LoginResponseDto> login(
    LoginRequestDto request, {
    required bool persistSession,
  });

  Future<RegisterResponseDto> register(RegisterRequestDto request);

  Future<void> verifyEmail(VerifyEmailRequestDto request);

  Future<void> resendVerificationEmail(
    ResendVerificationEmailRequestDto request,
  );

  Future<void> updateEmail(int userId, UpdateEmailRequestDto request);

  Future<void> changePassword(int userId, ChangePasswordRequestDto request);

  Future<void> requestPasswordReset(String email);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required this._apiClient, required this._tokenStorage});

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<LoginResponseDto> login(
    LoginRequestDto request, {
    required bool persistSession,
  }) async {
    final response = await _apiClient.post<Object?>(
      AuthApiPaths.login,
      data: request.toJson(),
    );
    final result = _readResult(response.data);

    try {
      final login = LoginResponseDto.fromJson(result);
      final claims = JwtSessionClaims.parse(login.accessToken);
      if (claims.userId != login.userId ||
          claims.role != login.role ||
          claims.isExpiredAt(DateTime.now().toUtc())) {
        throw const FormatException(
          'Login response and access-token claims are inconsistent.',
        );
      }
      if (!login.role.isMobileSupported) {
        throw UnsupportedUserRoleException(login.role.apiValue);
      }
      await _tokenStorage.saveAuthenticatedSession(
        accessToken: login.accessToken,
        userId: login.userId,
        role: login.role.apiValue,
        persist: persistSession,
      );
      return login;
    } on FormatException {
      throw const UnknownError(
        message: 'The login response did not match the API contract.',
      );
    }
  }

  @override
  Future<void> verifyEmail(VerifyEmailRequestDto request) async {
    final response = await _apiClient.post<Object?>(
      AuthApiPaths.verifyEmail,
      data: request.toJson(),
    );
    _ensureSuccessEnvelope(response.data);
  }

  @override
  Future<void> resendVerificationEmail(
    ResendVerificationEmailRequestDto request,
  ) async {
    final response = await _apiClient.post<Object?>(
      AuthApiPaths.resendVerificationEmail,
      data: request.toJson(),
    );
    _ensureSuccessEnvelope(response.data);
  }

  @override
  Future<void> updateEmail(int userId, UpdateEmailRequestDto request) async {
    final response = await _apiClient.put<Object?>(
      AuthApiPaths.updateEmail(userId),
      data: request.toJson(),
    );
    _ensureSuccessEnvelope(response.data);
  }

  @override
  Future<void> changePassword(
    int userId,
    ChangePasswordRequestDto request,
  ) async {
    final response = await _apiClient.post<Object?>(
      AuthApiPaths.changePassword(userId),
      data: request.toJson(),
    );
    _ensureSuccessEnvelope(response.data);
  }

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    final response = await _apiClient.post<Object?>(
      AuthApiPaths.register,
      data: request.toJson(),
    );
    final result = _readResult(response.data);

    try {
      return RegisterResponseDto.fromJson(result);
    } on FormatException {
      throw const UnknownError(
        message: 'The registration response did not match the API contract.',
      );
    }
  }

  @override
  Future<void> requestPasswordReset(String email) {
    // TODO(auth-api): Connect this only after a password-recovery endpoint and
    // request/response contract are published by the backend.
    throw const PasswordRecoveryUnavailableException();
  }
}

class PasswordRecoveryUnavailableException implements Exception {
  const PasswordRecoveryUnavailableException();
}

class UnsupportedUserRoleException implements Exception {
  const UnsupportedUserRoleException(this.role);

  final String role;
}

Map<String, Object?> _readResult(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const UnknownError(
      message: 'The API returned an invalid success envelope.',
    );
  }
  return _stringKeyedMap(envelope['result']);
}

void _ensureSuccessEnvelope(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const UnknownError(
      message: 'The API returned an invalid success envelope.',
    );
  }
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const UnknownError(
      message: 'The API response did not match the expected JSON object.',
    );
  }

  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw const UnknownError(
        message: 'The API response contained a non-string JSON key.',
      );
    }
    result[key] = entry.value;
  }
  return result;
}
