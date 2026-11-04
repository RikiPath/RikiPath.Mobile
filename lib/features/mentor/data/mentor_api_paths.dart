abstract final class MentorApiPaths {
  static const String availability = '/api/mentor/availability';
  static const String meetings = '/api/mentor-bookings';
  static const String weeklySchedule = '/api/mentor-schedule/weekly';
  static const String profile = '/api/mentor/profile';
  static const String submitVerification =
      '/api/mentor/profile/submit-verification';
  static const String verificationDocument =
      '/api/mentor/profile/verification-document';
  static const String mentorDisputes = '/api/mentor/mentor-disputes';

  // Mentor Self-Service Compensation & Bank Account (Mentor Compensation Milestone)
  static const String compensationOverview =
      '/api/mentor/compensation/overview';
  static const String compensationHourlyRates =
      '/api/mentor/compensation/hourly-rates';
  static const String compensationQualifications =
      '/api/mentor/compensation/qualifications';
  static const String compensationEarnings =
      '/api/mentor/compensation/earnings';
  static const String compensationPayrolls =
      '/api/mentor/compensation/payrolls';
  static const String compensationBankAccounts =
      '/api/mentor/compensation/bank-accounts';
  static const String compensationPayouts = '/api/mentor/compensation/payouts';

  static String compensationPayrollDetail(int payrollPeriodId) =>
      '$compensationPayrolls/$payrollPeriodId';

  static String compensationPayoutDetail(int obligationId) =>
      '$compensationPayouts/$obligationId';

  static String weeklyScheduleUrl(DateTime weekStart) {
    final d =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    return '$weeklySchedule?weekStart=$d';
  }

  static String cancelBooking(int bookingId) =>
      '/api/mentor-bookings/$bookingId/cancel';
  static String replyReview(int reviewId) =>
      '/api/mentor-reviews/$reviewId/reply';
  static String respondDispute(int disputeId) =>
      '/api/mentor-disputes/$disputeId/respond';
}
