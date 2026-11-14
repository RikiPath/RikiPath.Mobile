import 'dart:convert';
import 'dart:typed_data';

import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

/// Full detail model returned by `GET /api/mentor-bookings/{bookingId}`.
class MentorBookingDetail {
  const MentorBookingDetail({
    required this.id,
    required this.userSubscriptionId,
    required this.status,
    this.creditGrantId,
    this.mentorAvailabilityId,
    this.mentorId,
    this.mentorName,
    this.learnerId,
    this.learnerName,
    this.compensationLevelId,
    this.jlptLevel,
    this.paymentStatus,
    this.scheduledAt,
    this.endsAt,
    this.createdAt,
    this.meetingLink,
    this.roomId,
    this.question,
  });

  final int id;
  final int userSubscriptionId;
  final int? creditGrantId;
  final int? mentorAvailabilityId;
  final int? mentorId;
  final String? mentorName;
  final int? learnerId;
  final String? learnerName;
  final int? compensationLevelId;
  final String? jlptLevel;
  final MentorMeetingStatus status;
  final String? paymentStatus;
  final MentorTimestamp? scheduledAt;
  final MentorTimestamp? endsAt;
  final MentorTimestamp? createdAt;
  final String? meetingLink;
  final String? roomId;
  final String? question;
}

/// Result of `GET /api/mentor-bookings/{bookingId}/cancellation-eligibility`.
class MentorCancellationEligibility {
  const MentorCancellationEligibility({
    required this.bookingId,
    required this.canCancel,
    required this.canReschedule,
    required this.eligibleForFullRefund,
    required this.hoursUntilStart,
    required this.tier,
    required this.message,
  });

  final int bookingId;
  final bool canCancel;
  final bool canReschedule;
  final bool eligibleForFullRefund;
  final double hoursUntilStart;
  final String tier;
  final String message;
}

enum MentorAttendanceStatus {
  notJoined,
  joined,
  temporarilyDisconnected,
  left,
  completed,
  unknown;

  static MentorAttendanceStatus fromApiValue(Object? raw) {
    if (raw is int) {
      return switch (raw) {
        0 => MentorAttendanceStatus.notJoined,
        1 => MentorAttendanceStatus.joined,
        2 => MentorAttendanceStatus.temporarilyDisconnected,
        3 => MentorAttendanceStatus.left,
        4 => MentorAttendanceStatus.completed,
        _ => MentorAttendanceStatus.unknown,
      };
    }
    final normalized = (raw?.toString() ?? '').trim().toLowerCase();
    return switch (normalized) {
      'notjoined' || 'not_joined' => MentorAttendanceStatus.notJoined,
      'joined' => MentorAttendanceStatus.joined,
      'temporarilydisconnected' ||
      'temporarily_disconnected' =>
        MentorAttendanceStatus.temporarilyDisconnected,
      'left' => MentorAttendanceStatus.left,
      'completed' => MentorAttendanceStatus.completed,
      _ => MentorAttendanceStatus.unknown,
    };
  }
}

/// Attendance telemetry from `GET /api/mentor-meetings/bookings/{bookingId}/attendance`.
class MentorAttendanceRecord {
  const MentorAttendanceRecord({
    required this.id,
    required this.mentorBookingId,
    required this.roomId,
    required this.userId,
    required this.participantName,
    required this.role,
    required this.status,
    required this.reconnectionCount,
    required this.totalDurationSeconds,
    required this.isOnline,
    this.firstJoinedAtUtc,
    this.lastJoinedAtUtc,
    this.lastSeenAtUtc,
    this.leftAtUtc,
  });

  final int id;
  final int mentorBookingId;
  final String roomId;
  final int userId;
  final String participantName;
  final String role;
  final MentorAttendanceStatus status;
  final MentorTimestamp? firstJoinedAtUtc;
  final MentorTimestamp? lastJoinedAtUtc;
  final MentorTimestamp? lastSeenAtUtc;
  final MentorTimestamp? leftAtUtc;
  final int reconnectionCount;
  final int totalDurationSeconds;
  final bool isOnline;
}

/// Readiness & access check from `GET /api/mentor-meetings/rooms/{roomId}/access`.
class MentorRoomAccessStatus {
  const MentorRoomAccessStatus({
    required this.roomId,
    required this.canAccess,
    required this.isRoomReady,
    this.reason,
  });

  final String roomId;
  final bool canAccess;
  final bool isRoomReady;
  final String? reason;
}

enum MentorReviewModerationStatus {
  pending,
  approved,
  hidden,
  rejected,
  unknown;

