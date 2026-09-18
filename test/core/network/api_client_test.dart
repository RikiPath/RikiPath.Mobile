import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';

void main() {
  test('API client is instantiated from environment configuration', () {
    final config = AppConfig.fromValues(const {
      'APP_ENV': 'development',
      'API_BASE_URL': 'http://140.245.43.97',
      'SWAGGER_URL': 'http://140.245.43.97/swagger/index.html',
      'ENABLE_API_LOGGING': 'false',
    });
    final container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(config)],
    );
    addTearDown(container.dispose);

    final client = container.read(apiClientProvider);

    expect(client.baseUrl, Uri.parse('http://140.245.43.97'));
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

  test('response transform timeout maps to a processing error', () {
    const mapper = ApiErrorMapper();
    final request = RequestOptions(path: '/api/large-response');
    final exception = DioException(
      requestOptions: request,
      type: DioExceptionType.transformTimeout,
    );

    final error = mapper.fromDioException(exception);

    expect(error, isA<UnknownError>());
    expect(error.message, 'The response took too long to process.');
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
