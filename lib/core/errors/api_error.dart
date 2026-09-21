sealed class ApiError implements Exception {
  const ApiError(this.message, {this.statusCode, this.details = const []});

  final String message;
  final int? statusCode;
  final List<String> details;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkError extends ApiError {
  const NetworkError({
    String message = 'Unable to reach the server. Please try again.',
  }) : super(message);
}

final class UnauthorizedError extends ApiError {
  const UnauthorizedError({
    String message = 'Authentication is required or has expired.',
    List<String> details = const [],
  }) : super(message, statusCode: 401, details: details);
}

final class ForbiddenError extends ApiError {
  const ForbiddenError({
    String message = 'You do not have permission to perform this action.',
    List<String> details = const [],
  }) : super(message, statusCode: 403, details: details);
}

final class NotFoundError extends ApiError {
  const NotFoundError({
    String message = 'The requested resource was not found.',
    List<String> details = const [],
  }) : super(message, statusCode: 404, details: details);
}

final class ValidationError extends ApiError {
  const ValidationError({
    String message = 'The request contains invalid data.',
    int statusCode = 400,
    List<String> details = const [],
  }) : super(message, statusCode: statusCode, details: details);
}

final class ServerError extends ApiError {
  const ServerError({
    String message = 'The server could not complete the request.',
    required int statusCode,
    List<String> details = const [],
  }) : super(message, statusCode: statusCode, details: details);
}

final class UnknownError extends ApiError {
  const UnknownError({
    String message = 'An unexpected error occurred.',
    int? statusCode,
    List<String> details = const [],
  }) : super(message, statusCode: statusCode, details: details);
}
