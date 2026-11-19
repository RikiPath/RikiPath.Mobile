import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';

abstract interface class LearnerMentorRepository {
  Future<List<BookableMentor>> loadMentors();
  Future<BookableMentor?> loadPublicProfile(int mentorId);
}
