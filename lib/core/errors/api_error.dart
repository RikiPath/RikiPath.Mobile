sealed class ApiError implements Exception {
  const ApiError(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.retryable,
    this.details = const [],
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final bool? retryable;
  final List<String> details;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkError extends ApiError {
  const NetworkError({
    String message = 'Unable to reach the server. Please try again.',
    String? errorCode,
    bool? retryable,
  }) : super(message, errorCode: errorCode, retryable: retryable);
}

final class UnauthorizedError extends ApiError {
  const UnauthorizedError({
    String message = 'Authentication is required or has expired.',
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: 401,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}

final class ForbiddenError extends ApiError {
  const ForbiddenError({
    String message = 'You do not have permission to perform this action.',
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: 403,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}

final class NotFoundError extends ApiError {
  const NotFoundError({
    String message = 'The requested resource was not found.',
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: 404,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}

final class ConflictError extends ApiError {
  const ConflictError({
    String message = 'The request conflicts with the current resource state.',
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: 409,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}

final class ValidationError extends ApiError {
  const ValidationError({
    String message = 'The request contains invalid data.',
    int statusCode = 400,
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: statusCode,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}

final class ServerError extends ApiError {
  const ServerError({
    String message = 'The server could not complete the request.',
    required int statusCode,
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: statusCode,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}

final class UnknownError extends ApiError {
  const UnknownError({
    String message = 'An unexpected error occurred.',
    int? statusCode,
    String? errorCode,
    bool? retryable,
    List<String> details = const [],
  }) : super(
         message,
         statusCode: statusCode,
         errorCode: errorCode,
         retryable: retryable,
         details: details,
       );
}
