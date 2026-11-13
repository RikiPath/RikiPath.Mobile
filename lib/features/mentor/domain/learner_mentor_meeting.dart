import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

@immutable
class BookableMentor {
  const BookableMentor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.headline,
    this.bio,
    this.jlptLevels = const [],
    this.teachingMethod,
  });

  final int id;
  final String name;
  final String? avatarUrl;
  final String? headline;
  final String? bio;
  final List<String> jlptLevels;
  final String? teachingMethod;

  List<String> get teachingJlptLevels => jlptLevels;
}

@immutable
class MentorMeetingFeature {
  const MentorMeetingFeature({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
}

@immutable
class MentorMeetingPlan {
  const MentorMeetingPlan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.meetingSessionCount,
    required this.features,
    this.description,
    this.jlptLevel,
    this.certificateLevelId,
  });

  final int id;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final int meetingSessionCount;
  final List<MentorMeetingFeature> features;
  final String? jlptLevel;
  final int? certificateLevelId;
}

@immutable
class LearnerMentorAvailability {
  const LearnerMentorAvailability({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  final int id;
  final int mentorId;
  final String mentorName;
  final MentorTimestamp startTime;
  final MentorTimestamp endTime;
  final bool isBooked;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mentorId': mentorId,
    'mentorName': mentorName,
    'startTime': startTime.rawValue,
    'endTime': endTime.rawValue,
    'isBooked': isBooked,
  };

  factory LearnerMentorAvailability.fromJson(Map<String, dynamic> json) =>
      LearnerMentorAvailability(
        id: json['id'] as int,
        mentorId: json['mentorId'] as int,
        mentorName: json['mentorName'] as String,
        startTime: MentorTimestamp.parse(json['startTime'] as String),
        endTime: MentorTimestamp.parse(json['endTime'] as String),
        isBooked: json['isBooked'] as bool? ?? false,
      );
}

enum MentorPaymentStatus {
  pending('Pending'),
  paid('Paid'),
  failed('Failed'),
  refunded('Refunded'),
  unknown('Unknown');

  const MentorPaymentStatus(this.apiValue);

  final String apiValue;

  static MentorPaymentStatus fromApiValue(String value) {
    return values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => unknown,
    );
  }
}

@immutable
class LearnerMentorBooking {
  const LearnerMentorBooking({
    required this.id,
    required this.userSubscriptionId,
    required this.status,
    this.mentorAvailabilityId,
    this.mentorId,
    this.mentorName,
    this.learnerId,
    this.learnerName,
    this.paymentStatus,
    this.scheduledAt,
    this.endsAt,
    this.meetingLink,
    this.roomId,
    this.jlptLevel,
  });

  final int id;
  final int userSubscriptionId;
  final int? mentorAvailabilityId;
  final int? mentorId;
  final String? mentorName;
  final int? learnerId;
  final String? learnerName;
  final MentorMeetingStatus status;
  final MentorPaymentStatus? paymentStatus;
  final MentorTimestamp? scheduledAt;
  final MentorTimestamp? endsAt;
  final String? meetingLink;
  final String? roomId;
  final String? jlptLevel;

  Uri? get safeMeetingUri => safeExternalHttpUri(meetingLink);
}

@immutable
class MentorMeetingPurchase {
  const MentorMeetingPurchase({
    required this.subscriptionId,
    this.bookingId,
    required this.orderCode,
    required this.planName,
    required this.meetingSessionCount,
    required this.features,
    required this.amount,
    required this.checkoutUrl,
    required this.paymentLinkId,
    required this.qrCode,
    this.paymentExpiresAt,
    this.isQaSimulated = false,
  });

  final int subscriptionId;
  final int? bookingId;
  final int orderCode;
  final String planName;
  final int meetingSessionCount;
  final List<MentorMeetingFeature> features;
  final double amount;
  final String checkoutUrl;
  final String paymentLinkId;
  final String qrCode;
  final MentorTimestamp? paymentExpiresAt;
  final bool isQaSimulated;

  Uri? get safeCheckoutUri => safeExternalHttpUri(checkoutUrl);
}

@immutable
class MentorMeetingPurchaseStatus {
  const MentorMeetingPurchaseStatus({
    required this.subscriptionId,
    required this.planName,
    required this.paymentStatus,
    required this.isCheckoutExpired,
    required this.amountPaid,
    required this.meetingSessionsIncluded,
    required this.meetingSessionsUsed,
    required this.bookings,
    this.paymentExpiresAt,
    this.isQaSimulated = false,
  });

