import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';

void main() {
  test(
    'booking uses API end time instead of assigning 90 minutes to history',
    () async {
      final container = ProviderContainer(
        overrides: [
          learnerMentorBookingsControllerProvider.overrideWith(
            () => _BookingsController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final events = await container.read(learnerCalendarEventsProvider.future);
      expect(events, hasLength(1));
      expect(events.single.type, SakuraCalendarEventType.consultation);
      expect(events.single.durationMinutes, 50);
      expect(events.single.sourceEntityId, '17');
    },
  );

  test('SRS queue is displayed only on the current local day', () async {
    final container = ProviderContainer(
      overrides: [
        dailyReviewRepositoryProvider.overrideWith(
          (ref) => _ReviewRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final events = await container.read(
      learnerCalendarSrsEventsProvider.future,
    );
    expect(events, hasLength(1));
    expect(events.single.title, '4 thẻ cần ôn');
    expect(events.single.isSameDay(DateTime.now()), isTrue);
    expect(events.single.type, SakuraCalendarEventType.srsReview);
    expect(events.single.navigationTarget, 'dailyReview');
  });

  test(
    'learner calendar keeps only public unbooked slots as availability',
    () async {
      final container = ProviderContainer(
        overrides: [
          learnerMentorAvailabilityControllerProvider.overrideWith(
            () => _AvailabilityController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final events = await container.read(
        learnerCalendarAvailableSlotsProvider.future,
      );
      expect(events, hasLength(1));
      expect(events.single.id, 'available_12');
      expect(events.single.type, SakuraCalendarEventType.availableSlot);
      expect(events.single.bookingId, isNull);
    },
  );

  test('learning dates use completedAt, never inferred day order', () async {
    final container = ProviderContainer(
      overrides: [
        learningPathRepositoryProvider.overrideWith(
          (ref) => _LearningRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final events = await container.read(
      learnerCalendarLearningEventsProvider.future,
    );
    expect(events, hasLength(1));
    expect(events.single.title, 'Đã học: Ngày 2');
    expect(events.single.isSameDay(DateTime(2026, 11, 8)), isTrue);
    expect(events.single.sourceEntityId, '9:2');
  });
}

class _BookingsController extends LearnerMentorBookingsController {
  @override
  Future<List<LearnerMentorBooking>> build() async => [
    LearnerMentorBooking(
      id: 17,
      userSubscriptionId: 5,
      status: MentorMeetingStatus.accepted,
      scheduledAt: MentorTimestamp.parse('2026-11-10T09:00:00Z'),
      endsAt: MentorTimestamp.parse('2026-11-10T09:50:00Z'),
    ),
  ];
}

class _AvailabilityController extends LearnerMentorAvailabilityController {
  @override
  Future<List<LearnerMentorAvailability>> build() async => [
    LearnerMentorAvailability(
      id: 12,
      mentorId: 5,
      mentorName: 'Cố vấn An',
      startTime: MentorTimestamp.parse('2026-11-12T09:00:00Z'),
      endTime: MentorTimestamp.parse('2026-11-12T10:30:00Z'),
      isBooked: false,
    ),
    LearnerMentorAvailability(
      id: 13,
      mentorId: 5,
      mentorName: 'Cố vấn An',
      startTime: MentorTimestamp.parse('2026-11-13T09:00:00Z'),
      endTime: MentorTimestamp.parse('2026-11-13T10:30:00Z'),
      isBooked: true,
    ),
  ];
}

class _ReviewRepository implements DailyReviewRepository {
  @override
  Future<DailyReviewQueue> loadDailyQueue() async =>
      const DailyReviewQueue(totalDue: 4, items: []);

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) => throw UnimplementedError();
}

class _LearningRepository implements LearningPathRepository {
  @override
  Future<RecommendedLearningPath?> loadLatest() async =>
      RecommendedLearningPath(
        userId: 1,
        pathId: 9,
        generatedAt: DateTime.utc(2026, 11, 1),
        summary: '',
        strengths: const [],
        weaknesses: const [],
        feasibility: '',
        isExamDateRealistic: null,
        recommendedStudyDays: 2,
        focusTopics: const [],
        dailySchedules: [
          const RecommendedLearningDay(
            day: 1,
            title: 'Ngày 1',
            focus: '',
            lessons: [],
          ),
          RecommendedLearningDay(
            day: 2,
            title: 'Ngày 2',
            focus: '',
            lessons: const [],
            completedAt: DateTime(2026, 11, 8, 10),
          ),
        ],
      );

  @override
  Future<RecommendedLearningPath> generate() => throw UnimplementedError();
}
