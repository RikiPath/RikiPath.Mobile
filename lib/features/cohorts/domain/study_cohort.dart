import 'package:flutter/foundation.dart';

@immutable
class CohortSessionSlot {
  const CohortSessionSlot({
    required this.number,
    required this.availabilityId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    this.status = '',
  });

  final int number;
  final int availabilityId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;

  /// Optional session status reported by the backend (e.g. Scheduled,
  /// Completed, Cancelled). Empty when the row does not carry one.
  final String status;
}

/// One weekly slot of a cohort's fixed schedule, already in local time.
@immutable
class CohortSchedulePatternItem {
  const CohortSchedulePatternItem({
    required this.weekday,
    required this.weekdayLabel,
    required this.localStart,
    required this.localEnd,
  });

  /// 0 = Sunday … 6 = Saturday (backend convention).
  final int weekday;
  final String weekdayLabel;
  final String localStart;
  final String localEnd;

  String get display => '$weekdayLabel $localStart–$localEnd';
}

@immutable
class StudyCohortSummary {
  const StudyCohortSummary({
    required this.id,
    required this.planId,
    required this.name,
    required this.mentorId,
    required this.mentorName,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.enrolledCount,
    required this.seatsAvailable,
    required this.status,
    required this.level,
    required this.totalSessions,
    required this.sessionMinutes,
    required this.price,
    required this.enrollmentClosesAtUtc,
    required this.requiresEntitlement,
    required this.hasApprovedEntitlement,
    required this.entitlementReference,
    required this.entitlementStatusMessage,
    required this.myEnrollmentCourseId,
    required this.myEnrollmentStatus,
    required this.enrollmentOpen,
    required this.sessions,
    this.checkoutMode = 'PayOS',
    this.myEnrollmentPaymentState,
    this.intensity = '',
    this.intensityLabel = '',
    this.isRecommendedIntensity = false,
    this.totalTeachingHours,
    this.sessionsPerWeek,
    this.schedulePattern = const [],
  });

  /// "Light" | "Standard" | "Advanced" | "Custom" (empty for legacy rows).
  final String intensity;

  /// Ready-to-show label: "Nhẹ" | "Tiêu chuẩn" | "Nâng cao" | "Tùy chỉnh".
  final String intensityLabel;
  final bool isRecommendedIntensity;
  final num? totalTeachingHours;
  final int? sessionsPerWeek;
  final List<CohortSchedulePatternItem> schedulePattern;

  final String checkoutMode;
  final String? myEnrollmentPaymentState;
  final int id;
  final int planId;
  final String name;
  final int mentorId;
  final String mentorName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int enrolledCount;
  final int seatsAvailable;
  final String status;
  final String level;
  final int? totalSessions;
  final int? sessionMinutes;
  final num price;
  final DateTime enrollmentClosesAtUtc;
  final bool requiresEntitlement;
  final bool hasApprovedEntitlement;
  final String? entitlementReference;
  final String? entitlementStatusMessage;
  final int? myEnrollmentCourseId;
  final String? myEnrollmentStatus;
  final bool enrollmentOpen;
  final List<CohortSessionSlot> sessions;
}

@immutable
class CohortCheckoutResult {
  const CohortCheckoutResult({
    required this.courseId,
    required this.cohortId,
    this.checkoutUrl,
    required this.paymentStatus,
    required this.status,
    this.resumed = false,
  });

  final int courseId;
  final int cohortId;
  final String? checkoutUrl;
  final String paymentStatus;
  final String status;
  final bool resumed;

  bool get isEnrolled => paymentStatus == 'Paid' && status == 'Active';

  bool get requiresPayment =>
      paymentStatus == 'Pending' &&
      (checkoutUrl?.startsWith('https://') ?? false);
}

@immutable
class CohortEntitlementItem {
  const CohortEntitlementItem({
    required this.id,
    required this.studyCohortId,
    required this.cohortName,
    required this.level,
    required this.startsAt,
    required this.entitlementReference,
    required this.sourceType,
    required this.status,
    required this.isUsable,
    this.note,
    this.grantedAtUtc,
    this.expiresAtUtc,
  });

  final int id;
  final int studyCohortId;
  final String cohortName;
  final String level;
  final DateTime startsAt;
  final String entitlementReference;
  final String sourceType;
  final String status;
  final bool isUsable;
  final String? note;
  final DateTime? grantedAtUtc;
  final DateTime? expiresAtUtc;
}

@immutable
class CourseSessionItem {
  const CourseSessionItem({
    required this.id,
    required this.number,
    required this.attempt,
    required this.scheduledAt,
    required this.status,
    this.note,
    this.meetingUrl,
    this.confirmedAt,
  });

  final int id;
  final int number;
  final int attempt;
  final DateTime scheduledAt;
  final String status;
  final String? note;
  final String? meetingUrl;
  final DateTime? confirmedAt;

  String? get roomId {
    final url = meetingUrl;
    if (url == null || url.isEmpty) return null;
    final match = RegExp(r'/meeting-room/([^/?#]+)').firstMatch(url);
    if (match != null) return match.group(1);
    return null;
  }
}

@immutable
class CourseEligibilitySummary {
  const CourseEligibilitySummary({
    required this.canClaim,
    required this.passedOnTimeHomework,
    required this.requiredHomework,
    required this.absentSessions,
    required this.countedSessions,
    required this.reasons,
  });