  final int subscriptionId;
  final String planName;
  final MentorPaymentStatus paymentStatus;
  final bool isCheckoutExpired;
  final double amountPaid;
  final MentorTimestamp? paymentExpiresAt;
  final bool isQaSimulated;
  final int meetingSessionsIncluded;
  final int meetingSessionsUsed;
  final List<LearnerMentorBooking> bookings;

  int get remainingSessions {
    final remaining = meetingSessionsIncluded - meetingSessionsUsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isSettled => paymentStatus != MentorPaymentStatus.pending;
}

Uri? safeExternalHttpUri(String? rawValue) {
  return parseSafeExternalHttpUri(rawValue);
}

@immutable
class LearnerCreditGrant {
  const LearnerCreditGrant({
    required this.grantId,
    required this.userSubscriptionId,
    this.certificateLevelId,
    this.jlptLevel,
    required this.availableQuantity,
    this.expiresAtUtc,
  });

  final int grantId;
  final int userSubscriptionId;
  final int? certificateLevelId;
  final String? jlptLevel;
  final int availableQuantity;
  final DateTime? expiresAtUtc;
}

@immutable
class LearnerCreditBalance {
  const LearnerCreditBalance({
    required this.balance,
    required this.availableBalance,
    required this.pendingHoldCount,
    this.expiresAtUtc,
    this.activeGrants = const [],
  });

  final int balance;
  final int availableBalance;
  final int pendingHoldCount;
  final DateTime? expiresAtUtc;
  final List<LearnerCreditGrant> activeGrants;

  bool get hasCredits => availableBalance > 0;

  int availableForLevel(String? level) {
    if (level == null || level.trim().isEmpty) return availableBalance;
    final normalized = normalizeConsultationJlptLevel(level);
    return activeGrants
        .where((g) => normalizeConsultationJlptLevel(g.jlptLevel) == normalized)
        .fold<int>(0, (sum, g) => sum + g.availableQuantity);
  }
}

@immutable
class CancellationEligibility {
  const CancellationEligibility({
    required this.isEligible,
    required this.tier,
    required this.expectedRefundPercent,
    required this.refundAmountCredits,
    required this.canReschedule,
    required this.cutoffHours,
    this.message,
  });

  final bool isEligible;
  final String tier;
  final int expectedRefundPercent;
  final int refundAmountCredits;
  final bool canReschedule;
  final int cutoffHours;
  final String? message;

  bool get isFullRefund => expectedRefundPercent >= 100;
}

@immutable
class MentorRatingSummary {
  const MentorRatingSummary({
    required this.mentorId,
    required this.averageRating,
    required this.totalReviews,
    required this.starCounts,
    required this.positiveRatePercentage,
  });

  final int mentorId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starCounts;
  final double positiveRatePercentage;
}

@immutable
class MentorReviewItem {
  const MentorReviewItem({
    required this.id,
    required this.bookingId,
    required this.learnerName,
    required this.rating,
    this.comment,
    this.createdAtUtc,
    this.mentorReply,
    this.mentorRepliedAtUtc,
  });

  final int id;
  final int bookingId;
  final String learnerName;
  final int rating;
  final String? comment;
  final DateTime? createdAtUtc;
  final String? mentorReply;
  final DateTime? mentorRepliedAtUtc;
}

@immutable
class LearnerDisputeItem {
  const LearnerDisputeItem({
    required this.id,
    required this.bookingId,
    required this.category,
    required this.status,
    required this.description,
    this.resolutionNote,
    this.refundApproved,
    this.createdAtUtc,
  });

  final int id;
  final int bookingId;
  final int category;
  final int status;
  final String description;
  final String? resolutionNote;
  final bool? refundApproved;
  final DateTime? createdAtUtc;

  String get categoryLabel => switch (category) {
    1 => 'Mentor vắng mặt',
    2 => 'Buổi tư vấn không diễn ra',
    3 => 'Sự cố phòng họp trực tuyến',
    4 => 'Chất lượng không đạt yêu cầu',
    5 => 'Hành vi không phù hợp',
    6 => 'Tranh chấp chính sách',
    _ => 'Lý do khác',
  };

  String get statusLabel => switch (status) {
    1 => 'Đã gửi khiếu nại',
    2 => 'Đang xem xét',
    3 => 'Chờ Mentor giải trình',
    4 => 'Đã giải quyết',
    5 => 'Bị từ chối',
    6 => 'Đã đóng',
    _ => 'Không xác định',
  };
}
