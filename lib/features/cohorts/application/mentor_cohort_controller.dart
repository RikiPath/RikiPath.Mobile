import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/cohorts/data/mentor_cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

/// Cohorts the signed-in Mentor is assigned to (primary or substitute).
final mentorAssignedCohortsProvider =
    FutureProvider.autoDispose<List<StudyCohortSummary>>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(mentorCohortRepositoryProvider).fetchAssignedCohorts();
    });

/// One assigned cohort by id, derived from the assigned list.
final mentorCohortByIdProvider = FutureProvider.autoDispose
    .family<StudyCohortSummary?, int>((ref, cohortId) async {
      final cohorts = await ref.watch(mentorAssignedCohortsProvider.future);
      return cohorts.where((c) => c.id == cohortId).firstOrNull;
    });

final mentorCohortRosterProvider = FutureProvider.autoDispose
    .family<List<MentorCohortRosterEntry>, int>((ref, cohortId) async {
      return ref.watch(mentorCohortRepositoryProvider).fetchRoster(cohortId);
    });

final mentorCohortHomeworkProvider = FutureProvider.autoDispose
    .family<List<MentorCohortHomeworkItem>, int>((ref, cohortId) async {
      return ref
          .watch(mentorCohortRepositoryProvider)
          .fetchCohortHomework(cohortId);
    });

final mentorCohortAssignmentsProvider = FutureProvider.autoDispose
    .family<List<CohortMentorAssignment>, int>((ref, cohortId) async {
      return ref
          .watch(mentorCohortRepositoryProvider)
          .fetchMentorAssignments(cohortId);
    });

/// Complaints targeting the signed-in Mentor (all cohorts). Screens filter
/// by cohort locally.
final mentorCohortComplaintsProvider =
    FutureProvider.autoDispose<List<CohortComplaint>>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(mentorCohortRepositoryProvider).fetchComplaints();
    });

final mentorCohortScheduleRequestsProvider = FutureProvider.autoDispose
    .family<List<CohortScheduleRequest>, int>((ref, cohortId) async {
      return ref
          .watch(mentorCohortRepositoryProvider)
          .fetchScheduleRequests(cohortId);
    });

final mentorCohortShiftPreviewProvider = FutureProvider.autoDispose
    .family<CohortShiftPreview, ({int cohortId, int weeks})>((ref, args) async {
      return ref
          .watch(mentorCohortRepositoryProvider)
          .fetchShiftPreview(cohortId: args.cohortId, weeks: args.weeks);
    });

final mentorLearnerSkillProfileProvider = FutureProvider.autoDispose
    .family<MentorLearnerSkillProfile, ({int learnerId, int cohortId})>((
      ref,
      args,
    ) async {
      return ref
          .watch(mentorCohortRepositoryProvider)
          .fetchLearnerSkillProfile(
            learnerId: args.learnerId,
            cohortId: args.cohortId,
          );
    });

final mentorHomeworkCatalogProvider = FutureProvider.autoDispose
    .family<List<HomeworkCatalogItem>, ({String? level, String? search})>((
      ref,
      args,
    ) async {
      ref.watch(authenticatedUserIdProvider);
      return ref
          .watch(mentorCohortRepositoryProvider)
          .fetchHomeworkCatalog(level: args.level, search: args.search);
    });

final mentorCohortActionsProvider = Provider<MentorCohortActions>((ref) {
  return MentorCohortActions(ref);
});

/// Mutations for the Mentor cohort screens; each refreshes the providers it
/// affects so the UI always reflects the server state.
class MentorCohortActions {
  const MentorCohortActions(this._ref);

  final Ref _ref;

  MentorCohortRepository get _repo => _ref.read(mentorCohortRepositoryProvider);

  Future<void> createCohortHomework({
    required int cohortId,
    required String title,
    String? instructions,
    DateTime? dueAt,
    List<int> lessonIds = const [],
    List<int> practiceExerciseIds = const [],
    List<int>? targetLearnerIds,
  }) async {
    await _repo.createCohortHomework(
      cohortId: cohortId,
      title: title,
      instructions: instructions,
      dueAt: dueAt,
      lessonIds: lessonIds,
      practiceExerciseIds: practiceExerciseIds,
      targetLearnerIds: targetLearnerIds,
    );
    _ref.invalidate(mentorCohortHomeworkProvider(cohortId));
  }

  Future<({Uint8List bytes, String contentType})> downloadHomeworkScan(
    int assignmentId,
  ) => _repo.downloadHomeworkScan(assignmentId);

  Future<MentorHomeworkAiDraft> generateHomeworkAiDraft(int assignmentId) =>
      _repo.generateHomeworkAiDraft(assignmentId);

  Future<void> publishHomeworkGrade({
    required int cohortId,
    required int assignmentId,
    required int submissionId,
    required double score,
    required String feedback,
  }) async {
    await _repo.publishHomeworkGrade(
      assignmentId: assignmentId,
      submissionId: submissionId,
      score: score,
      feedback: feedback,
    );
    _ref.invalidate(mentorCohortHomeworkProvider(cohortId));
  }

  Future<void> confirmSessionAttendance({
    required int cohortId,
    required int courseId,
    required int sessionId,
    required String status,
    required String note,
  }) async {
    await _repo.confirmSessionAttendance(
      courseId: courseId,
      sessionId: sessionId,
      status: status,
      note: note,
    );
    _ref.invalidate(mentorAssignedCohortsProvider);
    _ref.invalidate(mentorCohortRosterProvider(cohortId));
  }

  Future<void> saveRetakeSupportPlan({
    required int cohortId,
    required int courseId,
    required int requestId,
    required String supportPlan,
  }) async {
    await _repo.saveRetakeSupportPlan(
      courseId: courseId,
      requestId: requestId,
      supportPlan: supportPlan,
    );
    _ref.invalidate(mentorCohortRosterProvider(cohortId));
  }

  Future<void> respondToComplaint({
    required int complaintId,
    required String response,
  }) async {
    await _repo.respondToComplaint(
      complaintId: complaintId,
      response: response,
    );
    _ref.invalidate(mentorCohortComplaintsProvider);
  }

  Future<CohortScheduleRequest?> createScheduleRequest({
    required int cohortId,
    required String kind,
    int? shiftWeeks,
    required String reason,
    required String idempotencyKey,
  }) async {
    final created = await _repo.createScheduleRequest(
      cohortId: cohortId,
      kind: kind,
      shiftWeeks: shiftWeeks,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );
    _ref.invalidate(mentorCohortScheduleRequestsProvider(cohortId));
    return created;
  }

  Future<void> withdrawScheduleRequest({
    required int cohortId,
    required int requestId,
  }) async {
    await _repo.withdrawScheduleRequest(requestId);
    _ref.invalidate(mentorCohortScheduleRequestsProvider(cohortId));
  }

  void refreshCohort(int cohortId) {
    _ref.invalidate(mentorAssignedCohortsProvider);
    _ref.invalidate(mentorCohortRosterProvider(cohortId));
    _ref.invalidate(mentorCohortHomeworkProvider(cohortId));
    _ref.invalidate(mentorCohortAssignmentsProvider(cohortId));
    _ref.invalidate(mentorCohortComplaintsProvider);
    _ref.invalidate(mentorCohortScheduleRequestsProvider(cohortId));
  }
}
