import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

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
  });

  final int id;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final int meetingSessionCount;
  final List<MentorMeetingFeature> features;
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
    this.meetingLink,
    this.roomId,
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
  final String? meetingLink;
  final String? roomId;

  Uri? get safeMeetingUri => safeExternalHttpUri(meetingLink);
}

@immutable
class MentorMeetingPurchase {
  const MentorMeetingPurchase({
    required this.subscriptionId,
    required this.bookingId,
    required this.orderCode,
    required this.planName,
    required this.meetingSessionCount,
    required this.features,
    required this.amount,
    required this.checkoutUrl,
    required this.paymentLinkId,
    required this.qrCode,
    this.paymentExpiresAt,
  });

  final int subscriptionId;
  final int bookingId;
  final int orderCode;
  final String planName;
  final int meetingSessionCount;
  final List<MentorMeetingFeature> features;
  final double amount;
  final String checkoutUrl;
  final String paymentLinkId;
  final String qrCode;
  final MentorTimestamp? paymentExpiresAt;

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
  });

  final int subscriptionId;
  final String planName;
  final MentorPaymentStatus paymentStatus;
  final bool isCheckoutExpired;
  final double amountPaid;
  final MentorTimestamp? paymentExpiresAt;
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
