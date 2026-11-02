import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';

abstract interface class LearnerMentorRepository {
  Future<List<MentorMeetingPlan>> loadPlans();

  Future<List<BookableMentor>> loadMentors();

  Future<List<LearnerMentorAvailability>> loadAvailability({
    required DateTime from,
    required DateTime to,
    int? mentorId,
  });

  Future<MentorMeetingPurchase> purchase({
    required int subscriptionPlanId,
    int? mentorAvailabilityId,
    String? idempotencyKey,
  });

  Future<LearnerMentorBooking> bookIncludedSession({
    required int subscriptionId,
    required int mentorAvailabilityId,
    String? question,
  });

  Future<List<LearnerMentorBooking>> loadBookings();

  Future<MentorMeetingPurchaseStatus> loadPurchaseStatus(int subscriptionId);

  Future<MentorMeetingPurchaseStatus> syncPurchaseStatus(int subscriptionId);

  // Credit Ledger (Stage 06)
  Future<LearnerCreditBalance> loadCreditBalance();

  // Atomic Booking (Stage 08)
  Future<LearnerMentorBooking> bookWithCredit({
    required int slotId,
    required String operationKey,
    String? notes,
  });

  // Cancellation & Reschedule (Stage 10)
  Future<CancellationEligibility> checkCancellationEligibility(int bookingId);

  Future<bool> cancelBooking({
    required int bookingId,
    required String reason,
    bool requestException = false,
    String? exceptionReason,
  });

  Future<bool> rescheduleBooking({
    required int bookingId,
    required int newSlotId,
  });

  // Reviews & Disputes (Stage 11)
  Future<MentorReviewItem> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  });

  Future<MentorRatingSummary> loadMentorReviewSummary(int mentorId);

  Future<List<MentorReviewItem>> loadMentorReviews(int mentorId);

  Future<LearnerDisputeItem> createDispute({
    required int bookingId,
    required int category,
    required String reason,
    String? evidenceNotes,
  });

  Future<List<LearnerDisputeItem>> loadMyDisputes();

  Future<bool> submitAbuseReport({
    required int reportedUserId,
    required int reason,
    required String details,
  });
}
