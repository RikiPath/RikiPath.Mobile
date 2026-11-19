abstract final class LearnerMentorApiPaths {
  static const String discoveryMentors = '/api/mentors';
  static const String mentors = discoveryMentors;
  static String mentorProfile(int mentorId) => '$discoveryMentors/$mentorId/profile';
}
