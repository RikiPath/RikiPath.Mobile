import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/cohorts/data/mentor_cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/mentor_cohort_detail_screen.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/mentor_cohorts_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

class _FakeMentorCohortRepository implements MentorCohortRepository {
  final List<({int id, String response})> responses = [];
  final List<Map<String, Object?>> scheduleRequests = [];

  static final DateTime _start = DateTime.now().add(const Duration(days: 7));

  @override
  Future<List<StudyCohortSummary>> fetchAssignedCohorts() async => [
    StudyCohortSummary(
      id: 20,
      planId: 3,
      name: 'N5 Morning Cohort',
      mentorId: 7,
      mentorName: 'Yamada Sensei',
      startsAt: _start,
      endsAt: _start.add(const Duration(days: 70)),
      capacity: 4,
      enrolledCount: 3,
      seatsAvailable: 1,
      status: 'Published',
      level: 'N5',
      totalSessions: 30,
      sessionMinutes: 90,
      price: 2000000,
      enrollmentClosesAtUtc: _start.subtract(const Duration(days: 1)),
      requiresEntitlement: false,
      hasApprovedEntitlement: false,
      entitlementReference: null,
      entitlementStatusMessage: null,
      myEnrollmentCourseId: null,
      myEnrollmentStatus: null,
      enrollmentOpen: true,
      intensity: 'Advanced',
      intensityLabel: 'Nâng cao',
      sessionsPerWeek: 3,
      sessions: [
        CohortSessionSlot(
          number: 1,
          availabilityId: 1,
          roomId: 'room-20',
          startTime: _start,
          endTime: _start.add(const Duration(minutes: 90)),
          status: 'Scheduled',
        ),
      ],
    ),
  ];

  @override
  Future<List<MentorCohortRosterEntry>> fetchRoster(int cohortId) async => [
    const MentorCohortRosterEntry(
      courseId: 101,
      learnerId: 501,
      learnerName: 'Nguyễn An',
      status: 'Active',
    ),
    const MentorCohortRosterEntry(
      courseId: 102,
      learnerId: 502,
      learnerName: 'Trần Bình',
      status: 'Active',
    ),
    const MentorCohortRosterEntry(
      courseId: 103,
      learnerId: 503,
      learnerName: 'Lê Chi',
      status: 'Active',
    ),
  ];

  @override
  Future<List<MentorCohortHomeworkItem>> fetchCohortHomework(
    int cohortId,
  ) async => const [
    MentorCohortHomeworkItem(
      id: 1,
      title: 'Hiragana tuần 1',
      status: 'Assigned',
      assignmentScope: 'CohortCommon',
      submittedCount: 2,
      totalCount: 3,
    ),
  ];

  @override
  Future<List<HomeworkCatalogItem>> fetchHomeworkCatalog({
    String? level,
    String? search,
  }) async => const [];

  @override
  Future<void> createCohortHomework({
    required int cohortId,
    required String title,
    String? instructions,
    DateTime? dueAt,
    List<int> lessonIds = const [],
    List<int> practiceExerciseIds = const [],
    List<int>? targetLearnerIds,
  }) async {}

  @override
  Future<({Uint8List bytes, String contentType})> downloadHomeworkScan(
    int assignmentId,
  ) async => (bytes: Uint8List(0), contentType: 'image/png');

  @override
  Future<MentorHomeworkAiDraft> generateHomeworkAiDraft(
    int assignmentId,
  ) async => const MentorHomeworkAiDraft(suggestedScore: 85, feedback: 'OK');

  @override
  Future<void> publishHomeworkGrade({
    required int assignmentId,
    required int submissionId,
    required double score,
    required String feedback,
  }) async {}

  @override
  Future<void> confirmSessionAttendance({
    required int courseId,
    required int sessionId,
    required String status,
    required String note,
  }) async {}

  @override
  Future<void> saveRetakeSupportPlan({
    required int courseId,
    required int requestId,
    required String supportPlan,
  }) async {}

