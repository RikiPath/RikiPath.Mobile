import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';

void main() {
  test(
    'cohort course sessions map using configured 90-minute duration and source ids',
    () async {
      final container = ProviderContainer(
        overrides: [
          learnerMyCoursesProvider.overrideWith(() => _CoursesController()),
        ],
      );
      addTearDown(container.dispose);

      final events = await container.read(learnerCalendarEventsProvider.future);
      expect(events, hasLength(1));
      expect(events.single.type, SakuraCalendarEventType.consultation);
      expect(events.single.durationMinutes, 90);
      expect(events.single.sourceEntityId, '17:101');
      expect(events.single.bookingId, 17);
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

class _CoursesController extends LearnerMyCoursesController {
  @override
  Future<List<LearnerStudyCourseDetail>> build() async => [
    LearnerStudyCourseDetail(
      id: 17,
      name: 'JLPT N3 Nhóm 1',
      planId: 1,
      cohortId: 8,
      sessionType: 'Group',
      level: 'N3',
      mentorId: 5,
      mentorName: 'Sensei An',
      durationMonths: 2,
      sessionsPerWeek: 3,
      totalSessions: 30,
      sessionMinutes: 90,
      amount: 2000000,
      paymentStatus: 'Paid',
      status: 'Active',
      startsAt: DateTime.utc(2026, 11, 10, 9),
      endsAt: DateTime.utc(2027, 1, 19, 9),
      completedAt: null,
      eligibility: const CourseEligibilitySummary(
        canClaim: false,
        passedOnTimeHomework: 0,
        requiredHomework: 0,
        absentSessions: 0,
        countedSessions: 0,
        reasons: [],
      ),
      sessions: [
        CourseSessionItem(
          id: 101,
          number: 1,
          attempt: 1,
          scheduledAt: DateTime.utc(2026, 11, 10, 9),
          status: 'Scheduled',
          meetingUrl: 'https://meet.example.com/meeting-room/r-101',
        ),
      ],
      requests: const [],
    ),
  ];
}

class _ReviewRepository implements DailyReviewRepository {
  @override
  Future<DailyReviewQueue> loadDailyQueue() async => const DailyReviewQueue(
    totalDue: 4,
    items: [],
  );

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
        pathId: 9,
        userId: 1,
        generatedAt: DateTime.utc(2026, 11, 1),
        summary: '',
        strengths: const [],
        weaknesses: const [],
        feasibility: 'High',
        isExamDateRealistic: true,
        recommendedStudyDays: 2,
        focusTopics: const ['Từ vựng', 'Ngữ pháp'],
        dailySchedules: [
          const RecommendedLearningDay(
            day: 1,
            title: 'Ngày 1',
            focus: 'Từ vựng',
            lessons: [],
          ),
          RecommendedLearningDay(
            day: 2,
            title: 'Ngày 2',
            focus: 'Ngữ pháp',
            lessons: const [],
            completedAt: DateTime(2026, 11, 8, 20),
          ),
        ],
      );

  @override
  Future<RecommendedLearningPath> generate() => throw UnimplementedError();
}
