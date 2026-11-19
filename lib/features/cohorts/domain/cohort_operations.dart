import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

/// Server-side discovery filters for GET /api/study-courses/cohorts.
@immutable
class CohortDiscoveryFilter {
  const CohortDiscoveryFilter({
    this.mentorId,
    this.level,
    this.intensity,
    this.weekday,
    this.fromTime,
    this.toTime,
  });

  final int? mentorId;
  final String? level;
  final String? intensity;

  /// 0 = Sunday … 6 = Saturday.
  final int? weekday;

  /// "HH:mm".
  final String? fromTime;

  /// "HH:mm".
  final String? toTime;

  bool get isEmpty =>
      mentorId == null &&
      level == null &&
      intensity == null &&
      weekday == null &&
      fromTime == null &&
      toTime == null;

  CohortDiscoveryFilter copyWith({
    ValueGetter<int?>? mentorId,
    ValueGetter<String?>? level,
    ValueGetter<String?>? intensity,
    ValueGetter<int?>? weekday,
    ValueGetter<String?>? fromTime,
    ValueGetter<String?>? toTime,
  }) {
    return CohortDiscoveryFilter(
      mentorId: mentorId != null ? mentorId() : this.mentorId,
      level: level != null ? level() : this.level,
      intensity: intensity != null ? intensity() : this.intensity,
      weekday: weekday != null ? weekday() : this.weekday,
      fromTime: fromTime != null ? fromTime() : this.fromTime,
      toTime: toTime != null ? toTime() : this.toTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CohortDiscoveryFilter &&
      other.mentorId == mentorId &&
      other.level == level &&
      other.intensity == intensity &&
      other.weekday == weekday &&
      other.fromTime == fromTime &&
      other.toTime == toTime;

  @override
  int get hashCode =>
      Object.hash(mentorId, level, intensity, weekday, fromTime, toTime);
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

@immutable
class CohortReviewComment {
  const CohortReviewComment({
    required this.rating,
    required this.comment,
    required this.createdAtUtc,
  });

  final int rating;
  final String comment;
  final DateTime? createdAtUtc;
}

@immutable
class MentorCohortReviewSummary {
  const MentorCohortReviewSummary({
    required this.mentorId,
    required this.averageRating,
    required this.reviewCount,
    this.comments = const [],
  });

  final int mentorId;
  final double averageRating;
  final int reviewCount;
  final List<CohortReviewComment> comments;

  bool get hasReviews => reviewCount > 0;
}

@immutable
class CohortMentorReview {
  const CohortMentorReview({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.rating,
    required this.comment,
    this.createdAtUtc,
    this.updatedAtUtc,
  });

  final int id;
  final int mentorId;
  final String mentorName;
  final int rating;
  final String comment;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;
}

// ---------------------------------------------------------------------------
// Complaints
// ---------------------------------------------------------------------------

abstract final class CohortComplaintCategory {
  static const String teachingQuality = 'TeachingQuality';
  static const String mentorConduct = 'MentorConduct';
  static const String schedule = 'Schedule';
  static const String paymentEnrollment = 'PaymentEnrollment';
  static const String other = 'Other';

  static const List<String> all = [
    teachingQuality,
    mentorConduct,
    schedule,
    paymentEnrollment,
    other,
  ];

  static String label(String category) => switch (category) {
    teachingQuality => 'Chất lượng giảng dạy',
    mentorConduct => 'Thái độ Mentor',
    schedule => 'Lịch học',
    paymentEnrollment => 'Thanh toán / ghi danh',
    other => 'Khác',
    _ => category,
  };
}

@immutable
class CohortComplaint {
  const CohortComplaint({
    required this.id,
    required this.courseId,
    required this.cohortId,
    required this.cohortName,
    required this.mentorId,
    required this.mentorName,
    required this.category,
    required this.message,
    required this.status,
    required this.refundReviewRequested,
    required this.hasEvidence,
    required this.mentorResponse,
    required this.decision,
    required this.createdAtUtc,
    required this.decidedAtUtc,
    required this.revision,
    this.history = const [],
  });

  final int id;
  final int courseId;
  final int? cohortId;
  final String? cohortName;
  final int? mentorId;
  final String? mentorName;
  final String category;
  final String message;
  final String status;
  final bool refundReviewRequested;
  final bool hasEvidence;
  final String? mentorResponse;
  final String? decision;
  final DateTime? createdAtUtc;
  final DateTime? decidedAtUtc;
  final int revision;
  final List<CohortTransferHistoryItem> history;

  bool get isTerminal => status == 'Resolved' || status == 'Rejected';

  bool get hasMentorResponse => (mentorResponse ?? '').trim().isNotEmpty;

  /// Mentors never answer payment/enrollment complaints; Admin owns those.
  bool get mentorCanRespond =>
      category != CohortComplaintCategory.paymentEnrollment &&
      !isTerminal &&
      !hasMentorResponse;

  String get statusLabel => switch (status) {
    'Open' => 'Đã tiếp nhận',
    'UnderReview' => 'Đang xem xét',
    'Resolved' => 'Đã xử lý',
    'Rejected' => 'Không chấp nhận',
    _ => status,
  };

  String get categoryLabel => CohortComplaintCategory.label(category);
}

// ---------------------------------------------------------------------------
// Completion summary
// ---------------------------------------------------------------------------

@immutable
class CompletionMentorItem {
  const CompletionMentorItem({
    required this.mentorId,
    required this.mentorName,
    required this.sessionNumbers,
    required this.isPrimary,
  });

  final int mentorId;
  final String mentorName;
  final List<int> sessionNumbers;
  final bool isPrimary;
}

@immutable
class CompletionSessionCounts {
  const CompletionSessionCounts({
    this.total = 0,
    this.delivered = 0,
    this.absent = 0,
    this.cancelled = 0,
    this.upcoming = 0,
  });

  final int total;
  final int delivered;
  final int absent;
  final int cancelled;
  final int upcoming;
}

@immutable
class CompletionAttendanceItem {
  const CompletionAttendanceItem({
    required this.number,
    required this.scheduledAt,
    required this.status,
  });

  final int number;
  final DateTime? scheduledAt;
  final String status;

  static const Set<String> _notDelivered = {
    '',
    'Upcoming',
    'Scheduled',
    'Pending',
    'Cancelled',
  };

  bool get isDelivered => !_notDelivered.contains(status);
}

@immutable
class CompletionHomeworkCounts {
  const CompletionHomeworkCounts({
    this.assigned = 0,
    this.submitted = 0,
    this.graded = 0,
    this.outstanding = 0,
  });

  final int assigned;
  final int submitted;
  final int graded;
  final int outstanding;
}

@immutable
class CompletionFeedbackItem {
  const CompletionFeedbackItem({
    required this.title,
    required this.feedback,
    required this.score,
    required this.publishedAtUtc,
  });

  final String title;
  final String feedback;
  final double? score;
  final DateTime? publishedAtUtc;
}

@immutable
class CohortCompletionSummary {
  const CohortCompletionSummary({
    required this.courseId,
    required this.cohortId,
    required this.cohortName,
    required this.level,
    required this.intensity,
    required this.intensityLabel,
    required this.isCompleted,
    required this.mentors,
    required this.sessions,
    required this.attendance,
    required this.homework,
    required this.mentorFeedback,
    required this.skillProgressAvailable,
    required this.note,
    this.skillProgress,
  });

  final int courseId;
  final int? cohortId;
  final String cohortName;
  final String level;
  final String intensity;
  final String intensityLabel;
  final bool isCompleted;
  final List<CompletionMentorItem> mentors;
  final CompletionSessionCounts sessions;
  final List<CompletionAttendanceItem> attendance;
  final CompletionHomeworkCounts homework;
  final List<CompletionFeedbackItem> mentorFeedback;
  final bool skillProgressAvailable;
  final Object? skillProgress;
  final String note;

  /// Mentors who actually taught at least one delivered session to this
  /// learner — the only ones the backend accepts reviews for.
  List<CompletionMentorItem> get reviewableMentors {
    final delivered = {
      for (final a in attendance)
        if (a.isDelivered) a.number,
    };
    return mentors
        .where((m) => m.sessionNumbers.any(delivered.contains))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Schedule conflicts / requests (Mentor)
// ---------------------------------------------------------------------------

@immutable
class ScheduleConflictItem {
  const ScheduleConflictItem({
    required this.code,
    required this.message,
    this.sessionNumber,
    this.proposedStartUtc,
    this.proposedEndUtc,
    this.commitmentKind,
    this.cohortId,
    this.cohortName,
    this.commitmentStartUtc,
    this.commitmentEndUtc,
  });

  final String code;
  final int? sessionNumber;
  final DateTime? proposedStartUtc;
  final DateTime? proposedEndUtc;
  final String? commitmentKind;
  final int? cohortId;
  final String? cohortName;
  final DateTime? commitmentStartUtc;
  final DateTime? commitmentEndUtc;

  /// Ready-to-show Vietnamese copy from the backend.
  final String message;
}

@immutable
class ShiftPreviewCheck {
  const ShiftPreviewCheck({
    required this.code,
    required this.passed,
    required this.message,
  });

  final String code;
  final bool passed;
  final String message;
}

@immutable
class ShiftPreviewSession {
  const ShiftPreviewSession({
    required this.number,
    required this.startTime,
    required this.endTime,
    this.currentStart,
    this.currentEnd,
  });

  final int number;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? currentStart;
  final DateTime? currentEnd;
}

@immutable
class CohortShiftPreview {
  const CohortShiftPreview({
    required this.eligible,
    this.checks = const [],
    this.blockers = const [],
    this.proposedSessions = const [],
    this.conflicts = const [],
    this.newEnrollmentClosesAtUtc,
  });

  final bool eligible;
  final List<ShiftPreviewCheck> checks;
  final List<String> blockers;
  final List<ShiftPreviewSession> proposedSessions;
  final List<ScheduleConflictItem> conflicts;
  final DateTime? newEnrollmentClosesAtUtc;
}

abstract final class CohortScheduleRequestKind {
  static const String shiftWeeks = 'ShiftWeeks';
  static const String cancelEmptyCohort = 'CancelEmptyCohort';

  static String label(String kind) => switch (kind) {
    shiftWeeks => 'Dời lịch khai giảng',
    cancelEmptyCohort => 'Hủy lớp chưa có học viên',
    _ => kind,
  };
}

@immutable
class CohortScheduleRequest {
  const CohortScheduleRequest({
    required this.id,
    required this.cohortId,
    required this.cohortName,
    required this.kind,
    required this.shiftWeeks,
    required this.reason,
    required this.status,
    required this.requestedByRole,
    required this.createdAtUtc,
    required this.reviewedAtUtc,
    required this.decisionNote,
    required this.revision,
    this.history = const [],
  });

  final int id;
  final int cohortId;
  final String cohortName;
  final String kind;
  final int? shiftWeeks;
  final String reason;
  final String status;
  final String requestedByRole;
  final DateTime? createdAtUtc;
  final DateTime? reviewedAtUtc;
  final String? decisionNote;
  final int revision;
  final List<CohortTransferHistoryItem> history;

  bool get isPending => status == 'Pending';

  String get kindLabel => kind == CohortScheduleRequestKind.shiftWeeks &&
          shiftWeeks != null
      ? 'Dời lịch $shiftWeeks tuần'
      : CohortScheduleRequestKind.label(kind);

  String get statusLabel => switch (status) {
    'Pending' => 'Chờ Admin duyệt',
    'Approved' => 'Đã duyệt',
    'Rejected' => 'Bị từ chối',
    'Withdrawn' => 'Đã rút yêu cầu',
    _ => status,
  };
}

// ---------------------------------------------------------------------------
// Mentor cohort operations
// ---------------------------------------------------------------------------

/// A learner enrolled in a cohort, as seen by the Mentor. Only the display
/// name is exposed — no contact or payment details.
@immutable
class MentorCohortRosterEntry {
  const MentorCohortRosterEntry({
    required this.courseId,
    required this.learnerId,
    required this.learnerName,
    required this.status,
    this.sessions = const [],
    this.retakeRequests = const [],
  });

  final int courseId;
  final int? learnerId;
  final String learnerName;
  final String status;
  final List<CourseSessionItem> sessions;
  final List<CourseRetakeRequestItem> retakeRequests;
}

@immutable
class MentorHomeworkAiDraft {
  const MentorHomeworkAiDraft({
    this.suggestedScore,
    this.feedback,
    this.generatedAtUtc,
    this.unavailableReason,
    this.transcription,
  });

  final double? suggestedScore;
  final String? feedback;
  final DateTime? generatedAtUtc;
  final String? unavailableReason;
  final String? transcription;
}

@immutable
class MentorCohortHomeworkRow {
  const MentorCohortHomeworkRow({
    required this.id,
    required this.title,
    this.instructions,
    required this.learnerId,
    required this.learnerName,
    required this.status,
    required this.assignmentScope,
    this.cohortAssignmentGroupKey,
    this.assignedAt,
    this.dueAt,
    this.submission,
    this.aiDraft,
    this.publishedGrade,
    this.lessonTitles = const [],
    this.exerciseTitles = const [],
  });

  final int id;
  final String title;
  final String? instructions;
  final int? learnerId;
  final String learnerName;
  final String status;
  final String assignmentScope;
  final String? cohortAssignmentGroupKey;
  final DateTime? assignedAt;
  final DateTime? dueAt;
  final CohortHomeworkSubmission? submission;
  final MentorHomeworkAiDraft? aiDraft;
  final CohortHomeworkPublishedGrade? publishedGrade;
  final List<String> lessonTitles;
  final List<String> exerciseTitles;
}

@immutable
class HomeworkCatalogItem {
  const HomeworkCatalogItem({
    required this.type,
    required this.id,
    required this.title,
    this.level = '',
    this.skill = '',
    this.questionCount,
  });

  /// 'Lesson' | 'PracticeExercise'
  final String type;
  final int id;
  final String title;
  final String level;
  final String skill;
  final int? questionCount;
}

@immutable
class CohortBinaryAttachment {
  const CohortBinaryAttachment({
    required this.bytes,
    required this.contentType,
  });

  final List<int> bytes;
  final String contentType;
}

@immutable
class MentorLearnerSkillMetric {
  const MentorLearnerSkillMetric({
    required this.skill,
    this.averageScorePercent,
    this.sampleCount = 0,
    this.latestAssessedAtUtc,
    this.dataSource,
  });

  final String skill;
  final double? averageScorePercent;
  final int sampleCount;
  final DateTime? latestAssessedAtUtc;
  final String? dataSource;
}

@immutable
class MentorLearnerSkillProfile {
  const MentorLearnerSkillProfile({
    required this.learnerId,
    required this.learnerName,
    this.cohortId,
    this.assessedJlptLevel,
    this.skills = const [],
    this.assignedCount = 0,
    this.submittedCount = 0,
    this.onTimeCount = 0,
    this.passedCount = 0,
    this.onTimePercent,
    this.latestActivityAtUtc,
  });

  final int learnerId;
  final String learnerName;
  final int? cohortId;
  final String? assessedJlptLevel;
  final List<MentorLearnerSkillMetric> skills;
  final int assignedCount;
  final int submittedCount;
  final int onTimeCount;
  final int passedCount;
  final double? onTimePercent;
  final DateTime? latestActivityAtUtc;
}

@immutable
class MentorCohortHomeworkItem {
  const MentorCohortHomeworkItem({
    required this.id,
    required this.title,
    required this.status,
    required this.assignmentScope,
    this.cohortAssignmentGroupKey,
    this.instructions,
    this.dueAt,
    this.submittedCount,
    this.gradedCount,
    this.totalCount,
    this.rows = const [],
  });

  final int id;
  final String title;
  final String status;
  final String assignmentScope;
  final String? cohortAssignmentGroupKey;
  final String? instructions;
  final DateTime? dueAt;
  final int? submittedCount;
  final int? gradedCount;
  final int? totalCount;
  final List<MentorCohortHomeworkRow> rows;

  String get progressLabel {
    final parts = <String>[
      if (submittedCount != null)
        'Đã nộp ${submittedCount!}${totalCount != null ? '/${totalCount!}' : ''}',
      if (gradedCount != null) 'Đã chấm ${gradedCount!}',
    ];
    return parts.isEmpty ? status : parts.join(' · ');
  }
}

@immutable
class CohortMentorAssignment {
  const CohortMentorAssignment({
    required this.mentorId,
    required this.mentorName,
    required this.isPrimary,
    this.fromSessionNumber,
    this.assignedAtUtc,
    this.reason,
    this.previousMentorId,
    this.affectedSessionCount,
    this.effectiveFromUtc,
  });

  final int mentorId;
  final String mentorName;
  final bool isPrimary;
  final int? fromSessionNumber;
  final DateTime? assignedAtUtc;
  final String? reason;
  final int? previousMentorId;
  final int? affectedSessionCount;
  final DateTime? effectiveFromUtc;
}

/// A Mentor's assigned cohort with derived schedule helpers.
@immutable
class MentorCohortOverview {
  const MentorCohortOverview(this.cohort);

  final StudyCohortSummary cohort;

  int get sessionsPerWeek =>
      cohort.sessionsPerWeek ??
      (cohort.schedulePattern.isNotEmpty ? cohort.schedulePattern.length : 0);

  CohortSessionSlot? nextSession(DateTime now) {
    final upcoming = cohort.sessions
        .where((s) => s.endTime.isAfter(now) && s.status != 'Cancelled')
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.firstOrNull;
  }
}
