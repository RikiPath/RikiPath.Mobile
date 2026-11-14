import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';

class MentorBookingDetailDto {
  MentorBookingDetailDto._();

  static MentorBookingDetail fromJson(Map<String, Object?> json) {
    return MentorBookingDetail(
      id: readRequiredPositiveInt(json, 'id'),
      userSubscriptionId: readIntOrZero(json, 'userSubscriptionId'),
      creditGrantId: readOptionalInt(json, 'creditGrantId'),
      mentorAvailabilityId: readOptionalInt(json, 'mentorAvailabilityId'),
      mentorId: readOptionalInt(json, 'mentorId'),
      mentorName: readOptionalString(json, 'mentorName'),
      learnerId: readOptionalInt(json, 'learnerId'),
      learnerName: readOptionalString(json, 'learnerName'),
      compensationLevelId:
          readOptionalInt(json, 'compensationLevelId') ??
          readOptionalInt(json, 'certificateLevelId'),
      jlptLevel: readOptionalString(json, 'jlptLevel'),
      status: MentorMeetingStatus.fromApiValue(
        json['status']?.toString() ?? 'PendingAssignment',
      ),
      paymentStatus: json['paymentStatus']?.toString(),
      scheduledAt: readOptionalTimestamp(json, 'scheduledAt'),
      endsAt: readOptionalTimestamp(json, 'endsAt'),
      createdAt: readOptionalTimestamp(json, 'createdAt'),
      meetingLink: readOptionalString(json, 'meetingLink'),
      roomId: json['roomId']?.toString(),
      question: readOptionalString(json, 'question'),
    );
  }
}

class MentorCancellationEligibilityDto {
  MentorCancellationEligibilityDto._();

  static MentorCancellationEligibility fromJson(Map<String, Object?> json) {
    return MentorCancellationEligibility(
      bookingId: readIntOrZero(json, 'bookingId'),
      canCancel: readBoolOrFalse(json, 'canCancel'),
      canReschedule: readBoolOrFalse(json, 'canReschedule'),
      eligibleForFullRefund: readBoolOrFalse(json, 'eligibleForFullRefund'),
      hoursUntilStart: readDoubleOrZero(json, 'hoursUntilStart'),
      tier: readStringOrEmpty(json, 'tier'),
      message: readStringOrEmpty(json, 'message'),
    );
  }
}

class MentorAttendanceRecordDto {
  MentorAttendanceRecordDto._();

  static MentorAttendanceRecord fromJson(Map<String, Object?> json) {
    return MentorAttendanceRecord(
      id: readIntOrZero(json, 'id'),
      mentorBookingId: readIntOrZero(json, 'mentorBookingId'),
      roomId: json['roomId']?.toString() ?? '',
      userId: readIntOrZero(json, 'userId'),
      participantName: readStringOrEmpty(json, 'participantName'),
      role: readStringOrEmpty(json, 'role'),
      status: MentorAttendanceStatus.fromApiValue(json['status']),
      firstJoinedAtUtc: readOptionalTimestamp(json, 'firstJoinedAtUtc'),
      lastJoinedAtUtc: readOptionalTimestamp(json, 'lastJoinedAtUtc'),
      lastSeenAtUtc: readOptionalTimestamp(json, 'lastSeenAtUtc'),
      leftAtUtc: readOptionalTimestamp(json, 'leftAtUtc'),
      reconnectionCount: readIntOrZero(json, 'reconnectionCount'),
      totalDurationSeconds: readIntOrZero(json, 'totalDurationSeconds'),
      isOnline: readBoolOrFalse(json, 'isOnline'),
    );
  }
}

class MentorRoomAccessStatusDto {
  MentorRoomAccessStatusDto._();

  static MentorRoomAccessStatus fromJson(Map<String, Object?> json) {
    return MentorRoomAccessStatus(
      roomId: json['roomId']?.toString() ?? '',
      canAccess: readBoolOrFalse(json, 'canAccess'),
      isRoomReady: readBoolOrFalse(json, 'isRoomReady'),
      reason: readOptionalString(json, 'reason'),
    );
  }
}

class MentorReviewDto {
  MentorReviewDto._();

  static MentorReviewItem fromJson(Map<String, Object?> json) {
    return MentorReviewItem(
      id: readRequiredPositiveInt(json, 'id'),
      mentorBookingId: readIntOrZero(json, 'mentorBookingId'),
      mentorId: readIntOrZero(json, 'mentorId'),
      mentorName: readStringOrEmpty(json, 'mentorName'),
      learnerId: readIntOrZero(json, 'learnerId'),
      learnerName: readStringOrEmpty(json, 'learnerName'),
      rating: readIntOrZero(json, 'rating'),
      comment: readOptionalString(json, 'comment'),
      isPublic: readBoolOrFalse(json, 'isPublic'),
      moderationStatus: MentorReviewModerationStatus.fromApiValue(
        json['moderationStatus'],
      ),
      mentorReply: readOptionalString(json, 'mentorReply'),
      mentorRepliedAtUtc: readOptionalTimestamp(json, 'mentorRepliedAtUtc'),
      createdAtUtc: readRequiredTimestamp(json, 'createdAtUtc'),
      updatedAtUtc:
          readOptionalTimestamp(json, 'updatedAtUtc') ??
          readRequiredTimestamp(json, 'createdAtUtc'),
    );
  }
}

