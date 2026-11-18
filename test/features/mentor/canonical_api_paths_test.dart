import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/notifications/data/notification_api_paths.dart';

void main() {
  group('canonical Mentor API paths', () {
    test('uses unversioned Backend operation paths', () {
      final paths = <String>[
        LearnerMentorApiPaths.discoveryMentors,
        LearnerMentorApiPaths.mentors,
        MentorApiPaths.availability,
        MentorApiPaths.weeklySchedule,
        MentorApiPaths.profile,
        MentorApiPaths.submitVerification,
        MentorApiPaths.verificationDocument,
        MentorApiPaths.verificationDocumentContent,
        MentorApiPaths.kpiSummary,
        MentorApiPaths.scheduleV3,
        MentorApiPaths.scheduleV3Rules,
        MentorApiPaths.scheduleV3PreviewSlots,
        MentorApiPaths.scheduleV3PublishSlots,
        MentorApiPaths.roomAccess('room-1'),
        NotificationApiPaths.registerDeviceToken,
        NotificationApiPaths.refreshDeviceToken,
        NotificationApiPaths.unregisterDeviceToken,
      ];

      expect(paths, everyElement(isNot(contains('/api/v1/'))));
    });

    test('maps Mentor discovery, availability, KPI and room endpoints to Backend routes', () {
      expect(LearnerMentorApiPaths.discoveryMentors, '/api/mentors');
      expect(MentorApiPaths.availability, '/api/mentor/availability');
      expect(MentorApiPaths.kpiSummary, '/api/mentor/kpi/summary');
      expect(
        MentorApiPaths.roomAccess('room-1'),
        '/api/mentor-meetings/rooms/room-1/access',
      );
      expect(MentorApiPaths.scheduleV3, '/api/mentors/me/schedule');
    });
  });
}