  final bool canClaim;
  final int passedOnTimeHomework;
  final int requiredHomework;
  final int absentSessions;
  final int countedSessions;
  final List<String> reasons;
}

@immutable
class CourseRetakeRequestItem {
  const CourseRetakeRequestItem({
    required this.id,
    required this.status,
    required this.examDate,
    required this.resultPublishedAt,
    required this.reason,
    required this.submittedAt,
    this.reviewedAt,
    this.response,
    this.mentorSupportPlan,
    this.mentorSupportPlanAtUtc,
  });

  final int id;
  final String status;
  final DateTime examDate;
  final DateTime resultPublishedAt;
  final String reason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? response;
  final String? mentorSupportPlan;
  final DateTime? mentorSupportPlanAtUtc;
}

@immutable
class LearnerStudyCourseDetail {
  const LearnerStudyCourseDetail({
    required this.id,
    required this.name,
    required this.planId,
    required this.cohortId,
    required this.sessionType,
    required this.level,
    required this.mentorId,
    required this.mentorName,
    required this.durationMonths,
    required this.sessionsPerWeek,
    required this.totalSessions,
    required this.sessionMinutes,
    required this.amount,
    required this.paymentStatus,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.completedAt,
    required this.eligibility,
    required this.sessions,
    required this.requests,
    this.paymentState = '',
    this.checkoutUrl,
    this.paymentExpiresAt,
    this.paymentConfirmedAtUtc,
  });

  final String paymentState;
  final String? checkoutUrl;
  final DateTime? paymentExpiresAt;
  final DateTime? paymentConfirmedAtUtc;

  bool get isAwaitingPayment => paymentState == 'AwaitingPayment';

  final int id;
  final String name;
  final int planId;
  final int? cohortId;
  final String sessionType;
  final String level;
  final int? mentorId;
  final String mentorName;
  final int durationMonths;
  final int sessionsPerWeek;
  final int totalSessions;
  final int sessionMinutes;
  final num amount;
  final String paymentStatus;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? completedAt;
  final CourseEligibilitySummary eligibility;
  final List<CourseSessionItem> sessions;
  final List<CourseRetakeRequestItem> requests;
}

@immutable
class CohortHomeworkSubmission {
  const CohortHomeworkSubmission({
    required this.id,
    required this.textContent,
    required this.submittedAt,
    required this.revisionCount,
    this.lastRevisedAtUtc,
    this.hasScan = false,
  });

  final int id;
  final String? textContent;
  final DateTime submittedAt;
  final int revisionCount;
  final DateTime? lastRevisedAtUtc;
  final bool hasScan;
}

@immutable
class CohortHomeworkPublishedGrade {
  const CohortHomeworkPublishedGrade({
    required this.passed,
    this.score,
    required this.feedback,
    required this.publishedAtUtc,
  });

  final bool? passed;
  final double? score;
  final String feedback;
  final DateTime publishedAtUtc;
}

@immutable
class CohortHomeworkAssignment {
  const CohortHomeworkAssignment({
    required this.id,
    required this.title,
    this.instructions,
    this.assignedAt,
    this.dueAt,
    required this.status,
    required this.assignmentScope,
    this.cohortId,
    this.submission,
    this.publishedGrade,
  });

  final int id;
  final String title;
  final String? instructions;
  final DateTime? assignedAt;
  final DateTime? dueAt;
  final String status;
  final String assignmentScope;
  final int? cohortId;
  final CohortHomeworkSubmission? submission;
  final CohortHomeworkPublishedGrade? publishedGrade;

  bool get isCommon => assignmentScope == 'CohortCommon';
}

/// Một bước trong lịch sử (append-only) của yêu cầu chuyển lớp.
class CohortTransferHistoryItem {
  const CohortTransferHistoryItem({
    required this.action,
    required this.actorRole,
    required this.detail,
    required this.atUtc,
  });

  final String action;
  final String actorRole;
  final String detail;
  final DateTime atUtc;
}

/// Yêu cầu chuyển lớp của Học viên. Học viên không tự đổi lớp/Mentor;
/// chỉ Admin duyệt mới cập nhật ghi danh.
class CohortTransferRequestItem {
  const CohortTransferRequestItem({
    required this.id,
    required this.status,
    required this.sourceCourseId,
    required this.sourceCohortId,
    required this.sourceCohortName,
    required this.requestedTargetCohortId,
    required this.requestedTargetCohortName,
    required this.targetCohortId,
    required this.targetCohortName,
    required this.reason,
    required this.hasEvidence,
    required this.createdAtUtc,
    required this.reviewedAtUtc,
    required this.decisionNote,
    required this.destinationCourseId,
    required this.history,
  });

  final int id;
  final String status;
  final int sourceCourseId;
  final int sourceCohortId;
  final String? sourceCohortName;
  final int? requestedTargetCohortId;
  final String? requestedTargetCohortName;
  final int? targetCohortId;
  final String? targetCohortName;
  final String reason;
  final bool hasEvidence;
  final DateTime createdAtUtc;
  final DateTime? reviewedAtUtc;
  final String? decisionNote;
  final int? destinationCourseId;
  final List<CohortTransferHistoryItem> history;

  bool get isPending => status == 'Pending';

  String get statusLabel => switch (status) {
    'Pending' => 'Chờ Admin xem xét',
    'Approved' => 'Đã duyệt chuyển lớp',
    'Rejected' => 'Bị từ chối',
    'Withdrawn' => 'Đã rút yêu cầu',
    _ => status,
  };
}
