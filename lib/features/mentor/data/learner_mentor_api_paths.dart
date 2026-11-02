abstract final class LearnerMentorApiPaths {
  static const String root = '/api/mentor-meetings';
  static const String mentors = '$root/mentors';
  static const String discoveryMentors = '/api/v1/mentors';
  static const String plans = '$root/plans';
  static const String availability = '$root/availability';
  static const String purchase = '$root/purchase';
  static const String bookings = '$root/bookings';

  // Credit Ledger (Stage 06)
  static const String creditBalance = '/api/v1/mentor-credits/balance';
  static const String creditStatement = '/api/v1/mentor-credits/statement';

  // Atomic Booking (Stage 08)
  static const String bookWithCredit = '$root/book';
  static const String bookingHold = '$root/hold';
  static const String releaseBookingHold = '$root/release-hold';

  // Cancellation & Reschedule (Stage 10)
  static String cancellationEligibility(int bookingId) =>
      '/api/v1/mentor-bookings/$bookingId/cancellation-eligibility';
  static String cancelBooking(int bookingId) =>
      '/api/v1/mentor-bookings/$bookingId/cancel';
  static String rescheduleBooking(int bookingId) =>
      '/api/v1/mentor-bookings/$bookingId/reschedule';

  // Reviews & Disputes (Stage 11)
  static const String reviews = '/api/v1/mentor-reviews';
  static String updateReview(int reviewId) => '$reviews/$reviewId';
  static String mentorReviews(int mentorId) => '$reviews/mentor/$mentorId';
  static String mentorReviewSummary(int mentorId) =>
      '$reviews/mentor/$mentorId/summary';
  static String replyReview(int reviewId) => '$reviews/$reviewId/reply';

  static const String disputes = '/api/v1/mentor-disputes';
  static const String myDisputes = '$disputes/my-disputes';
  static const String mentorDisputes = '$disputes/mentor-disputes';
  static String disputeDetail(int disputeId) => '$disputes/$disputeId';
  static String respondDispute(int disputeId) => '$disputes/$disputeId/respond';
  static const String reportAbuse = '$disputes/report-abuse';

  static String subscriptionBookings(int subscriptionId) =>
      '$root/subscriptions/$subscriptionId/bookings';

  static String purchaseStatus(int subscriptionId) =>
      '$root/purchases/$subscriptionId';

  static String syncPurchase(int subscriptionId) =>
      '$root/purchases/$subscriptionId/sync';
}
