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
}
