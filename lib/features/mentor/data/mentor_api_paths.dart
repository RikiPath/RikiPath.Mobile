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
  static const String verificationDocumentContent =
      '/api/mentor/profile/verification-document/content';
  static const String mentorChatThreads = '/api/mentor-chat/threads';
  static const String mentorChatHub = '/hubs/mentor-chat';
  static const String scheduleV3 = '/api/mentors/me/schedule';
  static const String scheduleV3Rules = '/api/mentors/me/schedule/rules';
  static const String scheduleV3PreviewSlots =
      '/api/mentors/me/schedule/preview-slots';
  static const String scheduleV3PublishSlots =
      '/api/mentors/me/schedule/publish-slots';
  static const String requestCancelAvailability =
      '/api/mentor/availability/request-cancel';

  static String compensationPayrollDetail(int payrollPeriodId) =>
      '$compensationPayrolls/$payrollPeriodId';

  static String compensationPayoutDetail(int obligationId) =>
      '$compensationPayouts/$obligationId';

  static String weeklyScheduleUrl(DateTime weekStart) {
    final d =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    return '$weeklySchedule?weekStart=$d';
  }

  static String bookingDetail(int bookingId) =>
      '/api/mentor-bookings/$bookingId';
  static String cancellationEligibility(int bookingId) =>
      '/api/mentor-bookings/$bookingId/cancellation-eligibility';
  static String bookingAttendance(int bookingId) =>
      '/api/mentor-meetings/bookings/$bookingId/attendance';
  static String roomAccess(String roomId) =>
      '/api/mentor-meetings/rooms/$roomId/access';
  static String cancelBooking(int bookingId) =>
      '/api/mentor-bookings/$bookingId/cancel';
  static String mentorRatingSummary(int mentorId) =>
      '/api/mentors/$mentorId/rating-summary';
  static String mentorReviews(int mentorId) =>
      '/api/mentors/$mentorId/reviews';
  static String replyReview(int reviewId) =>
      '/api/mentor-reviews/$reviewId/reply';
  static String disputeDetail(int disputeId) =>
      '/api/mentor-disputes/$disputeId';
  static String respondDispute(int disputeId) =>
      '/api/mentor-disputes/$disputeId/respond';
  static String mentorChatThread(int bookingId) =>
      '$mentorChatThreads/$bookingId';
  static String mentorChatMessages(int bookingId) =>
      '$mentorChatThreads/$bookingId/messages';
  static String mentorChatRead(int bookingId) =>
      '$mentorChatThreads/$bookingId/read';
  static String scheduleV3DisableSlot(int slotId) =>
      '$scheduleV3/slots/$slotId/disable';
  static String scheduleV3DeleteSlot(int slotId) =>
      '$scheduleV3/slots/$slotId';
  static String deleteAvailability(int id) => '$availability/$id';
  static String requestSlotChange(int slotId) =>
      '/api/mentor-schedule/slots/$slotId/change';
}
