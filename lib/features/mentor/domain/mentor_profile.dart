import 'package:flutter/foundation.dart';

@immutable
class MentorProfileData {
  const MentorProfileData({
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

  String get fullName {
    final fn = firstName ?? '';
    final ln = lastName ?? '';
    final combined = '$fn $ln'.trim();
    return combined.isEmpty ? email : combined;
  }

  bool get isApproved => verificationStatus.toLowerCase() == 'approved';
  bool get isPending => verificationStatus.toLowerCase() == 'pending';
  bool get isRejected => verificationStatus.toLowerCase() == 'rejected';
  bool get isChangesRequested =>
      verificationStatus.toLowerCase() == 'changesrequested';

  MentorProfileData copyWith({
    int? mentorId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    bool? hasVerificationDocument,
    String? introductionVideoUrl,
    String? verificationStatus,
    String? verificationStatusDescription,
    bool? isBookable,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? reviewNotes,
  }) {
    return MentorProfileData(
      mentorId: mentorId ?? this.mentorId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      expertise: expertise ?? this.expertise,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      workplace: workplace ?? this.workplace,
      verificationDocumentUrl:
          verificationDocumentUrl ?? this.verificationDocumentUrl,
      hasVerificationDocument:
          hasVerificationDocument ?? this.hasVerificationDocument,
      introductionVideoUrl:
          introductionVideoUrl ?? this.introductionVideoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationStatusDescription:
          verificationStatusDescription ?? this.verificationStatusDescription,
      isBookable: isBookable ?? this.isBookable,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }
}