class MentorRatingSummaryDto {
  MentorRatingSummaryDto._();

  static MentorRatingSummary fromJson(Map<String, Object?> json) {
    final rawBreakdown = readMapOrEmpty(json['ratingBreakdown']);
    final breakdown = <int, int>{};
    for (final entry in rawBreakdown.entries) {
      final star = int.tryParse(entry.key.trim());
      final count = switch (entry.value) {
        int v => v,
        num v => v.toInt(),
        String s => int.tryParse(s.trim()),
        _ => null,
      };
      if (star != null && count != null) {
        breakdown[star] = count;
      }
    }
    return MentorRatingSummary(
      mentorId: readIntOrZero(json, 'mentorId'),
      totalReviews: readIntOrZero(json, 'totalReviews'),
      averageRating: readDoubleOrZero(json, 'averageRating'),
      ratingBreakdown: breakdown,
      positiveRatePercent: readDoubleOrZero(json, 'positiveRatePercent'),
    );
  }
}

class MentorDisputeDto {
  MentorDisputeDto._();

  static MentorDisputeItem fromJson(Map<String, Object?> json) {
    final created = readRequiredTimestamp(json, 'createdAtUtc');
    return MentorDisputeItem(
      id: readRequiredPositiveInt(json, 'id'),
      mentorBookingId: readIntOrZero(json, 'mentorBookingId'),
      learnerId: readIntOrZero(json, 'learnerId'),
      learnerName: readStringOrEmpty(json, 'learnerName'),
      mentorId: readIntOrZero(json, 'mentorId'),
      mentorName: readStringOrEmpty(json, 'mentorName'),
      category: MentorDisputeCategory.fromApiValue(json['category']),
      status: MentorDisputeStatus.fromApiValue(json['status']),
      reason: readStringOrEmpty(json, 'reason'),
      evidenceUrls: readOptionalString(json, 'evidenceUrls'),
      mentorResponse: readOptionalString(json, 'mentorResponse'),
      mentorRespondedAtUtc: readOptionalTimestamp(json, 'mentorRespondedAtUtc'),
      adminNotes: readOptionalString(json, 'adminNotes'),
      adminDecision: readOptionalString(json, 'adminDecision'),
      isRefundApproved: readOptionalBool(json, 'isRefundApproved'),
      creditRefunded: readBoolOrFalse(json, 'creditRefunded'),
      resolvedAtUtc: readOptionalTimestamp(json, 'resolvedAtUtc'),
      createdAtUtc: created,
      updatedAtUtc: readOptionalTimestamp(json, 'updatedAtUtc') ?? created,
    );
  }
}

class MentorDisputeDetailDto {
  MentorDisputeDetailDto._();

  static MentorDisputeDetail fromJson(Map<String, Object?> json) {
    final disputeMap = readMapOrEmpty(json['dispute']);
    final rawHistories = json['histories'];
    final histories = <MentorDisputeHistoryEntry>[];
    if (rawHistories is List<Object?>) {
      for (final raw in rawHistories) {
        final item = readMapOrEmpty(raw);
        if (item.isEmpty) continue;
        histories.add(
          MentorDisputeHistoryEntry(
            id: readIntOrZero(item, 'id'),
            action: readStringOrEmpty(item, 'action'),
            previousStatus: item['previousStatus'] == null
                ? null
                : MentorDisputeStatus.fromApiValue(item['previousStatus']),
            newStatus: MentorDisputeStatus.fromApiValue(item['newStatus']),
            actorId: readIntOrZero(item, 'actorId'),
            actorRole: readStringOrEmpty(item, 'actorRole'),
            notes: readOptionalString(item, 'notes'),
            createdAtUtc: readRequiredTimestamp(item, 'createdAtUtc'),
          ),
        );
      }
    }

    return MentorDisputeDetail(
      dispute: MentorDisputeDto.fromJson(disputeMap),
      bookingScheduledAt: readOptionalTimestamp(json, 'bookingScheduledAt'),
      bookingStatus: MentorMeetingStatus.fromApiValue(
        json['bookingStatus']?.toString() ?? 'PendingAssignment',
      ),
      attendanceFirstJoinedAtUtc: readOptionalTimestamp(
        json,
        'attendanceFirstJoinedAtUtc',
      ),
      attendanceLastJoinedAtUtc: readOptionalTimestamp(
        json,
        'attendanceLastJoinedAtUtc',
      ),
      attendanceTotalDurationSeconds: readIntOrZero(
        json,
        'attendanceTotalDurationSeconds',
      ),
      attendanceReconnectionCount: readIntOrZero(
        json,
        'attendanceReconnectionCount',
      ),
      isCancelled: readBoolOrFalse(json, 'isCancelled'),
      cancellationReason: readOptionalString(json, 'cancellationReason'),
      cancelledByRole: readOptionalString(json, 'cancelledByRole'),
      creditAlreadyRefunded: readBoolOrFalse(json, 'creditAlreadyRefunded'),
      histories: histories,
    );
  }
}
