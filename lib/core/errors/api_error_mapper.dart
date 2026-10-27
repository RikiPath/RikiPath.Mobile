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
      DioExceptionType.badCertificate ||
      DioExceptionType.transformTimeout => const NetworkError(),
      DioExceptionType.cancel => const UnknownError(
        message: 'The request was cancelled.',
      ),
      DioExceptionType.badResponse => _fromResponse(exception.response),
      DioExceptionType.unknown =>
        exception.response == null
            ? const NetworkError()
            : _fromResponse(exception.response),
    };
  }

  ApiError? fromEnvelopeFailure(Object? data, {int? httpStatusCode}) {
    final payload = _BackendErrorPayload.tryParse(data);
    if (payload == null || payload.isSuccess != false) {
      return null;
    }

    return _fromPayload(payload, httpStatusCode: httpStatusCode);
  }

  ApiError _fromResponse(Response<dynamic>? response) {
    final payload = _BackendErrorPayload.tryParse(response?.data);
    return _fromPayload(payload, httpStatusCode: response?.statusCode);
  }

  ApiError _fromPayload(_BackendErrorPayload? payload, {int? httpStatusCode}) {
    final statusCode = _effectiveStatusCode(
      httpStatusCode,
      payload?.statusCode,
    );
    final details = payload?.errors ?? const <String>[];
    final message = payload?.errorMessage;
    final errorCode = payload?.errorCode;
    final retryable = payload?.retryable;

    if (statusCode == 400 || statusCode == 422) {
      return ValidationError(
        message: message ?? 'The request contains invalid data.',
        statusCode: statusCode!,
        errorCode: errorCode,
        retryable: retryable,
        details: details,
      );
    }
    if (statusCode == 401) {
      return UnauthorizedError(
        message: message ?? 'Authentication is required or has expired.',
        errorCode: errorCode,
        retryable: retryable,
        details: details,
      );
    }
    if (statusCode == 403) {
      return ForbiddenError(
        message:
            message ?? 'You do not have permission to perform this action.',
        errorCode: errorCode,
        retryable: retryable,
        details: details,
      );
    }
    if (statusCode == 404) {
      return NotFoundError(
        message: message ?? 'The requested resource was not found.',
        errorCode: errorCode,
        retryable: retryable,
        details: details,
      );
    }
    if (statusCode == 409) {
      return ConflictError(
        message:
            message ?? 'The request conflicts with the current resource state.',
        errorCode: errorCode,
        retryable: retryable,
        details: details,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerError(
        message: message ?? 'The server could not complete the request.',
        statusCode: statusCode,
        errorCode: errorCode,
        retryable: retryable,
        details: details,
      );
    }
    return UnknownError(
      message: message ?? 'The API request failed.',
      statusCode: statusCode,
      errorCode: errorCode,
      retryable: retryable,
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
    required this.errorCode,
    required this.retryable,
    required this.errors,
  });

  static _BackendErrorPayload? tryParse(Object? data) {
    if (data is! Map<Object?, Object?>) {
      return null;
    }

    final rawStatusCode = data['statusCode'] ?? data['status'];
    final rawErrorMessage = data['errorMessage'] ?? data['title'];
    final rawErrors = data['errors'];

    return _BackendErrorPayload(
      isSuccess: data['isSuccess'] is bool ? data['isSuccess'] as bool : null,
      statusCode: _readInteger(rawStatusCode),
      errorMessage:
          rawErrorMessage is String && rawErrorMessage.trim().isNotEmpty
          ? rawErrorMessage.trim()
          : null,
      errorCode: data['errorCode'] is String
          ? (data['errorCode'] as String).trim().isEmpty
                ? null
                : (data['errorCode'] as String).trim()
          : null,
      retryable: data['retryable'] is bool ? data['retryable'] as bool : null,
      errors: _readErrors(rawErrors),
    );
  }

  final bool? isSuccess;
  final int? statusCode;
  final String? errorMessage;
  final String? errorCode;
  final bool? retryable;
  final List<String> errors;
}

int? _readInteger(Object? value) {
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

List<String> _readErrors(Object? rawErrors) {
  if (rawErrors is List<Object?>) {
    return rawErrors
        .whereType<String>()
        .map((error) => error.trim())
        .where((error) => error.isNotEmpty)
        .toList(growable: false);
  }
  if (rawErrors is Map<Object?, Object?>) {
    return rawErrors.values
        .whereType<List<Object?>>()
        .expand((errors) => errors.whereType<String>())
        .map((error) => error.trim())
        .where((error) => error.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}
