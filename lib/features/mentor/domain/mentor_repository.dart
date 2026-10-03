import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

abstract interface class MentorRepository {
  Future<List<MentorAvailabilitySlot>> loadAvailability();

  Future<List<MentorMeetingSummary>> loadMeetings();
}