  @override
  Future<MentorLearnerSkillProfile> fetchLearnerSkillProfile({
    required int learnerId,
    required int cohortId,
  }) async => MentorLearnerSkillProfile(learnerId: learnerId, learnerName: 'Học viên');

  @override
  Future<List<CohortMentorAssignment>> fetchMentorAssignments(
    int cohortId,
  ) async => const [
    CohortMentorAssignment(mentorId: 7, mentorName: 'Yamada Sensei', isPrimary: true),
  ];

  @override
  Future<List<CohortComplaint>> fetchComplaints({String? status}) async => [
    _complaint(id: 1, category: CohortComplaintCategory.teachingQuality),
    _complaint(id: 2, category: CohortComplaintCategory.paymentEnrollment),
  ];

  @override
  Future<void> respondToComplaint({
    required int complaintId,
    required String response,
  }) async {
    responses.add((id: complaintId, response: response));
  }

  @override
  Future<CohortShiftPreview> fetchShiftPreview({
    required int cohortId,
    int weeks = 1,
  }) async => const CohortShiftPreview(eligible: true);

  @override
  Future<List<CohortScheduleRequest>> fetchScheduleRequests(
    int cohortId,
  ) async => const [];

  @override
  Future<CohortScheduleRequest?> createScheduleRequest({
    required int cohortId,
    required String kind,
    int? shiftWeeks,
    required String reason,
    required String idempotencyKey,
  }) async {
    scheduleRequests.add({
      'cohortId': cohortId,
      'kind': kind,
      'shiftWeeks': shiftWeeks,
      'reason': reason,
      'idempotencyKey': idempotencyKey,
    });
    return null;
  }

  @override
  Future<void> withdrawScheduleRequest(int requestId) async {}
}

CohortComplaint _complaint({required int id, required String category}) =>
    CohortComplaint(
      id: id,
      courseId: 101,
      cohortId: 20,
      cohortName: 'N5 Morning Cohort',
      mentorId: 7,
      mentorName: 'Yamada Sensei',
      category: category,
      message: 'Nội dung khiếu nại số $id',
      status: 'Open',
      refundReviewRequested: false,
      hasEvidence: false,
      mentorResponse: null,
      decision: null,
      createdAtUtc: DateTime(2026, 11, 16),
      decidedAtUtc: null,
      revision: 1,
    );

Widget _app(_FakeMentorCohortRepository repo, Widget home) => ProviderScope(
  overrides: [mentorCohortRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: home,
  ),
);

void main() {
  testWidgets('Mentor cohorts list renders intensity, sessions/week and roster '
      'count', (tester) async {
    final repo = _FakeMentorCohortRepository();
    await tester.pumpWidget(_app(repo, const MentorCohortsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('N5 Morning Cohort'), findsOneWidget);
    final intensity = tester.widget<MentorStatusBadge>(
      find.byKey(const ValueKey('mentor_cohort_intensity_20')),
    );
    expect(intensity.label, 'Nâng cao');
    expect(find.textContaining('3 buổi/tuần'), findsOneWidget);
    expect(find.text('Học viên: 3/4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mentor_cohort_next_20')),
      findsOneWidget,
    );
    expect(find.textContaining('Buổi tiếp theo: Buổi 1'), findsOneWidget);
  });

  testWidgets('Mentor cohort detail shows roster names only and hides respond '
      'for payment complaints', (tester) async {
    final repo = _FakeMentorCohortRepository();
    await tester.pumpWidget(
      _app(repo, const MentorCohortDetailScreen(cohortId: 20)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Lê Chi'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('Trần Bình'), findsOneWidget);
    expect(find.text('3 học viên'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mentor_complaint_2')),
      200,
      scrollable: scrollable,
    );
    expect(
      find.byKey(const ValueKey('mentor_complaint_respond_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mentor_complaint_respond_2')),
      findsNothing,
    );
  });
}
