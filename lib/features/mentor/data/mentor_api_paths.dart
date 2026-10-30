abstract final class MentorApiPaths {
  static const String availability = '/api/mentor/availability';
  static const String meetings = '/api/mentor/meetings';
  static const String weeklySchedule = '/api/mentor-schedule/weekly';

  static String weeklyScheduleUrl(DateTime weekStart) {
    final d =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    return '$weeklySchedule?weekStart=$d';
  }

  static String acceptMeeting(int bookingId) => '$meetings/$bookingId/accept';
}
