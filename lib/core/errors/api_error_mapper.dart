import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';

class ApiErrorMapper {
  const ApiErrorMapper();

  ApiError fromDioException(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => const NetworkError(),
      DioExceptionType.cancel => const UnknownError(
          message: 'The request was cancelled.',
        ),
      DioExceptionType.badResponse => _fromResponse(exception.response),
      DioExceptionType.unknown => exception.response == null
          ? const UnknownError()
          : _fromResponse(exception.response),
    };
  }

  ApiError? fromEnvelopeFailure(
    Object? data, {
    int? httpStatusCode,
  }) {
    final payload = _BackendErrorPayload.tryParse(data);
    if (payload == null || payload.isSuccess != false) {
      return null;
    }

    return _fromPayload(
      payload,
      httpStatusCode: httpStatusCode,
    );
  }

  ApiError _fromResponse(Response<dynamic>? response) {
    final payload = _BackendErrorPayload.tryParse(response?.data);
    return _fromPayload(
      payload,
      httpStatusCode: response?.statusCode,
    );
  }

  ApiError _fromPayload(
    _BackendErrorPayload? payload, {
    int? httpStatusCode,
  }) {
    final statusCode = _effectiveStatusCode(
      httpStatusCode,
      payload?.statusCode,
    );
    final details = payload?.errors ?? const <String>[];
    final message = payload?.errorMessage;

    if (statusCode == 400) {
      return ValidationError(
        message: message ?? 'The request contains invalid data.',
        statusCode: statusCode,
        details: details,
      );
    }
    if (statusCode == 401) {
      return UnauthorizedError(
        message: message ?? 'Authentication is required or has expired.',
        details: details,
      );
    }
    if (statusCode == 403) {
      return ForbiddenError(
        message:
            message ?? 'You do not have permission to perform this action.',
        details: details,
      );
    }
    if (statusCode == 404) {
      return NotFoundError(
        message: message ?? 'The requested resource was not found.',
        details: details,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerError(
        message: message ?? 'The server could not complete the request.',
        statusCode: statusCode,
        details: details,
      );
    }
    return UnknownError(
      message: message ?? 'The API request failed.',
      statusCode: statusCode,
      details: details,
    );
  }

  int? _effectiveStatusCode(int? httpStatusCode, int? payloadStatusCode) {
    if (httpStatusCode != null &&
        (httpStatusCode < 200 || httpStatusCode >= 300)) {
      return httpStatusCode;
    }
    return payloadStatusCode ?? httpStatusCode;
  }
}

class _BackendErrorPayload {
  const _BackendErrorPayload({
    required this.isSuccess,
    required this.statusCode,
    required this.errorMessage,
    required this.errors,
  });

  static _BackendErrorPayload? tryParse(Object? data) {
    if (data is! Map<Object?, Object?>) {
      return null;
    }

    final rawStatusCode = data['statusCode'];
    final rawErrorMessage = data['errorMessage'];
    final rawErrors = data['errors'];

    return _BackendErrorPayload(
      isSuccess: data['isSuccess'] is bool ? data['isSuccess'] as bool : null,
      statusCode: rawStatusCode is num ? rawStatusCode.toInt() : null,
      errorMessage: rawErrorMessage is String && rawErrorMessage.trim().isNotEmpty
          ? rawErrorMessage.trim()
          : null,
      errors: rawErrors is List<Object?>
          ? rawErrors
              .whereType<String>()
              .map((error) => error.trim())
              .where((error) => error.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }

  final bool? isSuccess;
  final int? statusCode;
  final String? errorMessage;
  final List<String> errors;
}
