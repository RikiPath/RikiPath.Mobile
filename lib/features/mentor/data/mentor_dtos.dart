import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

class MentorAvailabilityDto {
  const MentorAvailabilityDto({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.isApproved = true,
    this.bookedCount = 0,
  });

  factory MentorAvailabilityDto.fromJson(Map<String, Object?> json) {
    return MentorAvailabilityDto(
      id: _requiredPositiveInt(json, 'id'),
      startTime: MentorTimestamp.parse(_requiredString(json, 'startTime')),
      endTime: MentorTimestamp.parse(_requiredString(json, 'endTime')),
      isBooked: _requiredBool(json, 'isBooked'),
      isApproved: json['isApproved'] as bool? ?? true,
      bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final MentorTimestamp startTime;
  final MentorTimestamp endTime;
  final bool isBooked;
  final bool isApproved;
  final int bookedCount;

  MentorAvailabilitySlot toDomain() => MentorAvailabilitySlot(
    id: id,
    startTime: startTime,
    endTime: endTime,
    isBooked: isBooked,
    isApproved: isApproved,
    bookedCount: bookedCount,
  );
}

class WeeklyAvailabilityDto {
  const WeeklyAvailabilityDto({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.date,
    required this.period,
  });

  factory WeeklyAvailabilityDto.fromJson(Map<String, Object?> json) {
    final dateStr = _requiredString(json, 'date');
    final parsedDate = DateTime.parse(dateStr);
    return WeeklyAvailabilityDto(
      id: _requiredPositiveInt(json, 'id'),
      mentorId: _requiredPositiveInt(json, 'mentorId'),
      mentorName: _requiredString(json, 'mentorName'),
      date: parsedDate,
      period: _requiredString(json, 'period'),
    );
  }

  final int id;
  final int mentorId;
  final String mentorName;
  final DateTime date;
  final String period;

  WeeklyAvailabilityItem toDomain() => WeeklyAvailabilityItem(
    id: id,
    mentorId: mentorId,
    mentorName: mentorName,
    date: date,
    period: period,
  );
}

class MentorMeetingDto {
  const MentorMeetingDto({
    required this.id,
    required this.status,
    this.learnerName,
    this.scheduledAt,
    this.meetingLink,
    this.reviewRating,
    this.reviewComment,
    this.reviewReply,
    this.hasDispute = false,
    this.disputeReason,
    this.disputeResponse,
  });

  factory MentorMeetingDto.fromJson(Map<String, Object?> json) {
    return MentorMeetingDto(
      id: _requiredPositiveInt(json, 'id'),
      learnerName: _optionalString(json, 'learnerName'),
      scheduledAt: switch (_optionalString(json, 'scheduledAt')) {
        final value? => MentorTimestamp.parse(value),
        null => null,
      },
      status: MentorMeetingStatus.fromApiValue(_requiredString(json, 'status')),
      meetingLink: _optionalString(json, 'meetingLink'),
      reviewRating: (json['reviewRating'] as num?)?.toInt(),
      reviewComment: _optionalString(json, 'reviewComment'),
      reviewReply: _optionalString(json, 'reviewReply'),
      hasDispute: json['hasDispute'] as bool? ?? false,
      disputeReason: _optionalString(json, 'disputeReason'),
      disputeResponse: _optionalString(json, 'disputeResponse'),
    );
  }

  final int id;
  final String? learnerName;
  final MentorTimestamp? scheduledAt;
  final MentorMeetingStatus status;
  final String? meetingLink;
  final int? reviewRating;
  final String? reviewComment;
  final String? reviewReply;
  final bool hasDispute;
  final String? disputeReason;
  final String? disputeResponse;

  MentorMeetingSummary toDomain() => MentorMeetingSummary(
    id: id,
    learnerName: learnerName,
    scheduledAt: scheduledAt,
    status: status,
    meetingLink: meetingLink,
    reviewRating: reviewRating,
    reviewComment: reviewComment,
    reviewReply: reviewReply,
    hasDispute: hasDispute,
    disputeReason: disputeReason,
    disputeResponse: disputeResponse,
  );
}

class MentorProfileDto {
  const MentorProfileDto({
    required this.mentorId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.expertise,
    this.jlptLevel,
    this.yearsOfExperience,
    this.workplace,
    this.verificationDocumentUrl,
    this.hasVerificationDocument = false,
    this.introductionVideoUrl,
    this.verificationStatus = 'Unverified',
    this.verificationStatusDescription = '',
    this.isBookable = false,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.reviewNotes,
  });

  factory MentorProfileDto.fromJson(Map<String, Object?> json) {
    return MentorProfileDto(
      mentorId: (json['mentorId'] as num?)?.toInt() ?? 0,
      email: _requiredString(json, 'email'),
      firstName: _optionalString(json, 'firstName'),
      lastName: _optionalString(json, 'lastName'),
      phoneNumber: _optionalString(json, 'phoneNumber'),
      avatarUrl: _optionalString(json, 'avatarUrl'),
      bio: _optionalString(json, 'bio'),
      expertise: _optionalString(json, 'expertise'),
      jlptLevel: _optionalString(json, 'jlptLevel'),
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      workplace: _optionalString(json, 'workplace'),
      verificationDocumentUrl: _optionalString(json, 'verificationDocumentUrl'),
      hasVerificationDocument: json['hasVerificationDocument'] as bool? ?? false,
      introductionVideoUrl: _optionalString(json, 'introductionVideoUrl'),
      verificationStatus: (json['verificationStatus']?.toString()) ?? 'Unverified',
      verificationStatusDescription: json['verificationStatusDescription']?.toString() ?? '',
      isBookable: json['isBookable'] as bool? ?? false,
      submittedAt: switch (_optionalString(json, 'submittedAt')) {
        final val? => DateTime.tryParse(val),
        null => null,
      },
      reviewedAt: switch (_optionalString(json, 'reviewedAt')) {
        final val? => DateTime.tryParse(val),
        null => null,
      },
      rejectionReason: _optionalString(json, 'rejectionReason'),
      reviewNotes: _optionalString(json, 'reviewNotes'),
    );
  }

  final int mentorId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? expertise;
  final String? jlptLevel;
  final int? yearsOfExperience;
  final String? workplace;
  final String? verificationDocumentUrl;
  final bool hasVerificationDocument;
  final String? introductionVideoUrl;
  final String verificationStatus;
  final String verificationStatusDescription;
  final bool isBookable;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? reviewNotes;

  MentorProfileData toDomain() => MentorProfileData(
    mentorId: mentorId,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    avatarUrl: avatarUrl,
    bio: bio,
    expertise: expertise,
    jlptLevel: jlptLevel,
    yearsOfExperience: yearsOfExperience,
    workplace: workplace,
    verificationDocumentUrl: verificationDocumentUrl,
    hasVerificationDocument: hasVerificationDocument,
    introductionVideoUrl: introductionVideoUrl,
    verificationStatus: verificationStatus,
    verificationStatusDescription: verificationStatusDescription,
    isBookable: isBookable,
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
    rejectionReason: rejectionReason,
    reviewNotes: reviewNotes,
  );
}

Map<String, Object?> readMentorResultObject(Object? body) {
  if (body is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor API response envelope.');
  }
  final result = body['result'];
  if (result is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor API result object.');
  }
  return result.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, Object?>> readMentorResultList(Object? body) {
  if (body is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Mentor API response envelope.');
  }
  final result = body['result'];
  if (result is! List<Object?>) {
    throw const FormatException('Expected a Mentor API result list.');
  }
  return result
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw const FormatException('Expected a Mentor API result object.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

int _requiredPositiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = switch (value) {
    int() => value,
    _ => null,
  };
  if (parsed == null || parsed <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return parsed;
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
