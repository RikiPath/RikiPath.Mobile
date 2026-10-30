import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

class PurchaseMentorPlanRequestDto {
  const PurchaseMentorPlanRequestDto({
    required this.subscriptionPlanId,
    this.mentorAvailabilityId,
    this.idempotencyKey,
  });

  final int subscriptionPlanId;
  final int? mentorAvailabilityId;
  final String? idempotencyKey;

  Map<String, Object?> toJson() => <String, Object?>{
    'subscriptionPlanId': subscriptionPlanId,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };
}

class BookIncludedMeetingRequestDto {
  const BookIncludedMeetingRequestDto({
    required this.mentorAvailabilityId,
    this.question,
  });

  final int mentorAvailabilityId;
  final String? question;

  Map<String, Object?> toJson() => <String, Object?>{
    'mentorAvailabilityId': mentorAvailabilityId,
    if (question != null && question!.trim().isNotEmpty)
      'question': question!.trim(),
  };
}

class BookableMentorDto {
  const BookableMentorDto({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory BookableMentorDto.fromJson(Map<String, Object?> json) {
    return BookableMentorDto(
      id: _requiredPositiveInt(json, 'id'),
      name: _requiredString(json, 'name'),
      avatarUrl: _optionalString(json, 'avatarUrl'),
    );
  }

  final int id;
  final String name;
  final String? avatarUrl;

  BookableMentor toDomain() => BookableMentor(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
      );
}

class MentorMeetingFeatureDto {
  const MentorMeetingFeatureDto({
    required this.id,
    required this.name,
    this.description,
  });

  factory MentorMeetingFeatureDto.fromJson(Map<String, Object?> json) {
    return MentorMeetingFeatureDto(
      id: _requiredPositiveInt(json, 'id'),
      name: _requiredString(json, 'name'),
      description: _optionalString(json, 'description'),
    );
  }

  final int id;
  final String name;
  final String? description;

  MentorMeetingFeature toDomain() =>
      MentorMeetingFeature(id: id, name: name, description: description);
}

class MentorMeetingPlanDto {
  const MentorMeetingPlanDto({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.meetingSessionCount,
    required this.features,
    this.description,
  });

  factory MentorMeetingPlanDto.fromJson(Map<String, Object?> json) {
    return MentorMeetingPlanDto(
      id: _requiredPositiveInt(json, 'id'),
      name: _requiredString(json, 'name'),
      description: _optionalString(json, 'description'),
      durationDays: _requiredNonNegativeInt(json, 'durationDays'),
      price: _requiredNumber(json, 'price'),
      meetingSessionCount: _requiredNonNegativeInt(json, 'meetingSessionCount'),
      features: _requiredObjectList(
        json,
        'features',
      ).map(MentorMeetingFeatureDto.fromJson).toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final int meetingSessionCount;
  final List<MentorMeetingFeatureDto> features;

  MentorMeetingPlan toDomain() => MentorMeetingPlan(
    id: id,
    name: name,
    description: description,
    durationDays: durationDays,
    price: price,
    meetingSessionCount: meetingSessionCount,
    features: features
        .map((feature) => feature.toDomain())
        .toList(growable: false),
  );
}

class LearnerMentorAvailabilityDto {
  const LearnerMentorAvailabilityDto({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  factory LearnerMentorAvailabilityDto.fromJson(Map<String, Object?> json) {
    return LearnerMentorAvailabilityDto(
      id: _requiredPositiveInt(json, 'id'),
      mentorId: _requiredPositiveInt(json, 'mentorId'),
      mentorName: _requiredString(json, 'mentorName'),
      startTime: MentorTimestamp.parse(_requiredString(json, 'startTime')),
      endTime: MentorTimestamp.parse(_requiredString(json, 'endTime')),
      isBooked: _requiredBool(json, 'isBooked'),
    );
  }

  final int id;
  final int mentorId;
  final String mentorName;
  final MentorTimestamp startTime;
  final MentorTimestamp endTime;
  final bool isBooked;

  LearnerMentorAvailability toDomain() => LearnerMentorAvailability(
    id: id,
    mentorId: mentorId,
    mentorName: mentorName,
    startTime: startTime,
    endTime: endTime,
    isBooked: isBooked,
  );
}

class LearnerMentorBookingDto {
  const LearnerMentorBookingDto({
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

  factory LearnerMentorBookingDto.fromJson(Map<String, Object?> json) {
    return LearnerMentorBookingDto(
      id: _requiredPositiveInt(json, 'id'),
      userSubscriptionId: _requiredPositiveInt(json, 'userSubscriptionId'),
      mentorAvailabilityId: _optionalPositiveInt(json, 'mentorAvailabilityId'),
      mentorId: _optionalPositiveInt(json, 'mentorId'),
      mentorName: _optionalString(json, 'mentorName'),
      learnerId: _optionalPositiveInt(json, 'learnerId'),
      learnerName: _optionalString(json, 'learnerName'),
      status: MentorMeetingStatus.fromApiValue(_requiredString(json, 'status')),
      paymentStatus: switch (_optionalString(json, 'paymentStatus')) {
        final value? => MentorPaymentStatus.fromApiValue(value),
        null => null,
      },
      scheduledAt: switch (_optionalString(json, 'scheduledAt')) {
        final value? => MentorTimestamp.parse(value),
        null => null,
      },
      meetingLink: _optionalString(json, 'meetingLink'),
      roomId: _optionalString(json, 'roomId'),
    );
  }

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

  LearnerMentorBooking toDomain() => LearnerMentorBooking(
    id: id,
    userSubscriptionId: userSubscriptionId,
    mentorAvailabilityId: mentorAvailabilityId,
    mentorId: mentorId,
    mentorName: mentorName,
    learnerId: learnerId,
    learnerName: learnerName,
    status: status,
    paymentStatus: paymentStatus,
    scheduledAt: scheduledAt,
    meetingLink: meetingLink,
    roomId: roomId,
  );
}

class MentorMeetingPurchaseDto {
  const MentorMeetingPurchaseDto({
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

  factory MentorMeetingPurchaseDto.fromJson(Map<String, Object?> json) {
    return MentorMeetingPurchaseDto(
      subscriptionId: _requiredPositiveInt(json, 'subscriptionId'),
      bookingId: _optionalPositiveInt(json, 'bookingId'),
      orderCode: _requiredPositiveInt(json, 'orderCode'),
      planName: _requiredString(json, 'planName'),
      meetingSessionCount: _requiredNonNegativeInt(json, 'meetingSessionCount'),
      features: _requiredObjectList(
        json,
        'features',
      ).map(MentorMeetingFeatureDto.fromJson).toList(growable: false),
      amount: _requiredNumber(json, 'amount'),
      checkoutUrl: _requiredString(json, 'checkoutUrl'),
      paymentLinkId: _requiredString(json, 'paymentLinkId'),
      qrCode: _requiredString(json, 'qrCode'),
      paymentExpiresAt: switch (_optionalString(json, 'paymentExpiresAt')) {
        final value? => MentorTimestamp.parse(value),
        null => null,
      },
      isQaSimulated: json['isQaSimulated'] == true,
    );
  }

  final int subscriptionId;
  final int? bookingId;
  final int orderCode;
  final String planName;
  final int meetingSessionCount;
  final List<MentorMeetingFeatureDto> features;
  final double amount;
  final String checkoutUrl;
  final String paymentLinkId;
  final String qrCode;
  final MentorTimestamp? paymentExpiresAt;
  final bool isQaSimulated;

  MentorMeetingPurchase toDomain() => MentorMeetingPurchase(
    subscriptionId: subscriptionId,
    bookingId: bookingId,
    orderCode: orderCode,
    planName: planName,
    meetingSessionCount: meetingSessionCount,
    features: features
        .map((feature) => feature.toDomain())
        .toList(growable: false),
    amount: amount,
    checkoutUrl: checkoutUrl,
    paymentLinkId: paymentLinkId,
    qrCode: qrCode,
    paymentExpiresAt: paymentExpiresAt,
    isQaSimulated: isQaSimulated,
  );
}

class MentorMeetingPurchaseStatusDto {
  const MentorMeetingPurchaseStatusDto({
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

  factory MentorMeetingPurchaseStatusDto.fromJson(Map<String, Object?> json) {
    return MentorMeetingPurchaseStatusDto(
      subscriptionId: _requiredPositiveInt(json, 'subscriptionId'),
      planName: _requiredString(json, 'planName'),
      paymentStatus: MentorPaymentStatus.fromApiValue(
        _requiredString(json, 'paymentStatus'),
      ),
      isCheckoutExpired: _requiredBool(json, 'isCheckoutExpired'),
      amountPaid: _requiredNumber(json, 'amountPaid'),
      paymentExpiresAt: switch (_optionalString(json, 'paymentExpiresAt')) {
        final value? => MentorTimestamp.parse(value),
        null => null,
      },
      meetingSessionsIncluded: _requiredNonNegativeInt(
        json,
        'meetingSessionsIncluded',
      ),
      meetingSessionsUsed: _requiredNonNegativeInt(json, 'meetingSessionsUsed'),
      bookings: _requiredObjectList(
        json,
        'bookings',
      ).map(LearnerMentorBookingDto.fromJson).toList(growable: false),
      isQaSimulated: json['isQaSimulated'] == true,
    );
  }

  final int subscriptionId;
  final String planName;
  final MentorPaymentStatus paymentStatus;
  final bool isCheckoutExpired;
  final double amountPaid;
  final MentorTimestamp? paymentExpiresAt;
  final int meetingSessionsIncluded;
  final int meetingSessionsUsed;
  final List<LearnerMentorBookingDto> bookings;
  final bool isQaSimulated;

  MentorMeetingPurchaseStatus toDomain() => MentorMeetingPurchaseStatus(
    subscriptionId: subscriptionId,
    planName: planName,
    paymentStatus: paymentStatus,
    isCheckoutExpired: isCheckoutExpired,
    amountPaid: amountPaid,
    paymentExpiresAt: paymentExpiresAt,
    meetingSessionsIncluded: meetingSessionsIncluded,
    meetingSessionsUsed: meetingSessionsUsed,
    bookings: bookings
        .map((booking) => booking.toDomain())
        .toList(growable: false),
    isQaSimulated: isQaSimulated,
  );
}

Map<String, Object?> readLearnerMentorResultObject(Object? body) {
  final envelope = _readEnvelope(body);
  final result = envelope['result'];
  if (result is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor Meeting result object.');
  }
  return result.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, Object?>> readLearnerMentorResultList(Object? body) {
  final envelope = _readEnvelope(body);
  final result = envelope['result'];
  if (result is! List<Object?>) {
    throw const FormatException('Expected a Mentor Meeting result list.');
  }
  return result
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw const FormatException('Expected a Mentor Meeting result item.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

Map<Object?, Object?> _readEnvelope(Object? body) {
  if (body is! Map<Object?, Object?> || body['isSuccess'] != true) {
    throw const FormatException('Expected a successful Mentor API envelope.');
  }
  return body;
}

List<Map<String, Object?>> _requiredObjectList(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw FormatException('Expected a list field: $key.');
  }
  return value
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw FormatException('Expected an object in field: $key.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

int _requiredPositiveInt(Map<String, Object?> json, String key) {
  final value = _readInt(json[key]);
  if (value == null || value <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, Object?> json, String key) {
  final value = _readInt(json[key]);
  if (value == null || value < 0) {
    throw FormatException('Expected a non-negative integer field: $key.');
  }
  return value;
}

int? _optionalPositiveInt(Map<String, Object?> json, String key) {
  final raw = json[key];
  if (raw == null) return null;
  final value = _readInt(raw);
  if (value == null || value <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return value;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

double _requiredNumber(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Expected a number field: $key.');
  }
  return value.toDouble();
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) throw FormatException('Expected a string field: $key.');
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Expected a string field: $key.');
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Expected a boolean field: $key.');
  return value;
}
