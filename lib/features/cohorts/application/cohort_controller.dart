import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/cohorts/data/cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

class CohortDiscoveryData {
  const CohortDiscoveryData({
    required this.cohorts,
    required this.entitlements,
  });

  final List<StudyCohortSummary> cohorts;
  final List<CohortEntitlementItem> entitlements;
}

final learnerCohortDiscoveryProvider =
    AsyncNotifierProvider<LearnerCohortDiscoveryController, CohortDiscoveryData>(
      LearnerCohortDiscoveryController.new,
    );

final learnerMyCoursesProvider =
    AsyncNotifierProvider<LearnerMyCoursesController, List<LearnerStudyCourseDetail>>(
      LearnerMyCoursesController.new,
    );

final learnerCohortHomeworkProvider = FutureProvider.autoDispose
    .family<List<CohortHomeworkAssignment>, int>((ref, cohortId) async {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(cohortRepositoryProvider).fetchCohortHomework(cohortId);
    });

final learnerTransferRequestsProvider =
    FutureProvider.autoDispose<List<CohortTransferRequestItem>>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(cohortRepositoryProvider).fetchMyTransferRequests();
    });

/// Active server-side discovery filters (intensity, weekday, time, Mentor,
/// level). Changing it reloads [learnerCohortDiscoveryProvider].
final learnerCohortFilterProvider =
    NotifierProvider<LearnerCohortFilterController, CohortDiscoveryFilter>(
      LearnerCohortFilterController.new,
    );

class LearnerCohortFilterController extends Notifier<CohortDiscoveryFilter> {
  @override
  CohortDiscoveryFilter build() => const CohortDiscoveryFilter();

  void setFilter(CohortDiscoveryFilter filter) => state = filter;

  void clear() => state = const CohortDiscoveryFilter();
}

/// Public cohort review summary per Mentor (average, count, comments).
final learnerMentorReviewSummaryProvider = FutureProvider.autoDispose
    .family<MentorCohortReviewSummary, int>((ref, mentorId) async {
      return ref
          .watch(cohortRepositoryProvider)
          .fetchMentorReviewSummary(mentorId);
    });

final learnerCompletionSummaryProvider = FutureProvider.autoDispose
    .family<CohortCompletionSummary, int>((ref, courseId) async {
      return ref.watch(cohortRepositoryProvider).fetchCompletionSummary(courseId);
    });

final learnerCourseMentorReviewsProvider = FutureProvider.autoDispose
    .family<List<CohortMentorReview>, int>((ref, courseId) async {
      return ref
          .watch(cohortRepositoryProvider)
          .fetchCourseMentorReviews(courseId);
    });

/// The learner's own complaints (all courses); screens filter by course.
final learnerComplaintsProvider =
    FutureProvider.autoDispose<List<CohortComplaint>>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(cohortRepositoryProvider).fetchMyComplaints();
    });

String generateClientIdempotencyKey() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int n) => n.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class LearnerCohortDiscoveryController
    extends AsyncNotifier<CohortDiscoveryData> {
  @override
  Future<CohortDiscoveryData> build() {
    ref.watch(authenticatedUserIdProvider);
    return _load(
      ref.watch(cohortRepositoryProvider),
      ref.watch(learnerCohortFilterProvider),
    );
  }

  Future<CohortDiscoveryData> _load(
    CohortRepository repo,
    CohortDiscoveryFilter filter,
  ) async {
    final cohortsFuture = repo.fetchCohorts(
      mentorId: filter.mentorId,
      level: filter.level,
      intensity: filter.intensity,
      weekday: filter.weekday,
      fromTime: filter.fromTime,
      toTime: filter.toTime,
    );
    final entitlementsFuture = repo.fetchMyEntitlements();
    return CohortDiscoveryData(
      cohorts: await cohortsFuture,
      entitlements: await entitlementsFuture,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<CohortDiscoveryData>();
    state = await AsyncValue.guard(
      () => _load(
        ref.read(cohortRepositoryProvider),
        ref.read(learnerCohortFilterProvider),
      ),
    );
  }

  Future<int> enrollCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  }) async {
    final courseId = await ref
        .read(cohortRepositoryProvider)
        .enrollCohort(
          cohortId: cohortId,
          idempotencyKey: idempotencyKey,
          entitlementReference: entitlementReference,
        );
    ref.invalidateSelf();
    ref.invalidate(learnerMyCoursesProvider);
    return courseId;
  }

  Future<CohortCheckoutResult> checkoutCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  }) async {
    final result = await ref
        .read(cohortRepositoryProvider)
        .checkoutCohort(
          cohortId: cohortId,
          idempotencyKey: idempotencyKey,
          entitlementReference: entitlementReference,
        );
    ref.invalidateSelf();
    ref.invalidate(learnerMyCoursesProvider);
    return result;
  }
}

