abstract final class MentorApiPaths {
  static const String availability = '/api/mentor/availability';
  static const String weeklySchedule = '/api/mentor-schedule/weekly';
  static const String profile = '/api/mentor/profile';
  static const String submitVerification =
      '/api/mentor/profile/submit-verification';
  static const String verificationDocument =
      '/api/mentor/profile/verification-document';

  // Non-Financial Attendance & Teaching KPI
  static const String kpiSummary = '/api/mentor/kpi/summary';
  static const String verificationDocumentContent =
      '/api/mentor/profile/verification-document/content';
  static const String scheduleV3 = '/api/mentors/me/schedule';
  static const String scheduleV3Rules = '/api/mentors/me/schedule/rules';
  static const String scheduleV3PreviewSlots =
      '/api/mentors/me/schedule/preview-slots';
  static const String scheduleV3PublishSlots =
      '/api/mentors/me/schedule/publish-slots';
  static const String requestCancelAvailability =
      '/api/mentor/availability/request-cancel';

  static String weeklyScheduleUrl(DateTime weekStart) {
    final d =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    return '$weeklySchedule?weekStart=$d';
  }

  static String roomAccess(String roomId) =>
      '/api/mentor-meetings/rooms/$roomId/access';
  static String scheduleV3DeleteSlot(int slotId) =>
      '$scheduleV3/slots/$slotId';
  static String deleteAvailability(int id) => '$availability/$id';
  static String requestSlotChange(int slotId) =>
      '/api/mentor-schedule/slots/$slotId/change';
}
