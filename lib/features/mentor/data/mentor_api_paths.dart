abstract final class MentorApiPaths {
  static const String availability = '/api/mentor/availability';
  static const String meetings = '/api/mentor-bookings';
  static const String weeklySchedule = '/api/mentor-schedule/weekly';
  static const String profile = '/api/mentor/profile';
  static const String submitVerification = '/api/mentor/profile/submit-verification';
  static const String verificationDocument = '/api/mentor/profile/verification-document';
  static const String mentorDisputes = '/api/mentor/mentor-disputes';

  static String weeklyScheduleUrl(DateTime weekStart) {
    final d =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    return '$weeklySchedule?weekStart=$d';
  }

  static String cancelBooking(int bookingId) => '/api/mentor-bookings/$bookingId/cancel';
  static String replyReview(int reviewId) => '/api/mentor-reviews/$reviewId/reply';
  static String respondDispute(int disputeId) => '/api/mentor-disputes/$disputeId/respond';
}
