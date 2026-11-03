import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';

class ApiMentorRepository implements MentorRepository {
  const ApiMentorRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async {
    final response = await _apiClient.get<Object?>(MentorApiPaths.availability);
    return readMentorResultList(response.data)
        .map(MentorAvailabilityDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() async {
    final response = await _apiClient.get<Object?>(MentorApiPaths.meetings);
    return readMentorResultList(response.data)
        .map(MentorMeetingDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(
    DateTime weekStart,
  ) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.weeklyScheduleUrl(weekStart),
    );
    return readMentorResultList(response.data)
        .map(WeeklyAvailabilityDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<bool> saveWeeklySchedule({
    required DateTime weekStart,
    required List<WeeklyPeriodItem> periods,
  }) async {
    final weekStartStr =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final payload = {
      'weekStart': weekStartStr,
      'periods': periods
          .map((p) => {'date': p.formattedDate, 'period': p.period})
          .toList(growable: false),
    };
    final response = await _apiClient.put<Object?>(
      MentorApiPaths.weeklySchedule,
      data: payload,
    );
    if (response.data is Map<Object?, Object?>) {
      final map = response.data as Map<Object?, Object?>;
      return map['isSuccess'] == true;
    }
    return true;
  }

  @override
  Future<bool> cancelMeeting(int bookingId, String reason) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.cancelBooking(bookingId),
      data: {'reason': reason},
    );
    if (response.data is Map<Object?, Object?>) {
      final map = response.data as Map<Object?, Object?>;
      return map['isSuccess'] == true;
    }
    return true;
  }

  @override
  Future<bool> replyReview(int reviewId, String reply) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.replyReview(reviewId),
      data: {'reply': reply},
    );
    if (response.data is Map<Object?, Object?>) {
      final map = response.data as Map<Object?, Object?>;
      return map['isSuccess'] == true;
    }
    return true;
  }

  @override
  Future<bool> respondDispute(int disputeId, String responseText) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.respondDispute(disputeId),
      data: {'responseText': responseText},
    );
    if (response.data is Map<Object?, Object?>) {
      final map = response.data as Map<Object?, Object?>;
      return map['isSuccess'] == true;
    }
    return true;
  }

  @override
  Future<MentorProfileData> loadProfile() async {
    final response = await _apiClient.get<Object?>(MentorApiPaths.profile);
    final map = readMentorResultObject(response.data);
    return MentorProfileDto.fromJson(map).toDomain();
  }

  @override
  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async {
    final payload = <String, Object?>{
      'bio': ?bio,
      'expertise': ?expertise,
      'jlptLevel': ?jlptLevel,
      'yearsOfExperience': ?yearsOfExperience,
      'workplace': ?workplace,
      'introductionVideoUrl': ?introductionVideoUrl,
    };
    final response = await _apiClient.put<Object?>(
      MentorApiPaths.profile,
      data: payload,
    );
    final map = readMentorResultObject(response.data);
    return MentorProfileDto.fromJson(map).toDomain();
  }

  @override
  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async {
    final payload = <String, Object?>{'notes': ?notes};
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.submitVerification,
      data: payload,
    );
    final map = readMentorResultObject(response.data);
    return MentorProfileDto.fromJson(map).toDomain();
  }

  @override
  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lowerName = fileName.toLowerCase();
    final contentType = lowerName.endsWith('.pdf')
        ? 'application/pdf'
        : lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')
        ? 'image/jpeg'
        : lowerName.endsWith('.png')
        ? 'image/png'
        : throw ArgumentError.value(
            fileName,
            'fileName',
            'Unsupported document type',
          );
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.verificationDocument,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
    );
    return MentorProfileDto.fromJson(
      readMentorResultObject(response.data),
    ).toDomain();
  }
}