  static MentorReviewModerationStatus fromApiValue(Object? raw) {
    if (raw is int) {
      return switch (raw) {
        1 => MentorReviewModerationStatus.pending,
        2 => MentorReviewModerationStatus.approved,
        3 => MentorReviewModerationStatus.hidden,
        4 => MentorReviewModerationStatus.rejected,
        _ => MentorReviewModerationStatus.unknown,
      };
    }
    final normalized = (raw?.toString() ?? '').trim().toLowerCase();
    return switch (normalized) {
      'pending' => MentorReviewModerationStatus.pending,
      'approved' => MentorReviewModerationStatus.approved,
      'hidden' => MentorReviewModerationStatus.hidden,
      'rejected' => MentorReviewModerationStatus.rejected,
      _ => MentorReviewModerationStatus.unknown,
    };
  }
}

/// Learner review record from `GET /api/mentors/{mentorId}/reviews`.
class MentorReviewItem {
  const MentorReviewItem({
    required this.id,
    required this.mentorBookingId,
    required this.mentorId,
    required this.mentorName,
    required this.learnerId,
    required this.learnerName,
    required this.rating,
    required this.isPublic,
    required this.moderationStatus,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.comment,
    this.mentorReply,
    this.mentorRepliedAtUtc,
  });

  final int id;
  final int mentorBookingId;
  final int mentorId;
  final String mentorName;
  final int learnerId;
  final String learnerName;
  final int rating;
  final String? comment;
  final bool isPublic;
  final MentorReviewModerationStatus moderationStatus;
  final String? mentorReply;
  final MentorTimestamp? mentorRepliedAtUtc;
  final MentorTimestamp createdAtUtc;
  final MentorTimestamp updatedAtUtc;

  bool get hasReply => mentorReply != null && mentorReply!.trim().isNotEmpty;
}

/// Rating summary from `GET /api/mentors/{mentorId}/rating-summary`.
class MentorRatingSummary {
  const MentorRatingSummary({
    required this.mentorId,
    required this.totalReviews,
    required this.averageRating,
    required this.ratingBreakdown,
    required this.positiveRatePercent,
  });

  final int mentorId;
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingBreakdown;
  final double positiveRatePercent;
}

enum MentorDisputeCategory {
  mentorAbsent,
  sessionNotConducted,
  mediaRoomIssue,
  qualityIssue,
  inappropriateBehavior,
  policyDispute,
  other;

  static MentorDisputeCategory fromApiValue(Object? raw) {
    if (raw is int) {
      return switch (raw) {
        1 => MentorDisputeCategory.mentorAbsent,
        2 => MentorDisputeCategory.sessionNotConducted,
        3 => MentorDisputeCategory.mediaRoomIssue,
        4 => MentorDisputeCategory.qualityIssue,
        5 => MentorDisputeCategory.inappropriateBehavior,
        6 => MentorDisputeCategory.policyDispute,
        _ => MentorDisputeCategory.other,
      };
    }
    final normalized = (raw?.toString() ?? '').trim().toLowerCase();
    return switch (normalized) {
      'mentorabsent' || 'mentor_absent' => MentorDisputeCategory.mentorAbsent,
      'sessionnotconducted' ||
      'session_not_conducted' =>
        MentorDisputeCategory.sessionNotConducted,
      'mediaroomissue' ||
      'media_room_issue' =>
        MentorDisputeCategory.mediaRoomIssue,
      'qualityissue' || 'quality_issue' => MentorDisputeCategory.qualityIssue,
      'inappropriatebehavior' ||
      'inappropriate_behavior' =>
        MentorDisputeCategory.inappropriateBehavior,
      'policydispute' ||
      'policy_dispute' =>
        MentorDisputeCategory.policyDispute,
      _ => MentorDisputeCategory.other,
    };
  }
}

enum MentorDisputeStatus {
  submitted,
  underReview,
  awaitingResponse,
  resolved,
  rejected,
  closed;

  bool get isTerminal =>
      this == MentorDisputeStatus.resolved ||
      this == MentorDisputeStatus.rejected ||
      this == MentorDisputeStatus.closed;

