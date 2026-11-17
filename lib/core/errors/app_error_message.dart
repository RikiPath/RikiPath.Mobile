import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

/// Converts technical/data-layer failures into stable localized copy.
///
/// Backend messages and exception strings deliberately stay out of the
/// presentation layer. The only exception is the small set of business codes
/// whose `errorMessage` the backend guarantees to be a ready-to-show
/// Vietnamese sentence (schedule conflicts, full cohorts); those are shown
/// verbatim only when they actually look like user-facing copy.
///
/// A feature-specific [fallback] can retain useful context for failures that
/// do not belong to the shared API error hierarchy.
String appErrorMessage(
  Object error,
  AppLocalizations l10n, {
  String? fallback,
}) {
  if (error is DioException) {
    if (_isConnectivityFailure(error)) return l10n.commonErrorNetwork;
    return appErrorMessage(
      const ApiErrorMapper().fromDioException(error),
      l10n,
      fallback: fallback,
    );
  }

  if (error is ApiError) {
    final known = backendErrorCodeMessage(
      error.errorCode,
      l10n,
      serverMessage: error.message,
    );
    if (known != null) return known;
  }

  return switch (error) {
    NetworkError() => l10n.commonErrorNetwork,
    UnauthorizedError() => l10n.commonErrorUnauthorized,
    ForbiddenError() => l10n.commonErrorForbidden,
    NotFoundError() => l10n.commonErrorNotFound,
    ConflictError() => l10n.commonErrorConflict,
    ValidationError() => l10n.commonErrorValidation,
    ServerError() => l10n.commonErrorServer,
    UnknownError() => fallback ?? l10n.commonErrorUnknown,
    _ => fallback ?? l10n.commonErrorUnknown,
  };
}

bool _isConnectivityFailure(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.unknown => error.response == null,
    _ => false,
  };
}

/// Codes whose backend `errorMessage` is a ready Vietnamese sentence that
/// carries specifics (cohort name, time range, capacity) worth showing as-is.
const Set<String> _serverMessageCodes = {
  'MENTOR_SCHEDULE_CONFLICT',
  'MENTOR_REST_INTERVAL_VIOLATION',
  'MENTOR_DAILY_LIMIT_EXCEEDED',
  'MENTOR_WEEKLY_LIMIT_EXCEEDED',
  'COHORT_SESSION_DUPLICATE',
  'COHORT_SCHEDULE_CONFLICT',
  'COHORT_FULL',
};

