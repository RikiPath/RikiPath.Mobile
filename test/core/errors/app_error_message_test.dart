import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

void main() {
  final l10n = AppLocalizationsVi();

  test('network error uses localized copy instead of transport text', () {
    final message = appErrorMessage(
      const NetworkError(message: 'SocketException: host lookup failed'),
      l10n,
    );

    expect(message, l10n.commonErrorNetwork);
    expect(message, isNot(contains('SocketException')));
  });

  test('authorization statuses keep distinct user-facing messages', () {
    expect(
      appErrorMessage(const UnauthorizedError(), l10n),
      l10n.commonErrorUnauthorized,
    );
    expect(
      appErrorMessage(const ForbiddenError(), l10n),
      l10n.commonErrorForbidden,
    );
  });

  test('resource and conflict errors remain distinct', () {
    expect(
      appErrorMessage(const NotFoundError(), l10n),
      l10n.commonErrorNotFound,
    );
    expect(
      appErrorMessage(const ConflictError(), l10n),
      l10n.commonErrorConflict,
    );
  });

  test('validation and server errors use stable localized copy', () {
    expect(
      appErrorMessage(
        const ValidationError(message: 'raw backend validation'),
        l10n,
      ),
      l10n.commonErrorValidation,
    );
    expect(
      appErrorMessage(
        const ServerError(message: 'raw server body', statusCode: 500),
        l10n,
      ),
      l10n.commonErrorServer,
    );
  });

  test('unknown technical exception uses the supplied feature fallback', () {
    final message = appErrorMessage(
      FormatException('raw malformed response'),
      l10n,
      fallback: 'Không thể tải nội dung.',
    );

    expect(message, 'Không thể tải nội dung.');
    expect(message, isNot(contains('FormatException')));
    expect(message, isNot(contains('raw malformed response')));
  });

  group('Task 05 backend error codes', () {
    const offline =
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và thử lại.';

    test('raw DioException connection/timeout errors map to offline copy', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        final message = appErrorMessage(
          DioException(
            requestOptions: RequestOptions(path: '/api/study-courses/cohorts'),
            type: type,
            error: 'SocketException: Failed host lookup',
          ),
          l10n,
        );
        expect(message, offline, reason: type.name);
        expect(message, isNot(contains('SocketException')));
      }
      // The mapped NetworkError uses the same copy.
      expect(appErrorMessage(const NetworkError(), l10n), offline);
    });

    test('DioException with an envelope body maps through the error code', () {
      final requestOptions = RequestOptions(path: '/api/x');
      final message = appErrorMessage(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: requestOptions,
            statusCode: 409,
            data: <String, Object?>{
              'isSuccess': false,
              'statusCode': 409,
              'errorCode': 'COHORT_ALREADY_ENROLLED',
              'errorMessage': 'Duplicate enrollment row',
            },
          ),
        ),
        l10n,
      );
      expect(message, 'Bạn đã ghi danh lớp này.');
    });

    test('MENTOR_SCHEDULE_CONFLICT shows the ready server sentence', () {
      const ready =
          'Bạn đã có lịch dạy lớp JLPT N5-A từ 19:00 đến 20:30 vào thứ 4 '
          '(20/11/2026). Vui lòng chọn khung giờ khác.';
      expect(
        appErrorMessage(
          const ConflictError(
            message: ready,
            errorCode: 'MENTOR_SCHEDULE_CONFLICT',
          ),
          l10n,
        ),
        ready,
      );
      // Non-user-facing server text falls back to stable Vietnamese copy.
      final fallback = appErrorMessage(
        const ConflictError(errorCode: 'MENTOR_SCHEDULE_CONFLICT'),
        l10n,
      );
      expect(fallback, contains('trùng với lịch dạy'));
      expect(fallback, isNot(contains('conflicts')));
    });

    test('COHORT_FULL maps to the Vietnamese capacity message', () {
      expect(
        appErrorMessage(
          const ConflictError(
            message: 'Cohort capacity exceeded',
            errorCode: 'COHORT_FULL',
          ),
          l10n,
        ),
        'Lớp đã đủ 4 học viên. Vui lòng chọn lớp khác.',
      );
    });

    test('500 INTERNAL_ERROR never leaks technical text', () {
      final message = appErrorMessage(
        const ServerError(
          message: 'System.NullReferenceException at Foo.Bar()',
          statusCode: 500,
          errorCode: 'INTERNAL_ERROR',
        ),
        l10n,
      );
      expect(message, l10n.commonErrorServer);
      expect(message, isNot(contains('Exception')));
    });

    test('other contract codes use Vietnamese copy', () {
      expect(
        appErrorMessage(
          const ConflictError(errorCode: 'COHORT_CANCELLATION_NOT_ALLOWED'),
          l10n,
        ),
        contains('không thể tự hủy'),
      );
      expect(
        appErrorMessage(
          const ValidationError(
            statusCode: 422,
            errorCode: 'TRANSFER_SOURCE_STARTED',
          ),
          l10n,
        ),
        contains('không thể chuyển lớp'),
      );
      expect(
        appErrorMessage(
          const ServerError(statusCode: 504, errorCode: 'UPSTREAM_TIMEOUT'),
          l10n,
        ),
        contains('thử lại sau'),
      );
    });
  });
}
