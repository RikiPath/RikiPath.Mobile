abstract final class LearnerMentorApiPaths {
  static const String root = '/api/mentor-meetings';
  static const String mentors = '$root/mentors';
  static const String discoveryMentors = '/api/mentors';
  static const String plans = '$root/plans';
  static const String availability = '$root/availability';
  static const String purchase = '$root/purchase';
  static const String bookings = '/api/learner/mentor-bookings';

  // Credit Ledger (Stage 06)
  static const String creditBalance = '/api/learner/credits/balance';
  static const String creditStatement = '/api/learner/credits/history';

  // Atomic Booking (Stage 08)
  static const String bookWithCredit = '/api/learner/mentor-bookings';
  static const String bookingHold = '$root/hold';
  static const String releaseBookingHold = '$root/release-hold';

  // Cancellation & Reschedule (Stage 10)
  static String cancellationEligibility(int bookingId) =>
      '/api/mentor-bookings/$bookingId/cancellation-eligibility';
  static String cancelBooking(int bookingId) =>
      '/api/mentor-bookings/$bookingId/cancel';
  static String rescheduleBooking(int bookingId) =>
      '/api/mentor-bookings/$bookingId/reschedule';

  // Reviews & Disputes (Stage 11)
  static const String reviews = '/api/mentor-reviews';
  static String updateReview(int reviewId) => '$reviews/$reviewId';
  static String mentorReviews(int mentorId) => '/api/mentors/$mentorId/reviews';
  static String mentorReviewSummary(int mentorId) =>
      '/api/mentors/$mentorId/rating-summary';
  static String replyReview(int reviewId) => '$reviews/$reviewId/reply';

  static const String disputes = '/api/mentor-disputes';
  static const String myDisputes = '/api/learner/mentor-disputes';
  static const String mentorDisputes = '/api/mentor/mentor-disputes';
  static String disputeDetail(int disputeId) => '$disputes/$disputeId';
  static String respondDispute(int disputeId) => '$disputes/$disputeId/respond';

  static String purchaseStatus(int subscriptionId) =>
      '$root/purchases/$subscriptionId';

  static String syncPurchase(int subscriptionId) =>
      '$root/purchases/$subscriptionId/sync';
}