  static MentorDisputeStatus fromApiValue(Object? raw) {
    if (raw is int) {
      return switch (raw) {
        1 => MentorDisputeStatus.submitted,
        2 => MentorDisputeStatus.underReview,
        3 => MentorDisputeStatus.awaitingResponse,
        4 => MentorDisputeStatus.resolved,
        5 => MentorDisputeStatus.rejected,
        6 => MentorDisputeStatus.closed,
        _ => MentorDisputeStatus.submitted,
      };
    }
    final normalized = (raw?.toString() ?? '').trim().toLowerCase();
    return switch (normalized) {
      'submitted' => MentorDisputeStatus.submitted,
      'underreview' || 'under_review' => MentorDisputeStatus.underReview,
      'awaitingresponse' ||
      'awaiting_response' =>
        MentorDisputeStatus.awaitingResponse,
      'resolved' => MentorDisputeStatus.resolved,
      'rejected' => MentorDisputeStatus.rejected,
      'closed' => MentorDisputeStatus.closed,
      _ => MentorDisputeStatus.submitted,
    };
  }
}

/// Dispute item from `GET /api/mentor/mentor-disputes`.
class MentorDisputeItem {
  const MentorDisputeItem({
    required this.id,
    required this.mentorBookingId,
    required this.learnerId,
    required this.learnerName,
    required this.mentorId,
    required this.mentorName,
    required this.category,
    required this.status,
    required this.reason,
    required this.creditRefunded,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.evidenceUrls,
    this.mentorResponse,
    this.mentorRespondedAtUtc,
    this.adminNotes,
    this.adminDecision,
    this.isRefundApproved,
    this.resolvedAtUtc,
  });

  final int id;
  final int mentorBookingId;
  final int learnerId;
  final String learnerName;
  final int mentorId;
  final String mentorName;
  final MentorDisputeCategory category;
  final MentorDisputeStatus status;
  final String reason;
  final String? evidenceUrls;
  final String? mentorResponse;
  final MentorTimestamp? mentorRespondedAtUtc;
  final String? adminNotes;
  final String? adminDecision;
  final bool? isRefundApproved;
  final bool creditRefunded;
  final MentorTimestamp? resolvedAtUtc;
  final MentorTimestamp createdAtUtc;
  final MentorTimestamp updatedAtUtc;

  bool get hasMentorResponded =>
      mentorResponse != null && mentorResponse!.trim().isNotEmpty;

  bool get canSubmitResponse => !hasMentorResponded && !status.isTerminal;

  List<String> get evidenceUrlList {
    final raw = evidenceUrls;
    if (raw == null || raw.trim().isEmpty) return const [];
    final trimmed = raw.trim();
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .whereType<Object?>()
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        }
      } on FormatException {
        // Fall through to delimiter splitting for malformed bracket strings.
      }
    }
    return trimmed
        .split(RegExp(r'[\r\n,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}

class MentorDisputeHistoryEntry {
  const MentorDisputeHistoryEntry({
    required this.id,
    required this.action,
    required this.newStatus,
    required this.actorId,
    required this.actorRole,
    required this.createdAtUtc,
    this.previousStatus,
    this.notes,
  });

  final int id;
  final String action;
  final MentorDisputeStatus? previousStatus;
  final MentorDisputeStatus newStatus;
  final int actorId;
  final String actorRole;
  final String? notes;
  final MentorTimestamp createdAtUtc;
}

/// Detail response from `GET /api/mentor-disputes/{disputeId}`.
class MentorDisputeDetail {
  const MentorDisputeDetail({
    required this.dispute,
    required this.bookingStatus,
    required this.attendanceTotalDurationSeconds,
    required this.attendanceReconnectionCount,
    required this.isCancelled,
    required this.creditAlreadyRefunded,
    required this.histories,
    this.bookingScheduledAt,
    this.attendanceFirstJoinedAtUtc,
    this.attendanceLastJoinedAtUtc,
    this.cancellationReason,
    this.cancelledByRole,
  });

  final MentorDisputeItem dispute;
  final MentorTimestamp? bookingScheduledAt;
  final MentorMeetingStatus bookingStatus;
  final MentorTimestamp? attendanceFirstJoinedAtUtc;
  final MentorTimestamp? attendanceLastJoinedAtUtc;
  final int attendanceTotalDurationSeconds;
  final int attendanceReconnectionCount;
  final bool isCancelled;
  final String? cancellationReason;
  final String? cancelledByRole;
  final bool creditAlreadyRefunded;
  final List<MentorDisputeHistoryEntry> histories;
}

/// Private verification certificate loaded either as bytes or signed URL.
class MentorVerificationDocumentData {
  const MentorVerificationDocumentData({
    this.signedUrl,
    this.bytes,
    this.contentType,
  });

  final String? signedUrl;
  final Uint8List? bytes;
  final String? contentType;

  bool get isImage =>
      contentType != null && contentType!.toLowerCase().startsWith('image/');

  bool get isPdf =>
      contentType != null && contentType!.toLowerCase().contains('pdf');
}
