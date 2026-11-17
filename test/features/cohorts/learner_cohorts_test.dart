import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/data/cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/learner_cohort_detail_screen.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/learner_cohorts_screen.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_complaint_section.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_completion_summary_card.dart';

class _FakeCohortRepository implements CohortRepository {
  _FakeCohortRepository({
    this.courseStatus = 'Completed',
    this.transfers = const [],
    this.paymentState = '',
  });

  final String courseStatus;
  final String paymentState;
  int checkoutCalls = 0;
  final List<int> reconcileCalls = [];
  List<CohortTransferRequestItem> transfers;
  String? submittedText;
  String? submittedRetakeReason;
  String? transferReason;
  int? transferTarget;
  int? transferCourseId;
  String? transferKey;
  int enrollCalls = 0;
  final List<Map<String, Object?>> cohortQueries = [];
  String? complaintCategory;
  String? complaintMessage;
  String? complaintKey;
  int? complaintCourseId;
  bool? complaintRefund;
  final List<CohortComplaint> complaints = [];

  @override
  Future<MentorCohortReviewSummary> fetchMentorReviewSummary(
    int mentorId,
  ) async => MentorCohortReviewSummary(
    mentorId: mentorId,
    averageRating: mentorId == 2 ? 4.5 : 0,
    reviewCount: mentorId == 2 ? 8 : 0,
  );

  @override
  Future<CohortCompletionSummary> fetchCompletionSummary(int courseId) async =>
      CohortCompletionSummary(
        courseId: courseId,
        cohortId: 10,
        cohortName: 'N3 Evening Cohort',
        level: 'N3',
        intensity: 'Standard',
        intensityLabel: 'Tiêu chuẩn',
        isCompleted: courseStatus == 'Completed',
        mentors: const [
          CompletionMentorItem(
            mentorId: 2,
            mentorName: 'Tanaka Sensei',
            sessionNumbers: [1],
            isPrimary: true,
          ),
        ],
        sessions: const CompletionSessionCounts(total: 1, delivered: 1),
        attendance: [
          CompletionAttendanceItem(
            number: 1,
            scheduledAt: DateTime(2026, 11, 1, 19, 0),
            status: 'Present',
          ),
        ],
        homework: const CompletionHomeworkCounts(
          assigned: 1,
          submitted: 1,
          graded: 1,
        ),
        mentorFeedback: const [],
        skillProgressAvailable: false,
        note: '',
      );

  @override
  Future<List<CohortMentorReview>> fetchCourseMentorReviews(
    int courseId,
  ) async => const [];

  @override
  Future<CohortMentorReview?> submitMentorReview({
    required int courseId,
    required int mentorId,
    required int rating,
    required String comment,
  }) async => null;

  @override
  Future<CohortMentorReview?> updateMentorReview({
    required int courseId,
    required int reviewId,
    required int mentorId,
    required int rating,
    required String comment,
  }) async => null;

  @override
  Future<List<CohortComplaint>> fetchMyComplaints({String? status}) async =>
      List.of(complaints);

