import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/notifications/data/notification_api_paths.dart';

void main() {
  group('canonical Mentor API paths', () {
    test('uses unversioned Backend operation paths', () {
      final paths = <String>[
        LearnerMentorApiPaths.discoveryMentors,
        LearnerMentorApiPaths.creditBalance,
        LearnerMentorApiPaths.creditStatement,
        LearnerMentorApiPaths.cancellationEligibility(42),
        LearnerMentorApiPaths.cancelBooking(42),
        LearnerMentorApiPaths.rescheduleBooking(42),
        LearnerMentorApiPaths.reviews,
        LearnerMentorApiPaths.mentorReviews(42),
        LearnerMentorApiPaths.mentorReviewSummary(42),
        LearnerMentorApiPaths.disputes,
        LearnerMentorApiPaths.myDisputes,
        LearnerMentorApiPaths.mentorDisputes,
        MentorApiPaths.mentorDisputes,
        MentorApiPaths.cancelBooking(42),
        MentorApiPaths.replyReview(42),
        MentorApiPaths.respondDispute(42),
        NotificationApiPaths.registerDeviceToken,
        NotificationApiPaths.refreshDeviceToken,
        NotificationApiPaths.unregisterDeviceToken,
      ];

      expect(paths, everyElement(isNot(contains('/api/v1/'))));
    });

    test('maps credit and public-review paths to Backend-owned routes', () {
      expect(LearnerMentorApiPaths.creditBalance, '/api/learner/credits/balance');
      expect(LearnerMentorApiPaths.creditStatement, '/api/learner/credits/history');
      expect(LearnerMentorApiPaths.mentorReviews(42), '/api/mentors/42/reviews');
      expect(LearnerMentorApiPaths.mentorReviewSummary(42), '/api/mentors/42/rating-summary');
      expect(LearnerMentorApiPaths.myDisputes, '/api/learner/mentor-disputes');
      expect(LearnerMentorApiPaths.mentorDisputes, '/api/mentor/mentor-disputes');
    });
  });
}
