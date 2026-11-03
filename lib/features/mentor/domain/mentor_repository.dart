import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'dart:typed_data';

abstract interface class MentorRepository {
  Future<List<MentorAvailabilitySlot>> loadAvailability();

  Future<List<MentorMeetingSummary>> loadMeetings();

  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(DateTime weekStart);

  Future<bool> saveWeeklySchedule({
    required DateTime weekStart,
    required List<WeeklyPeriodItem> periods,
  });

  Future<bool> cancelMeeting(int bookingId, String reason);

  Future<bool> replyReview(int reviewId, String reply);

  Future<bool> respondDispute(int disputeId, String responseText);

  Future<MentorProfileData> loadProfile();

  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  });

  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  });

  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  });
}