  @override
  Future<CohortComplaint?> submitComplaint({
    required int courseId,
    required String category,
    required String message,
    int? mentorId,
    bool refundReviewRequested = false,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    complaintCourseId = courseId;
    complaintCategory = category;
    complaintMessage = message;
    complaintKey = idempotencyKey;
    complaintRefund = refundReviewRequested;
    final created = CohortComplaint(
      id: 900,
      courseId: courseId,
      cohortId: 10,
      cohortName: 'N3 Evening Cohort',
      mentorId: mentorId,
      mentorName: null,
      category: category,
      message: message,
      status: 'Open',
      refundReviewRequested: refundReviewRequested,
      hasEvidence: evidenceBytes != null,
      mentorResponse: null,
      decision: null,
      createdAtUtc: DateTime(2026, 11, 17, 10),
      decidedAtUtc: null,
      revision: 1,
    );
    complaints.insert(0, created);
    return created;
  }

  @override
  Future<List<StudyCohortSummary>> fetchCohorts({
    int? mentorId,
    String? level,
    String? intensity,
    int? weekday,
    String? fromTime,
    String? toTime,
  }) async {
    cohortQueries.add({
      'mentorId': mentorId,
      'level': level,
      'intensity': intensity,
      'weekday': weekday,
      'fromTime': fromTime,
      'toTime': toTime,
    });
    return _cohorts();
  }

  List<StudyCohortSummary> _cohorts() => [
    StudyCohortSummary(
      id: 10,
      planId: 1,
      name: 'N3 Evening Cohort',
      mentorId: 2,
      mentorName: 'Tanaka Sensei',
      startsAt: DateTime(2026, 12, 1, 19, 0),
      endsAt: DateTime(2027, 2, 1, 20, 30),
      capacity: 4,
      enrolledCount: 2,
      seatsAvailable: 2,
      status: 'Published',
      level: 'N3',
      totalSessions: 12,
      sessionMinutes: 90,
      price: 2500000,
      enrollmentClosesAtUtc: DateTime(2026, 11, 30),
      requiresEntitlement: true,
      hasApprovedEntitlement: true,
      entitlementReference: 'ENT-C10-U9-ABCD',
      entitlementStatusMessage: null,
      myEnrollmentCourseId: null,
      myEnrollmentStatus: null,
      enrollmentOpen: true,
      sessions: const [],
      intensity: 'Standard',
      intensityLabel: 'Tiêu chuẩn',
      isRecommendedIntensity: true,
      totalTeachingHours: 18,
      sessionsPerWeek: 2,
      schedulePattern: const [
        CohortSchedulePatternItem(
          weekday: 2,
          weekdayLabel: 'Thứ 3',
          localStart: '19:00',
          localEnd: '20:30',
        ),
      ],
    ),
    StudyCohortSummary(
      id: 11,
      planId: 2,
      name: 'N2 Blocked Cohort',
      mentorId: 3,
      mentorName: 'Sato Sensei',
      startsAt: DateTime(2026, 12, 2, 19, 0),
      endsAt: DateTime(2027, 2, 2, 20, 30),
      capacity: 4,
      enrolledCount: 4,
      seatsAvailable: 0,
      status: 'Published',
      level: 'N2',
      totalSessions: 12,
      sessionMinutes: 90,
      price: 3000000,
      enrollmentClosesAtUtc: DateTime(2026, 11, 30),
      requiresEntitlement: true,
      hasApprovedEntitlement: false,
      entitlementReference: null,
      entitlementStatusMessage:
          'Bạn chưa có quyền ghi danh lớp nhóm cho lớp này.',
      myEnrollmentCourseId: null,
      myEnrollmentStatus: null,
      enrollmentOpen: false,
      sessions: const [],
    ),
  ];

  @override
  Future<List<CohortEntitlementItem>> fetchMyEntitlements() async => [
    CohortEntitlementItem(
      id: 1,
      studyCohortId: 10,
      cohortName: 'N3 Evening Cohort',
      level: 'N3',
      startsAt: DateTime(2026, 12, 1, 19, 0),
      entitlementReference: 'ENT-C10-U9-ABCD',
      sourceType: 'AdminManualGrant',
      status: 'Active',
      isUsable: true,
    ),
  ];

  @override
  Future<int> enrollCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  }) async {
    enrollCalls++;
    return 55;
  }

  @override
  Future<CohortCheckoutResult> checkoutCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  }) async {
    checkoutCalls++;
    return CohortCheckoutResult(
      courseId: 55,
      cohortId: cohortId,
      paymentStatus: 'Paid',
      status: 'Active',
    );
  }

  @override
  Future<void> reconcileCoursePayment(int courseId) async {
    reconcileCalls.add(courseId);
  }

  @override
  Future<List<LearnerStudyCourseDetail>> fetchMyCourses() async => [
    LearnerStudyCourseDetail(
      paymentState: paymentState,
      checkoutUrl: paymentState == 'AwaitingPayment'
          ? 'https://pay.example.com/checkout/1'
          : null,
      paymentExpiresAt: paymentState == 'AwaitingPayment'
          ? DateTime(2026, 11, 18, 10, 0)
          : null,
      id: 55,
      name: 'N3 Evening Cohort',
      planId: 1,
      cohortId: 10,
      sessionType: 'Group',
      level: 'N3',
      mentorId: 2,
      mentorName: 'Tanaka Sensei',
      durationMonths: 3,
      sessionsPerWeek: 2,
      totalSessions: 1,
      sessionMinutes: 90,
      amount: 0,
      paymentStatus: 'Paid',
      status: courseStatus,
      startsAt: DateTime(2026, 11, 1, 19, 0),
      endsAt: DateTime(2026, 11, 15, 20, 30),
      completedAt: DateTime(2026, 11, 16, 10, 0),
      eligibility: const CourseEligibilitySummary(
        canClaim: true,
        passedOnTimeHomework: 1,
        requiredHomework: 1,
        absentSessions: 0,
        countedSessions: 1,
        reasons: [],
      ),
      sessions: [
        CourseSessionItem(
          id: 1,
          number: 1,
          attempt: 1,
          scheduledAt: DateTime(2026, 11, 1, 19, 0),
          status: 'Present',
          meetingUrl: 'https://app.rikipath.local/meeting-room/room-10',
        ),
      ],
      requests: [
        CourseRetakeRequestItem(
          id: 7,
          status: 'Approved',
          examDate: DateTime(2026, 11, 10),
          resultPublishedAt: DateTime(2026, 11, 15),
          reason: 'Thiêu 3 điểm đọc hiểu N3',
          submittedAt: DateTime(2026, 11, 16),
          response: 'Đã kiểm tra minh chứng hợp lệ.',
          mentorSupportPlan: 'Ôn 4 đề đọc hiểu cùng Mentor trong 2 tuần.',
        ),
      ],
    ),
  ];

  @override
  Future<void> cancelCohortEnrollment({
    required int courseId,
    String? reason,
  }) async {}

  @override
  Future<List<CohortHomeworkAssignment>> fetchCohortHomework(
    int cohortId,
  ) async => [
    CohortHomeworkAssignment(
      id: 91,
      title: 'Luyện Kanji N3 Tuần 1',
      instructions: 'Viết 10 câu ví dụ.',
      status: 'Graded',
      assignmentScope: 'CohortCommon',
      cohortId: cohortId,
      submission: CohortHomeworkSubmission(
        id: 12,
        textContent: 'Bai lam N3',
        submittedAt: DateTime(2026, 11, 5),
        revisionCount: 1,
        hasScan: true,
      ),
      publishedGrade: CohortHomeworkPublishedGrade(
        passed: true,
        score: 92,
        feedback: 'Chữ viết rõ ràng, đúng ngữ pháp.',
        publishedAtUtc: DateTime(2026, 11, 6),
      ),
    ),
  ];

  @override
  Future<void> submitHomeworkText({
    required int assignmentId,
    required String textContent,
  }) async {
    submittedText = textContent;
  }

  @override
  Future<void> submitHomeworkScan({
    required int assignmentId,
    String? textContent,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {}

  @override
  Future<void> requestJlptRetake({
    required int courseId,
    required DateTime examDate,
    required DateTime resultPublishedAt,
    required String reason,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    submittedRetakeReason = reason;
  }

  @override
  Future<List<CohortTransferRequestItem>> fetchMyTransferRequests() async =>
      transfers;

  @override
  Future<CohortTransferRequestItem> requestCohortTransfer({
    required int courseId,
    int? targetCohortId,
    required String reason,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    transferCourseId = courseId;
    transferReason = reason;
    transferTarget = targetCohortId;
    transferKey = idempotencyKey;
    final created = _transfer(id: 300, status: 'Pending', reason: reason);
    transfers = [created, ...transfers];
    return created;
  }

  @override
  Future<void> withdrawCohortTransfer(int requestId) async {}
}

CohortTransferRequestItem _transfer({
  required int id,
  required String status,
  String reason = 'Đổi ca làm việc buổi tối',
  String? decisionNote,
}) => CohortTransferRequestItem(
  id: id,
  status: status,
  sourceCourseId: 55,
  sourceCohortId: 10,
  sourceCohortName: 'N3 Evening Cohort',
  requestedTargetCohortId: null,
  requestedTargetCohortName: null,
  targetCohortId: null,
  targetCohortName: null,
  reason: reason,
  hasEvidence: false,
  createdAtUtc: DateTime(2026, 11, 17, 9),
  reviewedAtUtc: null,
  decisionNote: decisionNote,
  destinationCourseId: null,
  history: [
    CohortTransferHistoryItem(
      action: 'Requested',
      actorRole: 'Learner',
      detail: 'Học viên đề nghị Admin chọn lớp phù hợp.',
      atUtc: DateTime(2026, 11, 17, 9),
    ),
  ],
);

void main() {
  testWidgets(
    'LearnerCohortsScreen enforces backend entitlement & capacity gating',
    (tester) async {
      final repo = _FakeCohortRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cohortRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const LearnerCohortsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('N3 Evening Cohort'), findsOneWidget);
      expect(find.text('N2 Blocked Cohort'), findsOneWidget);
      expect(
        find.textContaining('Bạn chưa có quyền ghi danh lớp nhóm'),
        findsOneWidget,
      );

      final blockedButton = tester.widget<RikiPrimaryButton>(
        find.byKey(const ValueKey('enroll_cohort_11')),
      );
      expect(blockedButton.onPressed, isNull);

      final openButton = tester.widget<RikiPrimaryButton>(
        find.byKey(const ValueKey('enroll_cohort_10')),
      );
      expect(openButton.onPressed, isNotNull);

      // Task 05 card details: intensity, recommended badge, pattern, hours,
      // price and Mentor review summary (empty → "Chưa có đánh giá").
      expect(find.byKey(const ValueKey('cohort_intensity_10')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cohort_recommended_10')),
        findsOneWidget,
      );
      expect(find.textContaining('Thứ 3 19:00–20:30'), findsOneWidget);
      expect(find.textContaining('Tổng 18 giờ'), findsOneWidget);
      expect(find.textContaining('2 buổi/tuần'), findsOneWidget);
      expect(
        find.textContaining('Học phí trọn khóa: 2.500.000 đ'),
        findsOneWidget,
      );
      expect(find.textContaining('4.5 · 8 đánh giá'), findsOneWidget);
      expect(find.text('Chưa có đánh giá'), findsOneWidget);
    },
  );

  testWidgets('LearnerCohortsScreen passes intensity/weekday filters to the '
      'repository query', (tester) async {
    final repo = _FakeCohortRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cohortRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const LearnerCohortsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.cohortQueries.last['intensity'], isNull);

    await tester.tap(
      find.byKey(const ValueKey('cohort_filter_intensity_Light')),
    );
    await tester.pumpAndSettle();
    expect(repo.cohortQueries.last['intensity'], 'Light');

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('cohort_filter_weekday')),
        matching: find.text('T4'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.cohortQueries.last['weekday'], 3);
    expect(repo.cohortQueries.last['intensity'], 'Light');
  });

  testWidgets(
    'LearnerCohortDetailScreen renders room link, cohort homework grade & mentor support plan',
    (tester) async {
      final repo = _FakeCohortRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cohortRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const LearnerCohortDetailScreen(courseId: 55),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('N3 Evening Cohort'), findsOneWidget);
      expect(find.text('Vào phòng'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Giao chung cả lớp'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Giao chung cả lớp'), findsOneWidget);
      expect(find.textContaining('Chữ viết rõ ràng'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Ôn 4 đề đọc hiểu cùng Mentor trong 2 tuần.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Ôn 4 đề đọc hiểu cùng Mentor trong 2 tuần.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Awaiting-payment course shows pending status, never confirmed, and reconciles on demand',
    (tester) async {
      final repo = _FakeCohortRepository(
        courseStatus: 'Pending',
        paymentState: 'AwaitingPayment',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cohortRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const LearnerCohortDetailScreen(courseId: 55),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang chờ xác nhận thanh toán'), findsOneWidget);
      expect(find.text('Đã xác nhận thanh toán'), findsNothing);

      final check = find.byKey(const Key('check_payment_55'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(repo.reconcileCalls, [55]);
    },
  );

  testWidgets(
    'Learner submits a cohort transfer REQUEST (no direct change) and sees rejection reason + history',
    (tester) async {
      final repo = _FakeCohortRepository(
        courseStatus: 'Active',
        transfers: [
          _transfer(
            id: 201,
            status: 'Rejected',
            decisionNote: 'Lớp đích đã đủ chỗ',
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cohortRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const LearnerCohortDetailScreen(courseId: 55),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final section = find.byKey(const Key('cohort_transfer_section'));
      await tester.scrollUntilVisible(
        section,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Mentor chính: Tanaka Sensei'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('transfer_rejection_201')), findsOneWidget);
      expect(find.textContaining('Lớp đích đã đủ chỗ'), findsOneWidget);
      expect(
        find.textContaining(
          'Requested: Học viên đề nghị Admin chọn lớp phù hợp.',
        ),
        findsOneWidget,
      );

      // Too-short reason is blocked client-side; server still validates.
      await tester.enterText(
        find.byKey(const Key('transfer_reason_field')),
        'ngắn',
      );
      await tester.ensureVisible(
        find.byKey(const Key('transfer_submit_button')),
      );
      await tester.tap(find.byKey(const Key('transfer_submit_button')));
      await tester.pumpAndSettle();
      expect(repo.transferReason, isNull);

      await tester.enterText(
        find.byKey(const Key('transfer_reason_field')),
        'Đổi ca làm việc nên cần học lớp tối khác',
      );
      await tester.ensureVisible(
        find.byKey(const Key('transfer_submit_button')),
      );
      await tester.tap(find.byKey(const Key('transfer_submit_button')));
      await tester.pumpAndSettle();
      expect(repo.transferCourseId, 55);
      expect(repo.transferReason, 'Đổi ca làm việc nên cần học lớp tối khác');
      expect(repo.transferTarget, isNull);
      expect(repo.transferKey, isNotNull);
      expect(
        repo.enrollCalls,
        0,
        reason: 'Transfer must never enroll directly',
      );
      expect(find.text('Chờ Admin xem xét'), findsOneWidget);
      // A pending request hides the form (one pending request per enrollment).
      expect(find.byKey(const Key('transfer_submit_button')), findsNothing);
    },
  );

  Future<void> pumpComplaintSection(
    WidgetTester tester,
    _FakeCohortRepository repo,
  ) async {
    final course = (await repo.fetchMyCourses()).first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cohortRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CohortComplaintSection(
                course: course,
                mentors: const [(id: 2, name: 'Tanaka Sensei')],
                pickEvidence: () async => null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Learner complaint submit sends category + idempotency key and lists status',
    (tester) async {
      final repo = _FakeCohortRepository(courseStatus: 'Active');
      await pumpComplaintSection(tester, repo);

      // Refund-review toggle only exists for payment/enrollment complaints.
      expect(find.byKey(const Key('complaint_refund_toggle')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('complaint_category_Schedule')),
      );
      await tester.pumpAndSettle();

      // Too-short message is blocked client-side.
      await tester.enterText(
        find.byKey(const Key('complaint_message_field')),
        'ngắn',
      );
      await tester.ensureVisible(
        find.byKey(const Key('complaint_submit_button')),
      );
      await tester.tap(find.byKey(const Key('complaint_submit_button')));
      await tester.pumpAndSettle();
      expect(repo.complaintCategory, isNull);

      await tester.enterText(
        find.byKey(const Key('complaint_message_field')),
        'Lịch học buổi 3 bị đổi mà không được báo trước',
      );
      await tester.ensureVisible(
        find.byKey(const Key('complaint_submit_button')),
      );
      await tester.tap(find.byKey(const Key('complaint_submit_button')));
      await tester.pumpAndSettle();

      expect(repo.complaintCourseId, 55);
      expect(repo.complaintCategory, 'Schedule');
      expect(
        repo.complaintMessage,
        'Lịch học buổi 3 bị đổi mà không được báo trước',
      );
      expect(repo.complaintKey, isNotNull);
      expect(
        repo.complaintKey,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(repo.complaintRefund, isFalse);
      expect(find.byKey(const ValueKey('complaint_item_900')), findsOneWidget);
      expect(find.text('Đã tiếp nhận'), findsOneWidget);
    },
  );

  testWidgets(
    'PaidUnderReview highlights the complaint form with payment category and refund review',
    (tester) async {
      final repo = _FakeCohortRepository(
        courseStatus: 'Pending',
        paymentState: 'PaidUnderReview',
      );
      await pumpComplaintSection(tester, repo);

      expect(
        find.byKey(const Key('complaint_paid_under_review_hint')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('complaint_refund_toggle')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('complaint_message_field')),
        'Đã chuyển khoản nhưng chưa được ghi danh vào lớp',
      );
      await tester.ensureVisible(
        find.byKey(const Key('complaint_submit_button')),
      );
      await tester.tap(find.byKey(const Key('complaint_submit_button')));
      await tester.pumpAndSettle();

      expect(repo.complaintCategory, 'PaymentEnrollment');
      expect(repo.complaintRefund, isTrue);
      expect(repo.complaintKey, isNotNull);
    },
  );

  testWidgets(
    'Completion summary lists teaching Mentors and states it is not an official JLPT certificate',
    (tester) async {
      final repo = _FakeCohortRepository();
      final summary = await repo.fetchCompletionSummary(55);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CohortCompletionSummaryCard(summary: summary),
            ),
          ),
        ),
      );

      expect(
        find.textContaining('không phải chứng chỉ JLPT chính thức'),
        findsOneWidget,
      );
      expect(
        find.text('Tanaka Sensei · Mentor chính · Buổi 1'),
        findsOneWidget,
      );
      expect(find.textContaining('Đã học 1/1 buổi'), findsOneWidget);
      expect(find.textContaining('Đã chấm 1'), findsOneWidget);
      // A completed course record must never be shown as a certificate.
      expect(find.textContaining('Chứng chỉ JLPT'), findsNothing);
    },
  );
}
