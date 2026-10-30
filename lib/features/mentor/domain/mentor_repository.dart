import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

abstract interface class MentorRepository {
  Future<List<MentorAvailabilitySlot>> loadAvailability();

  Future<List<MentorMeetingSummary>> loadMeetings();

  Future<void> acceptMeeting(int bookingId);

  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(DateTime weekStart);

  Future<bool> saveWeeklySchedule({
    required DateTime weekStart,
    required List<WeeklyPeriodItem> periods,
  });
}
