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
  Future<List<BookableMentor>> loadMentors() async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.mentors,
    );
    return readLearnerMentorResultList(response.data)
        .map(BookableMentorDto.fromJson)
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
    int? mentorAvailabilityId,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.purchase,
      data: PurchaseMentorPlanRequestDto(
        subscriptionPlanId: subscriptionPlanId,
        mentorAvailabilityId: mentorAvailabilityId,
        idempotencyKey: idempotencyKey,
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
    String? question,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.subscriptionBookings(subscriptionId),
      data: BookIncludedMeetingRequestDto(
        mentorAvailabilityId: mentorAvailabilityId,
        question: question,
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

  @override
  Future<MentorMeetingPurchaseStatus> syncPurchaseStatus(
    int subscriptionId,
  ) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.syncPurchase(subscriptionId),
    );
    return MentorMeetingPurchaseStatusDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<LearnerCreditBalance> loadCreditBalance() async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.creditBalance,
    );
    return LearnerCreditBalanceDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<LearnerMentorBooking> bookWithCredit({
    required int slotId,
    required String operationKey,
    String? notes,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.bookWithCredit,
      data: BookWithCreditRequestDto(
        mentorAvailabilityId: slotId,
        operationKey: operationKey,
        notes: notes,
      ).toJson(),
    );
    return LearnerMentorBookingDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<CancellationEligibility> checkCancellationEligibility(
    int bookingId,
  ) async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.cancellationEligibility(bookingId),
    );
    return CancellationEligibilityDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<bool> cancelBooking({
    required int bookingId,
    required String reason,
    bool requestException = false,
    String? exceptionReason,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.cancelBooking(bookingId),
      data: CancelMentorBookingRequestDto(
        reason: reason,
        requestException: requestException,
        exceptionReason: exceptionReason,
      ).toJson(),
    );
    return response.data != null;
  }

  @override
  Future<bool> rescheduleBooking({
    required int bookingId,
    required int newSlotId,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.rescheduleBooking(bookingId),
      data: RescheduleMentorBookingRequestDto(
        newMentorAvailabilityId: newSlotId,
      ).toJson(),
    );
    return response.data != null;
  }

  @override
  Future<MentorReviewItem> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.reviews,
      data: CreateMentorReviewRequestDto(
        mentorBookingId: bookingId,
        rating: rating,
        comment: comment,
      ).toJson(),
    );
    return MentorReviewDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<MentorRatingSummary> loadMentorReviewSummary(int mentorId) async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.mentorReviewSummary(mentorId),
    );
    return MentorRatingSummaryDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<List<MentorReviewItem>> loadMentorReviews(int mentorId) async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.mentorReviews(mentorId),
    );
    return readLearnerMentorResultList(response.data)
        .map(MentorReviewDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<LearnerDisputeItem> createDispute({
    required int bookingId,
    required int category,
    required String reason,
    String? evidenceNotes,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.disputes,
      data: CreateMentorDisputeRequestDto(
        mentorBookingId: bookingId,
        category: category,
        description: reason,
        evidenceNotes: evidenceNotes,
      ).toJson(),
    );
    return LearnerDisputeDto.fromJson(
      readLearnerMentorResultObject(response.data),
    ).toDomain();
  }

  @override
  Future<List<LearnerDisputeItem>> loadMyDisputes() async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.myDisputes,
    );
    return readLearnerMentorResultList(response.data)
        .map(LearnerDisputeDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<bool> submitAbuseReport({
    required int reportedUserId,
    required int reason,
    required String details,
  }) async {
    final response = await _apiClient.post<Object?>(
      LearnerMentorApiPaths.reportAbuse,
      data: SubmitAbuseReportRequestDto(
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
      ).toJson(),
    );
    return response.data != null;
  }
}