const Map<String, String> _codeMessages = {
  // Mentor schedule rules (Task 05).
  'MENTOR_SCHEDULE_CONFLICT':
      'Khung giờ này trùng với lịch dạy hiện có. Vui lòng chọn khung giờ khác.',
  'MENTOR_REST_INTERVAL_VIOLATION':
      'Khoảng nghỉ giữa hai buổi dạy chưa đủ. Vui lòng chọn khung giờ khác.',
  'MENTOR_DAILY_LIMIT_EXCEEDED':
      'Đã vượt giới hạn số buổi dạy trong ngày. Vui lòng chọn ngày khác.',
  'MENTOR_WEEKLY_LIMIT_EXCEEDED':
      'Đã vượt giới hạn số buổi dạy trong tuần. Vui lòng chọn tuần khác.',
  'COHORT_SESSION_DUPLICATE':
      'Lịch lớp có buổi học bị trùng thời gian. Vui lòng kiểm tra lại.',
  // Cohort scheduling / plan configuration.
  'COHORT_SCHEDULE_REVISION_CONFLICT':
      'Lịch lớp vừa được cập nhật. Vui lòng tải lại và thử lại.',
  'COHORT_SCHEDULE_ALREADY_PUBLISHED':
      'Lịch lớp đã được công bố nên không thể chỉnh sửa trực tiếp.',
  'COHORT_SCHEDULE_INCOMPLETE':
      'Lịch lớp chưa đủ số buổi theo kế hoạch khóa học.',
  'COURSE_PLAN_INVALID_CAPACITY': 'Sĩ số lớp không hợp lệ.',
  'COURSE_PLAN_INVALID_INTENSITY': 'Cường độ học không hợp lệ.',
  'COURSE_PLAN_INVALID_DURATION': 'Thời lượng khóa học không hợp lệ.',
  // Checkout / enrollment.
  'COHORT_FULL': 'Lớp đã đủ 4 học viên. Vui lòng chọn lớp khác.',
  'COHORT_ENROLLMENT_CLOSED':
      'Lớp đã hết hạn ghi danh. Vui lòng chọn lớp khác.',
  'COHORT_ALREADY_ENROLLED': 'Bạn đã ghi danh lớp này.',
  'COHORT_SCHEDULE_CONFLICT':
      'Lịch lớp trùng với lịch học khác của bạn. Vui lòng chọn lớp khác.',
  'PAYMENT_GATEWAY_INVALID_LINK':
      'Cổng thanh toán chưa tạo được liên kết hợp lệ. Vui lòng thử lại sau.',
  'COHORT_CANCELLATION_NOT_ALLOWED':
      'Khóa học đã bắt đầu nên không thể tự hủy ghi danh.',
  'TRANSFER_SOURCE_STARTED':
      'Khóa học đã bắt đầu nên không thể chuyển lớp.',
  // Cohort schedule requests.
  'COHORT_SCHEDULE_REQUEST_PENDING':
      'Lớp đang có một yêu cầu dời lịch/hủy lớp chờ xử lý.',
  'COHORT_HAS_CONFIRMED_LEARNERS':
      'Lớp đã có học viên xác nhận ghi danh nên không thể hủy.',
  'COHORT_PAYMENT_PENDING':
      'Lớp đang có giao dịch chờ thanh toán. Vui lòng thử lại sau.',
  'COHORT_PAYMENT_REVIEW_OPEN':
      'Lớp đang có giao dịch chờ Admin xem xét.',
  'COHORT_ALREADY_STARTED': 'Lớp đã bắt đầu nên không thể thay đổi lịch.',
  'COHORT_SCHEDULE_REQUEST_REASON_REQUIRED':
      'Vui lòng nhập lý do cho yêu cầu.',
  // Cohort reviews.
  'COHORT_REVIEW_NOT_ELIGIBLE':
      'Bạn chỉ có thể đánh giá Mentor đã dạy bạn ít nhất một buổi.',
  'COHORT_REVIEW_DUPLICATE':
      'Bạn đã đánh giá Mentor này. Bạn có thể chỉnh sửa đánh giá hiện có.',
  // Platform-wide.
  'CONCURRENCY_CONFLICT':
      'Dữ liệu vừa được cập nhật. Vui lòng tải lại và thử lại.',
  'DUPLICATE_REQUEST': 'Yêu cầu này đã được gửi trước đó.',
  'UPSTREAM_TIMEOUT': 'Hệ thống phản hồi quá lâu. Vui lòng thử lại sau.',
};

/// Maps a backend `errorCode` to user-facing copy, or `null` when the code is
/// unknown so callers can fall back to the status-based message.
String? backendErrorCodeMessage(
  String? errorCode,
  AppLocalizations l10n, {
  String? serverMessage,
}) {
  if (errorCode == null || errorCode.isEmpty) return null;
  final code = errorCode.toUpperCase();
  if (code == 'INTERNAL_ERROR') return l10n.commonErrorServer;
  if (_serverMessageCodes.contains(code) &&
      isReadyUserFacingMessage(serverMessage)) {
    return serverMessage!.trim();
  }
  return _codeMessages[code];
}

final RegExp _vietnameseLetters = RegExp(
  '[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
  caseSensitive: false,
);
final RegExp _technicalMarkers = RegExp(
  r'(exception|stack ?trace|\bat [\w.]+\(|sql|null reference|traceid|\{|\})',
  caseSensitive: false,
);

/// True when a backend message is a short Vietnamese sentence rather than
/// technical text (exception names, stack traces, English defaults).
bool isReadyUserFacingMessage(String? message) {
  final text = message?.trim();
  if (text == null || text.isEmpty || text.length > 400) return false;
  if (_technicalMarkers.hasMatch(text)) return false;
  return _vietnameseLetters.hasMatch(text);
}
