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
  'HOMEWORK_AI_DRAFT_UNAVAILABLE',
  'HOMEWORK_SUBMISSION_CHANGED',
  'HOMEWORK_ALREADY_GRADED',
  'HOMEWORK_CLOSED',
  'HOMEWORK_EXERCISES_INCOMPLETE',
  'AI_CREDIT_REQUIRED',
  'SELF_STUDY_PACKAGE_REQUIRED',
  'WRITING_PACKAGE_REQUIRED',
  'ENROLLMENT_CUTOFF_PASSED',
  'RESERVATION_EXPIRED',
  'LATE_PAYMENT_AFTER_CANCEL_OR_FAILURE',
  'COHORT_ENTITLEMENT_INVALID',
  'COHORT_PLAN_CHANGED',
  'COHORT_SCHEDULE_PENDING',
  'TRANSFER_TARGET_FULL',
  'TRANSFER_SCHEDULE_CONFLICT',
  'TRANSFER_REQUEST_ALREADY_PENDING',
  'TRANSFER_TARGET_STARTED',
  'TRANSFER_TARGET_CUTOFF',
  'TRANSFER_LEVEL_MISMATCH',
  'TRANSFER_CURRICULUM_MISMATCH',
  'TRANSFER_RETAKE_UNSUPPORTED',
  'TRANSFER_DISABLED_BY_POLICY',
  'TRANSFER_EVIDENCE_INVALID',
  'COMPLAINT_REFUND_REVIEW_NOT_ALLOWED',
  'COMPLAINT_ALREADY_DECIDED',
  'COMPLAINT_EVIDENCE_INVALID',
  'COMPLAINT_MENTOR_RESPONSE_NOT_ALLOWED',
  'COMPLAINT_STALE',
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
  'COHORT_ENTITLEMENT_INVALID':
      'Mã quyền học lớp nhóm không hợp lệ hoặc đã hết hạn.',
  'COHORT_PLAN_CHANGED':
      'Thông tin gói học của lớp vừa được cập nhật. Vui lòng tải lại.',
  'COHORT_SCHEDULE_PENDING':
      'Lớp đang điều chỉnh lịch học nên tạm chưa nhận ghi danh.',
  'ENROLLMENT_CUTOFF_PASSED':
      'Đã quá thời hạn đăng ký vào lớp này.',
  'RESERVATION_EXPIRED':
      'Thời gian giữ chỗ thanh toán đã hết hạn. Vui lòng đăng ký lại.',
  'LATE_PAYMENT_AFTER_CANCEL_OR_FAILURE':
      'Giao dịch hoàn tất sau khi giữ chỗ đã hết hạn; vui lòng liên hệ hỗ trợ hoặc gửi khiếu nại.',
  'PAYMENT_GATEWAY_INVALID_LINK':
      'Cổng thanh toán chưa tạo được liên kết hợp lệ. Vui lòng thử lại sau.',
  'COHORT_CANCELLATION_NOT_ALLOWED':
      'Khóa học đã bắt đầu nên không thể tự hủy ghi danh.',
  'TRANSFER_SOURCE_STARTED':
      'Khóa học đã bắt đầu nên không thể chuyển lớp.',
  'TRANSFER_TARGET_FULL': 'Lớp đích đã đủ sĩ số.',
  'TRANSFER_SCHEDULE_CONFLICT':
      'Lịch học của lớp đích trùng với lịch học khác của bạn.',
  'TRANSFER_REQUEST_ALREADY_PENDING':
      'Bạn đang có một yêu cầu chuyển lớp chờ duyệt.',
  // Homework (PR #70 + Cohort).
  'HOMEWORK_AI_DRAFT_UNAVAILABLE':
      'Chưa tạo được gợi ý chấm bằng AI. Mentor có thể xem bài nộp và chấm trực tiếp.',
  'HOMEWORK_SUBMISSION_CHANGED':
      'Học viên vừa nộp phiên bản mới. Vui lòng tải lại trước khi công bố điểm.',
  'HOMEWORK_ALREADY_GRADED':
      'Bài tập này đã được chấm điểm nên không thể nộp lại.',
  'HOMEWORK_CLOSED': 'Bài tập đã đóng hoặc không còn mở nộp.',
  'HOMEWORK_EXERCISES_INCOMPLETE':
      'Vui lòng hoàn thành các bài luyện tập đính kèm trước khi nộp.',
  // AI / Subscriptions gates.
  'AI_CREDIT_REQUIRED':
      'Bạn chưa có lượt AI cho tính năng này. Vào Mua gói để mua thêm lượt.',
  'SELF_STUDY_PACKAGE_REQUIRED':
      'Bạn cần kích hoạt gói tự học để sử dụng nội dung này.',
  'WRITING_PACKAGE_REQUIRED':
      'Bạn cần gói luyện viết AI để chấm bài viết.',
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
  // Cohort reviews & complaints.
  'COHORT_REVIEW_NOT_ELIGIBLE':
      'Bạn chỉ có thể đánh giá Mentor đã dạy bạn ít nhất một buổi.',
  'COHORT_REVIEW_DUPLICATE':
      'Bạn đã đánh giá Mentor này. Bạn có thể chỉnh sửa đánh giá hiện có.',
  'COHORT_REVIEW_COMMENT_TOO_LONG':
      'Nội dung nhận xét vượt quá giới hạn ký tự cho phép.',
  'COMPLAINT_REFUND_REVIEW_NOT_ALLOWED':
      'Không thể gửi yêu cầu xem xét hoàn tiền cho trạng thái đơn hiện tại.',
  'COMPLAINT_ALREADY_DECIDED': 'Khiếu nại này đã có quyết định từ Admin.',
  'COMPLAINT_EVIDENCE_INVALID':
      'Tệp minh chứng không hợp lệ (hỗ trợ PDF/PNG/JPG ≤10MB).',
  'COMPLAINT_MENTOR_RESPONSE_NOT_ALLOWED':
      'Bạn không thể phản hồi khiếu nại này.',
  'COMPLAINT_STALE':
      'Khiếu nại vừa được cập nhật. Vui lòng tải lại trang.',
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