class LearnerMyCoursesController
    extends AsyncNotifier<List<LearnerStudyCourseDetail>> {
  @override
  Future<List<LearnerStudyCourseDetail>> build() {
    ref.watch(authenticatedUserIdProvider);
    return ref.watch(cohortRepositoryProvider).fetchMyCourses();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<LearnerStudyCourseDetail>>();
    state = await AsyncValue.guard(
      () => ref.read(cohortRepositoryProvider).fetchMyCourses(),
    );
  }

  Future<void> reconcilePayment(int courseId) async {
    await ref.read(cohortRepositoryProvider).reconcileCoursePayment(courseId);
    ref.invalidate(learnerCohortDiscoveryProvider);
    await refresh();
  }

  Future<void> cancelPendingEnrollment(int courseId) async {
    await ref.read(cohortRepositoryProvider).cancelPendingEnrollment(courseId);
    ref.invalidate(learnerCohortDiscoveryProvider);
    await refresh();
  }

  Future<({Uint8List bytes, String contentType})> downloadHomeworkScan(
    int assignmentId,
  ) => ref.read(cohortRepositoryProvider).downloadHomeworkScan(assignmentId);

  Future<({Uint8List bytes, String contentType})> downloadTransferEvidence(
    int requestId,
  ) => ref.read(cohortRepositoryProvider).downloadTransferEvidence(requestId);

  Future<({Uint8List bytes, String contentType})> downloadRetakeEvidence({
    required int courseId,
    required int requestId,
  }) => ref
      .read(cohortRepositoryProvider)
      .downloadRetakeEvidence(courseId: courseId, requestId: requestId);

  Future<void> cancelCohortEnrollment({
    required int courseId,
    String? reason,
  }) async {
    await ref
        .read(cohortRepositoryProvider)
        .cancelCohortEnrollment(courseId: courseId, reason: reason);
    ref.invalidateSelf();
    ref.invalidate(learnerCohortDiscoveryProvider);
  }

  Future<void> submitHomeworkText({
    required int cohortId,
    required int assignmentId,
    required String textContent,
  }) async {
    await ref
        .read(cohortRepositoryProvider)
        .submitHomeworkText(
          assignmentId: assignmentId,
          textContent: textContent,
        );
    ref.invalidate(learnerCohortHomeworkProvider(cohortId));
  }

  Future<void> submitHomeworkScan({
    required int cohortId,
    required int assignmentId,
    String? textContent,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    await ref
        .read(cohortRepositoryProvider)
        .submitHomeworkScan(
          assignmentId: assignmentId,
          textContent: textContent,
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
        );
    ref.invalidate(learnerCohortHomeworkProvider(cohortId));
  }

  Future<void> requestJlptRetake({
    required int courseId,
    required DateTime examDate,
    required DateTime resultPublishedAt,
    required String reason,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    await ref
        .read(cohortRepositoryProvider)
        .requestJlptRetake(
          courseId: courseId,
          examDate: examDate,
          resultPublishedAt: resultPublishedAt,
          reason: reason,
          evidenceBytes: evidenceBytes,
          evidenceFileName: evidenceFileName,
          evidenceContentType: evidenceContentType,
        );
    ref.invalidateSelf();
  }

  /// Gửi YÊU CẦU chuyển lớp (Admin duyệt); không đổi ghi danh trực tiếp.
  Future<void> requestCohortTransfer({
    required int courseId,
    int? targetCohortId,
    required String reason,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    await ref
        .read(cohortRepositoryProvider)
        .requestCohortTransfer(
          courseId: courseId,
          targetCohortId: targetCohortId,
          reason: reason,
          idempotencyKey: idempotencyKey,
          evidenceBytes: evidenceBytes,
          evidenceFileName: evidenceFileName,
          evidenceContentType: evidenceContentType,
        );
    ref.invalidate(learnerTransferRequestsProvider);
  }

  Future<void> withdrawCohortTransfer(int requestId) async {
    await ref.read(cohortRepositoryProvider).withdrawCohortTransfer(requestId);
    ref.invalidate(learnerTransferRequestsProvider);
  }

  /// Creates or (when [reviewId] is set) updates a cohort Mentor review.
  Future<void> saveMentorReview({
    required int courseId,
    required int mentorId,
    int? reviewId,
    required int rating,
    required String comment,
  }) async {
    final repo = ref.read(cohortRepositoryProvider);
    if (reviewId != null) {
      await repo.updateMentorReview(
        courseId: courseId,
        reviewId: reviewId,
        mentorId: mentorId,
        rating: rating,
        comment: comment,
      );
    } else {
      await repo.submitMentorReview(
        courseId: courseId,
        mentorId: mentorId,
        rating: rating,
        comment: comment,
      );
    }
    ref.invalidate(learnerCourseMentorReviewsProvider(courseId));
    ref.invalidate(learnerMentorReviewSummaryProvider(mentorId));
  }

  Future<void> submitComplaint({
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
    await ref
        .read(cohortRepositoryProvider)
        .submitComplaint(
          courseId: courseId,
          category: category,
          message: message,
          mentorId: mentorId,
          refundReviewRequested:
              category == CohortComplaintCategory.paymentEnrollment &&
              refundReviewRequested,
          idempotencyKey: idempotencyKey,
          evidenceBytes: evidenceBytes,
          evidenceFileName: evidenceFileName,
          evidenceContentType: evidenceContentType,
        );
    ref.invalidate(learnerComplaintsProvider);
  }
}
