import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/data/cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/data/mentor_cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/mentor_cohort_sheets.dart';

void main() {
  group('Learner payment reconcile & cancel pending enrollment', () {
    test(
      'reconcilePayment posts exact path and reloads my courses',
      () async {
        final calls = <String>[];
        var reconciled = false;
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add('${options.method} ${options.path}');
              if (options.method == 'POST' &&
                  options.path == '/api/study-courses/77/payment/reconcile') {
                reconciled = true;
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{'isSuccess': true},
                  ),
                );
                return;
              }
              if (options.method == 'GET' &&
                  options.path == '/api/study-courses') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': [
                        <String, Object?>{
                          'id': 77,
                          'studyCoursePlanId': 1,
                          'title': 'JLPT N5 Lớp Sáng',
                          'mentorId': 5,
                          'mentorName': 'Tanaka',
                          'durationMonths': 3,
                          'sessionsPerWeek': 3,
                          'totalSessions': 30,
                          'sessionMinutes': 90,
                          'amount': 2000000,
                          'paymentStatus': reconciled ? 'Paid' : 'Pending',
                          'status': reconciled ? 'Active' : 'Pending',
                          'eligibility': <String, Object?>{
                            'canClaim': false,
                            'passedOnTimeHomework': 0,
                            'requiredHomework': 1,
                            'absentSessions': 0,
                            'countedSessions': 0,
                            'reasons': const <String>[],
                          },
                          'sessions': const <Object?>[],
                          'requests': const <Object?>[],
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final container = ProviderContainer(
          overrides: [
            cohortRepositoryProvider.overrideWithValue(
              ApiCohortRepository(ApiClient(dio, const ApiErrorMapper())),
            ),
          ],
        );
        addTearDown(container.dispose);

        final initial = await container.read(learnerMyCoursesProvider.future);
        expect(initial.single.status, 'Pending');

        await container
            .read(learnerMyCoursesProvider.notifier)
            .reconcilePayment(77);

        final refreshed = await container.read(learnerMyCoursesProvider.future);
        expect(refreshed.single.status, 'Active');
        expect(
          calls,
          contains('POST /api/study-courses/77/payment/reconcile'),
        );
      },
    );

    test(
      'cancelPendingEnrollment posts exact cancel-pending-enrollment path',
      () async {
        final calls = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add('${options.method} ${options.path}');
              if (options.method == 'POST' &&
                  options.path ==
                      '/api/study-courses/77/cancel-pending-enrollment') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{'isSuccess': true},
                  ),
                );
                return;
              }
              if (options.method == 'GET' &&
                  options.path == '/api/study-courses') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': const <Object?>[],
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final container = ProviderContainer(
          overrides: [
            cohortRepositoryProvider.overrideWithValue(
              ApiCohortRepository(ApiClient(dio, const ApiErrorMapper())),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(learnerMyCoursesProvider.future);
        await container
            .read(learnerMyCoursesProvider.notifier)
            .cancelPendingEnrollment(77);

        expect(
          calls,
          contains('POST /api/study-courses/77/cancel-pending-enrollment'),
        );
      },
    );
  });

  group('Mentor Cohort Operation Sheets', () {
    StudyCohortSummary sampleCohort() {
      final start = DateTime.now().subtract(const Duration(hours: 2));
      return StudyCohortSummary(
        id: 20,
        planId: 3,
        name: 'N4 Lớp Chiều',
        mentorId: 7,
        mentorName: 'Yamada',
        startsAt: start,
        endsAt: start.add(const Duration(days: 70)),
        capacity: 4,
        enrolledCount: 1,
        seatsAvailable: 3,
        status: 'Active',
        level: 'N4',
        totalSessions: 20,
        sessionMinutes: 90,
        price: 1500000,
        enrollmentClosesAtUtc: start,
        requiresEntitlement: false,
        hasApprovedEntitlement: false,
        entitlementReference: null,
        entitlementStatusMessage: null,
        myEnrollmentCourseId: null,
        myEnrollmentStatus: null,
        enrollmentOpen: true,
        sessions: [
          CohortSessionSlot(
            number: 1,
            availabilityId: 10,
            roomId: 'room-20',
            startTime: start,
            endTime: start.add(const Duration(minutes: 90)),
            status: 'Scheduled',
          ),
        ],
      );
    }

    testWidgets(
      'MentorSessionAttendanceSheet submits chosen status and note',
      (tester) async {
        final repo = _FakeOpsMentorRepository();
        final cohort = sampleCohort();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [mentorCohortRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: Scaffold(
                body: MentorSessionAttendanceSheet(
                  cohort: cohort,
                  slot: cohort.sessions.single,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('att_5001_ExcusedAbsent')));
        await tester.enterText(
          find.byKey(const ValueKey('att_note_5001')),
          'Học viên xin phép nghỉ trước buổi',
        );
        await tester.tap(find.byKey(const ValueKey('att_submit_5001')));
        await tester.pumpAndSettle();

        expect(repo.attendanceCall, (
          courseId: 101,
          sessionId: 5001,
          status: 'ExcusedAbsent',
          note: 'Học viên xin phép nghỉ trước buổi',
        ));
      },
    );

    testWidgets(
      'MentorCreateHomeworkSheet submits title and selected catalog lesson',
      (tester) async {
        final repo = _FakeOpsMentorRepository();
        final cohort = sampleCohort();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [mentorCohortRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: Scaffold(body: MentorCreateHomeworkSheet(cohort: cohort)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('hw_title_field')),
          'Bài tập tuần 1',
        );
        await tester.tap(find.text('Bài 1: Chào hỏi'));
        await tester.ensureVisible(find.byKey(const Key('hw_create_submit')));
        await tester.tap(find.byKey(const Key('hw_create_submit')));
        await tester.pumpAndSettle();

        expect(repo.createdTitle, 'Bài tập tuần 1');
        expect(repo.createdLessonIds, <int>[12]);
      },
    );

    testWidgets(
      'MentorHomeworkGradingSheet preserves draft on AI fallback and 409 submission conflict',
      (tester) async {
        final repo = _FakeOpsMentorRepository(
          aiError: const ServerError(
            statusCode: 503,
            errorCode: 'HOMEWORK_AI_DRAFT_UNAVAILABLE',
            message: 'AI tạm gián đoạn',
          ),
          publishErrorOnFirstCall: const ConflictError(
            errorCode: 'HOMEWORK_SUBMISSION_CHANGED',
            message: 'Submission changed',
          ),
        );
        final item = MentorCohortHomeworkItem(
          id: 90,
          title: 'Bài viết tuần 2',
          status: 'Submitted',
          assignmentScope: 'CohortCommon',
          rows: [
            MentorCohortHomeworkRow(
              id: 90,
              title: 'Bài viết tuần 2',
              learnerId: 501,
              learnerName: 'Nguyễn An',
              status: 'Submitted',
              assignmentScope: 'CohortCommon',
              submission: CohortHomeworkSubmission(
                id: 301,
                textContent: '日本語を勉強しています。',
                submittedAt: DateTime(2026, 11, 17, 10, 0),
                revisionCount: 1,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [mentorCohortRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: Scaffold(
                body: MentorHomeworkGradingSheet(cohortId: 20, initialItem: item),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Trigger AI/OCR draft fallback (non-blocking).
        await tester.tap(find.byKey(const ValueKey('hw_ai_draft_90')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Bạn vẫn có thể tự nhập điểm & nhận xét'),
          findsOneWidget,
        );

        // 2. Mentor types manual draft and gets 409 HOMEWORK_SUBMISSION_CHANGED.
        await tester.enterText(find.byKey(const ValueKey('hw_score_90')), '88');
        await tester.enterText(
          find.byKey(const ValueKey('hw_feedback_90')),
          'Chú ý chia thể động từ tự nhiên hơn',
        );
        await tester.tap(find.byKey(const ValueKey('hw_publish_grade_90')));
        await tester.pumpAndSettle();

        // Draft fields remain intact after 409!
        expect(find.text('88'), findsOneWidget);
        expect(find.text('Chú ý chia thể động từ tự nhiên hơn'), findsOneWidget);

        // 3. Re-submit succeeds after 409 refresh.
        await tester.tap(find.byKey(const ValueKey('hw_publish_grade_90')));
        await tester.pumpAndSettle();
        expect(repo.publishedCalls, 1);
        expect(repo.lastScore, 88.0);
        expect(repo.lastFeedback, 'Chú ý chia thể động từ tự nhiên hơn');
      },
    );

    testWidgets(
      'HOMEWORK_AI_DRAFT_UNAVAILABLE invalidates mentorCohortHomeworkProvider',
      (tester) async {
        final initialItem =
            (await _FakeOpsMentorRepository().fetchCohortHomework(20)).first;
        final repo = _AiUnavailableOpsMentorRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [mentorCohortRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: Scaffold(
                body: MentorHomeworkGradingSheet(
                  cohortId: 20,
                  initialItem: initialItem,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fetchesBeforeTap = repo.homeworkFetchCount;
        await tester.tap(find.byKey(const ValueKey('hw_ai_draft_90')));
        await tester.pumpAndSettle();

        expect(repo.homeworkFetchCount, greaterThan(fetchesBeforeTap));
      },
    );
  });
}

class _AiUnavailableOpsMentorRepository extends _FakeOpsMentorRepository {
  _AiUnavailableOpsMentorRepository()
    : super(
        aiError: const ServerError(
          statusCode: 503,
          errorCode: 'HOMEWORK_AI_DRAFT_UNAVAILABLE',
          message: 'AI tạm gián đoạn',
        ),
      );

  int homeworkFetchCount = 0;

  @override
  Future<List<MentorCohortHomeworkItem>> fetchCohortHomework(
    int cohortId,
  ) async {
    homeworkFetchCount += 1;
    return super.fetchCohortHomework(cohortId);
  }
}

class _FakeOpsMentorRepository implements MentorCohortRepository {
  _FakeOpsMentorRepository({this.aiError, this.publishErrorOnFirstCall});

  final Object? aiError;
  final Object? publishErrorOnFirstCall;
  var _publishAttemptedOnce = false;
  int publishedCalls = 0;
  double? lastScore;
  String? lastFeedback;
  ({int courseId, int sessionId, String status, String note})? attendanceCall;
  String? createdTitle;
  List<int> createdLessonIds = const [];

  @override
  Future<List<StudyCohortSummary>> fetchAssignedCohorts() async => const [];

  @override
  Future<List<MentorCohortRosterEntry>> fetchRoster(int cohortId) async => [
    MentorCohortRosterEntry(
      courseId: 101,
      learnerId: 501,
      learnerName: 'Nguyễn An',
      status: 'Active',
      sessions: [
        CourseSessionItem(
          id: 5001,
          number: 1,
          attempt: 1,
          scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'Scheduled',
        ),
      ],
    ),
  ];

  @override
  Future<List<MentorCohortHomeworkItem>> fetchCohortHomework(
    int cohortId,
  ) async => [
    MentorCohortHomeworkItem(
      id: 90,
      title: 'Bài viết tuần 2',
      status: 'Submitted',
      assignmentScope: 'CohortCommon',
      rows: [
        MentorCohortHomeworkRow(
          id: 90,
          title: 'Bài viết tuần 2',
          learnerId: 501,
          learnerName: 'Nguyễn An',
          status: 'Submitted',
          assignmentScope: 'CohortCommon',
          submission: CohortHomeworkSubmission(
            id: 301,
            textContent: '日本語を勉強しています。',
            submittedAt: DateTime(2026, 11, 17, 10, 0),
            revisionCount: 2,
          ),
        ),
      ],
    ),
  ];

  @override
  Future<List<HomeworkCatalogItem>> fetchHomeworkCatalog({
    String? level,
    String? search,
  }) async => const [
    HomeworkCatalogItem(
      type: 'lesson',
      id: 12,
      title: 'Bài 1: Chào hỏi',
      level: 'N4',
      skill: 'Vocabulary',
    ),
  ];

  @override
  Future<void> createCohortHomework({
    required int cohortId,
    required String title,
    String? instructions,
    DateTime? dueAt,
    List<int> lessonIds = const [],
    List<int> practiceExerciseIds = const [],
    List<int>? targetLearnerIds,
  }) async {
    createdTitle = title;
    createdLessonIds = lessonIds;
  }

  @override
  Future<({Uint8List bytes, String contentType})> downloadHomeworkScan(
    int assignmentId,
  ) async => (bytes: Uint8List(0), contentType: 'image/png');

  @override
  Future<MentorHomeworkAiDraft> generateHomeworkAiDraft(
    int assignmentId,
  ) async {
    if (aiError != null) throw aiError!;
    return const MentorHomeworkAiDraft(suggestedScore: 90, feedback: 'Tốt');
  }

  @override
  Future<void> publishHomeworkGrade({
    required int assignmentId,
    required int submissionId,
    required double score,
    required String feedback,
  }) async {
    if (publishErrorOnFirstCall != null && !_publishAttemptedOnce) {
      _publishAttemptedOnce = true;
      throw publishErrorOnFirstCall!;
    }
    publishedCalls++;
    lastScore = score;
    lastFeedback = feedback;
  }

  @override
  Future<void> confirmSessionAttendance({
    required int courseId,
    required int sessionId,
    required String status,
    required String note,
  }) async {
    attendanceCall = (
      courseId: courseId,
      sessionId: sessionId,
      status: status,
      note: note,
    );
  }

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
  }) async =>
      MentorLearnerSkillProfile(learnerId: learnerId, learnerName: 'An');

  @override
  Future<List<CohortMentorAssignment>> fetchMentorAssignments(
    int cohortId,
  ) async => const [];

  @override
  Future<List<CohortComplaint>> fetchComplaints({String? status}) async =>
      const [];

  @override
  Future<void> respondToComplaint({
    required int complaintId,
    required String response,
  }) async {}

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
  }) async => null;

  @override
  Future<void> withdrawScheduleRequest(int requestId) async {}
}
