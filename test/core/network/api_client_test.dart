import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';

import '../../support/test_auth_session.dart';

void main() {
  test('API client is instantiated from environment configuration', () {
    final config = AppConfig.fromValues(const {
      'APP_ENV': 'development',
      'API_PROFILE': 'remote',
      'API_BASE_URL': 'https://test.example.invalid',
      'SWAGGER_URL': 'https://test.example.invalid/swagger/index.html',
      'ENABLE_API_LOGGING': 'false',
    });
    final container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(config)],
    );
    addTearDown(container.dispose);

    final client = container.read(apiClientProvider);

    expect(client.baseUrl, Uri.parse('https://test.example.invalid'));
    expect(client.connectTimeout, const Duration(seconds: 15));
  });

  test('backend validation envelope maps to ValidationError', () {
    const mapper = ApiErrorMapper();
    final request = RequestOptions(path: '/api/Auth/register');
    final exception = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 400,
        data: const <String, Object?>{
          'statusCode': 400,
          'isSuccess': false,
          'errorMessage': 'Validation failed.',
          'errors': <String>['Email is required.'],
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = mapper.fromDioException(exception);

    expect(error, isA<ValidationError>());
    expect(error.message, 'Validation failed.');
    expect(error.statusCode, 400);
    expect(error.details, const ['Email is required.']);
  });

  test('response transform timeout maps to NetworkError', () {
    const mapper = ApiErrorMapper();
    final request = RequestOptions(path: '/api/large-response');
    final exception = DioException(
      requestOptions: request,
      type: DioExceptionType.transformTimeout,
    );

    final error = mapper.fromDioException(exception);

    expect(error, isA<NetworkError>());
  });

  test('connection reset or DNS failure maps to NetworkError', () {
    const mapper = ApiErrorMapper();
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/UserProfile/me'),
      type: DioExceptionType.unknown,
      error: const SocketException('Connection reset'),
    );

    expect(mapper.fromDioException(exception), isA<NetworkError>());
  });

  test('Bearer attachment is restricted to the configured API origin', () {
    final baseUrl = Uri.parse('http://140.245.43.97');

    expect(
      shouldAttachBearerToken(
        baseUrl: baseUrl,
        requestUrl: Uri.parse('http://140.245.43.97/api/UserProfile/me'),
      ),
      isTrue,
    );
    expect(
      shouldAttachBearerToken(
        baseUrl: baseUrl,
        requestUrl: Uri.parse('http://attacker.example/api/UserProfile/me'),
      ),
      isFalse,
    );
    expect(
      shouldAttachBearerToken(
        baseUrl: baseUrl,
        requestUrl: Uri.parse('https://140.245.43.97/api/UserProfile/me'),
      ),
      isFalse,
    );
  });

  test('failed 200 envelope uses its backend status code', () {
    const mapper = ApiErrorMapper();

    final error = mapper.fromEnvelopeFailure(const <String, Object?>{
      'statusCode': 401,
      'isSuccess': false,
      'errorMessage': 'Unauthorized.',
      'errors': <String>[],
    }, httpStatusCode: 200);

    expect(error, isA<UnauthorizedError>());
    expect(error?.message, 'Unauthorized.');
  });

  test('booking conflict envelope maps to ConflictError', () {
    const mapper = ApiErrorMapper();

    final error = mapper.fromEnvelopeFailure(const <String, Object?>{
      'statusCode': 409,
      'isSuccess': false,
      'errorMessage': 'Slot không còn trống.',
      'errors': <String>[],
    }, httpStatusCode: 409);

    expect(error, isA<ConflictError>());
    expect(error?.message, 'Slot không còn trống.');
    expect(error?.statusCode, 409);
  });

  test('422 envelope maps to ValidationError without changing status', () {
    const mapper = ApiErrorMapper();

    final error = mapper.fromEnvelopeFailure(const <String, Object?>{
      'statusCode': 422,
      'isSuccess': false,
      'errorMessage': 'Business validation failed.',
    }, httpStatusCode: 422);

    expect(error, isA<ValidationError>());
    expect(error?.statusCode, 422);
  });

  test('401 invalidates an authenticated session exactly once', () async {
    final session = createTestAuthSession(
      initialState: AuthSessionState.authenticated,
      userId: 42,
      role: BackendUserRole.learner,
    );
    addTearDown(session.dispose);
    final client = ApiClient(
      Dio()..httpClientAdapter = _StatusAdapter(401),
      const ApiErrorMapper(),
      onUnauthorized: session.signOut,
    );

    await expectLater(
      client.get<Object?>('/protected'),
      throwsA(isA<UnauthorizedError>()),
    );

    expect(session.value, AuthSessionState.unauthenticated);
    expect(session.currentUserId, isNull);
  });

  for (final status in <int>[403, 404, 500]) {
    test('$status does not invalidate an authenticated session', () async {
      var invalidations = 0;
      final client = ApiClient(
        Dio()..httpClientAdapter = _StatusAdapter(status),
        const ApiErrorMapper(),
        onUnauthorized: () async {
          invalidations++;
        },
      );

      await expectLater(client.get<Object?>('/protected'), throwsA(anything));

      expect(invalidations, 0);
    });
  }

  test('failed 200 envelope with 401 invokes session invalidation', () async {
    var invalidations = 0;
    final client = ApiClient(
      Dio()..httpClientAdapter = _EnvelopeAdapter(),
      const ApiErrorMapper(),
      onUnauthorized: () async {
        invalidations++;
      },
    );

    await expectLater(
      client.get<Object?>('/expired-envelope'),
      throwsA(isA<UnauthorizedError>()),
    );

    expect(invalidations, 1);
  });

  test('session cleanup failure does not hide the original 401', () async {
    final client = ApiClient(
      Dio()..httpClientAdapter = _StatusAdapter(401),
      const ApiErrorMapper(),
      onUnauthorized: () async => throw StateError('storage unavailable'),
    );

    await expectLater(
      client.get<Object?>('/protected'),
      throwsA(isA<UnauthorizedError>()),
    );
  });

  test('403 remains forbidden and does not become an auth-session error', () {
    const mapper = ApiErrorMapper();
    final request = RequestOptions(path: '/api/MentorMeeting/availability');
    final error = mapper.fromDioException(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 403,
          data: '<html>Forbidden</html>',
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error, isA<ForbiddenError>());
    expect(error, isNot(isA<UnauthorizedError>()));
    expect(error.toString(), isNot(contains('<html>')));
  });

  test('non-JSON 500 response maps safely without exposing the body', () {
    const mapper = ApiErrorMapper();
    final request = RequestOptions(path: '/api/SharedBank/vocabulary/search');
    final error = mapper.fromDioException(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 500,
          data: '<html>proxy failure</html>',
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error, isA<ServerError>());
    expect(error.toString(), isNot(contains('proxy failure')));
  });

  test('ASP.NET validation problem maps field errors without traceId', () {
    const mapper = ApiErrorMapper();
    final request = RequestOptions(path: '/api/Auth/register');
    final exception = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 400,
        data: const <String, Object?>{
          'type': 'https://tools.ietf.org/html/rfc9110',
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': <String, Object?>{
            'Email': <String>['The Email field is required.'],
            'Password': <String>['The Password field is required.'],
          },
          'traceId': '00-secret-diagnostic-id',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = mapper.fromDioException(exception);

    expect(error, isA<ValidationError>());
    expect(error.details, const [
      'The Email field is required.',
      'The Password field is required.',
    ]);
    expect(error.toString(), isNot(contains('traceId')));
    expect(error.toString(), isNot(contains('secret-diagnostic-id')));
  });
}

class _StatusAdapter implements HttpClientAdapter {
  const _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"statusCode":$statusCode,"isSuccess":false}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _EnvelopeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"statusCode":401,"isSuccess":false}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
