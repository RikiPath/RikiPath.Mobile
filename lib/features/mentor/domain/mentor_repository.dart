import 'dart:typed_data';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';

abstract interface class MentorRepository {
  Future<List<MentorAvailabilitySlot>> loadAvailability();

  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(DateTime weekStart);

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
