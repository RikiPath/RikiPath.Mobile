abstract final class MentorApiPaths {
  static const String availability = '/api/mentor/availability';
  static const String meetings = '/api/mentor/meetings';
  static const String weeklySchedule = '/api/mentor-schedule/weekly';
  static const String profile = '/api/mentor/profile';
  static const String submitVerification = '/api/mentor/profile/submit-verification';
  static const String verificationDocument = '/api/mentor/profile/verification-document';
  static const String mentorDisputes = '/api/v1/mentor/mentor-disputes';

  static String weeklyScheduleUrl(DateTime weekStart) {
    final d =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    return '$weeklySchedule?weekStart=$d';
  }

  static String acceptMeeting(int bookingId) => '$meetings/$bookingId/accept';
  static String cancelBooking(int bookingId) => '/api/v1/mentor-bookings/$bookingId/cancel';
  static String replyReview(int reviewId) => '/api/v1/mentor-reviews/$reviewId/reply';
  static String respondDispute(int disputeId) => '/api/v1/mentor-disputes/$disputeId/respond';
}
