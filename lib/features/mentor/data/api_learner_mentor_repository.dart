import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';

class ApiLearnerMentorRepository implements LearnerMentorRepository {
  const ApiLearnerMentorRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<MentorMeetingPlan>> loadPlans() async {
    final response = await _apiClient.get<Object?>(LearnerMentorApiPaths.plans);
    return readLearnerMentorResultList(response.data)
        .map(MentorMeetingPlanDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<LearnerMentorAvailability>> loadAvailability({
    required DateTime from,
    required DateTime to,
    int? mentorId,
  }) async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.availability,
      queryParameters: <String, Object?>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'mentorId': ?mentorId,
      },
    );
    return readLearnerMentorResultList(response.data)
        .map(LearnerMentorAvailabilityDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<MentorMeetingPurchase> purchase({
    required int subscriptionPlanId,
    required int mentorAvailabilityId,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.purchase,
      data: PurchaseMentorPlanRequestDto(
        subscriptionPlanId: subscriptionPlanId,
        mentorAvailabilityId: mentorAvailabilityId,
      ).toJson(),
    );
    return MentorMeetingPurchaseDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<LearnerMentorBooking> bookIncludedSession({
    required int subscriptionId,
    required int mentorAvailabilityId,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.subscriptionBookings(subscriptionId),
      data: BookIncludedMeetingRequestDto(
        mentorAvailabilityId: mentorAvailabilityId,
      ).toJson(),
    );
    return LearnerMentorBookingDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<List<LearnerMentorBooking>> loadBookings() async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.bookings,
    );
    return readLearnerMentorResultList(response.data)
        .map(LearnerMentorBookingDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<MentorMeetingPurchaseStatus> loadPurchaseStatus(
    int subscriptionId,
  ) async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.purchaseStatus(subscriptionId),
    );
    return MentorMeetingPurchaseStatusDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }
}
