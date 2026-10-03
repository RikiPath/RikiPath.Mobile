import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

final _apiErrorMapperProvider = Provider<ApiErrorMapper>((ref) {
  return const ApiErrorMapper();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(_dioProvider),
    ref.watch(_apiErrorMapperProvider),
    onUnauthorized: () async {
      final session = ref.read(authSessionControllerProvider);
      if (session.value == AuthSessionState.authenticated) {
        await session.signOut();
      }
    },
  );
});

final _dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl.toString(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      headers: const {'Accept': 'application/json'},
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);
  final configuredBaseUrl = config.apiBaseUrl;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (shouldAttachBearerToken(
          baseUrl: configuredBaseUrl,
          requestUrl: options.uri,
        )) {
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ),
  );

  if (config.shouldLogApi) {
    dio.interceptors.add(_ApiMetadataLogInterceptor());
  }

  return dio;
});

bool shouldAttachBearerToken({required Uri baseUrl, required Uri requestUrl}) {
  final resolvedRequest = baseUrl.resolveUri(requestUrl);
  return resolvedRequest.scheme.toLowerCase() == baseUrl.scheme.toLowerCase() &&
      resolvedRequest.host.toLowerCase() == baseUrl.host.toLowerCase() &&
      resolvedRequest.port == baseUrl.port;
}

class ApiClient {
  ApiClient(
    Dio dio,
    ApiErrorMapper errorMapper, {
    Future<void> Function()? onUnauthorized,
  }) : this._(dio, errorMapper, onUnauthorized);

  ApiClient._(this._dio, this._errorMapper, this._onUnauthorized);

  final Dio _dio;
  final ApiErrorMapper _errorMapper;
  final Future<void> Function()? _onUnauthorized;

  Uri get baseUrl => Uri.parse(_dio.options.baseUrl);
  Duration? get connectTimeout => _dio.options.connectTimeout;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _execute(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _execute(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _execute(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _execute(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _execute(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> _execute<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      final response = await request();
      final envelopeError = _errorMapper.fromEnvelopeFailure(
        response.data,
        httpStatusCode: response.statusCode,
      );
      if (envelopeError != null) {
        throw envelopeError;
      }
      return response;
    } on DioException catch (exception) {
      final error = _errorMapper.fromDioException(exception);
      await _invalidateUnauthorizedSession(error);
      throw error;
    } on UnauthorizedError catch (error) {
      await _invalidateUnauthorizedSession(error);
      rethrow;
    }
  }

  Future<void> _invalidateUnauthorizedSession(ApiError error) async {
    if (error is! UnauthorizedError || _onUnauthorized == null) return;
    try {
      await _onUnauthorized();
    } catch (_) {
      // Session cleanup failure must not replace the original 401 contract.
    }
  }
}

class _ApiMetadataLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] --> ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    debugPrint(
      '[API] <-- ${response.statusCode ?? '-'} ${request.method} '
      '${request.uri.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final request = error.requestOptions;
    debugPrint(
      '[API] <!! ${error.response?.statusCode ?? '-'} ${request.method} '
      '${request.uri.path}',
    );
    handler.next(error);
  }
}
