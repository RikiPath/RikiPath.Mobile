import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';

final mentorOperationsRepositoryProvider = Provider<MentorOperationsRepository>(
  (ref) => ApiMentorOperationsRepository(ref.watch(apiClientProvider)),
);

/// Full booking detail provider (`GET /api/mentor-bookings/{bookingId}`).
final mentorBookingDetailProvider =
    FutureProvider.autoDispose.family<MentorBookingDetail, int>((
      ref,
      bookingId,
    ) {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(mentorOperationsRepositoryProvider).loadBookingDetail(
            bookingId,
          );
    }, retry: (_, _) => null);

/// Cancellation policy eligibility (`GET /api/mentor-bookings/{bookingId}/cancellation-eligibility`).
final mentorCancellationEligibilityProvider =
    FutureProvider.autoDispose.family<MentorCancellationEligibility, int>((
      ref,
      bookingId,
    ) {
      ref.watch(authenticatedUserIdProvider);
      return ref
          .watch(mentorOperationsRepositoryProvider)
          .checkCancellationEligibility(bookingId);
    }, retry: (_, _) => null);

/// Booking attendance telemetry (`GET /api/mentor-meetings/bookings/{bookingId}/attendance`).
final mentorBookingAttendanceProvider =
    FutureProvider.autoDispose.family<List<MentorAttendanceRecord>, int>((
      ref,
      bookingId,
    ) {
      ref.watch(authenticatedUserIdProvider);
      return ref
          .watch(mentorOperationsRepositoryProvider)
          .loadBookingAttendance(bookingId);
    }, retry: (_, _) => null);

/// Room readiness / access check (`GET /api/mentor-meetings/rooms/{roomId}/access`).
final mentorRoomAccessProvider =
    FutureProvider.autoDispose.family<MentorRoomAccessStatus, String>((
      ref,
      roomId,
    ) {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(mentorOperationsRepositoryProvider).checkRoomAccess(
            roomId,
          );
    }, retry: (_, _) => null);

/// Combined Reviews + Rating Summary bundle for the logged-in Mentor.
class MentorReviewsBundle {
  const MentorReviewsBundle({
    required this.mentorId,
    required this.summary,
    required this.reviews,
    this.hasMore = false,
  });

  final int mentorId;
  final MentorRatingSummary summary;
  final List<MentorReviewItem> reviews;
  final bool hasMore;
}

final mentorReviewsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MentorReviewsController,
      MentorReviewsBundle
    >(MentorReviewsController.new, retry: (_, _) => null);

class MentorReviewsController extends AsyncNotifier<MentorReviewsBundle> {
  static const int _pageSize = 20;
  int _currentPage = 1;

  @override
  Future<MentorReviewsBundle> build() async {
    ref.watch(authenticatedUserIdProvider);
    final profile = await ref.watch(mentorProfileControllerProvider.future);
    final ops = ref.watch(mentorOperationsRepositoryProvider);
    _currentPage = 1;
    final results = await Future.wait([
      ops.loadRatingSummary(profile.mentorId),
      ops.loadReviews(profile.mentorId, page: 1, pageSize: _pageSize),
    ]);
    final summary = results[0] as MentorRatingSummary;
    final reviews = results[1] as List<MentorReviewItem>;
    return MentorReviewsBundle(
      mentorId: profile.mentorId,
      summary: summary,
      reviews: reviews,
      hasMore: reviews.length >= _pageSize,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore) return;
    final ops = ref.read(mentorOperationsRepositoryProvider);
    final nextPage = _currentPage + 1;
    final nextItems = await ops.loadReviews(
      current.mentorId,
      page: nextPage,
      pageSize: _pageSize,
    );
    _currentPage = nextPage;
    final existingIds = current.reviews.map((r) => r.id).toSet();
    final merged = [
      ...current.reviews,
      ...nextItems.where((r) => !existingIds.contains(r.id)),
    ];
    state = AsyncData(
      MentorReviewsBundle(
        mentorId: current.mentorId,
        summary: current.summary,
        reviews: merged,
        hasMore: nextItems.length >= _pageSize,
      ),
    );
  }

  Future<bool> replyToReview({
    required int reviewId,
    required String reply,
  }) async {
    final ok = await ref
        .read(mentorMeetingsControllerProvider.notifier)
        .replyReview(reviewId, reply);
    if (ok) {
      ref.invalidateSelf();
    }
    return ok;
  }
}

final mentorDisputesControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MentorDisputesController,
      List<MentorDisputeItem>
    >(MentorDisputesController.new, retry: (_, _) => null);

class MentorDisputesController extends AsyncNotifier<List<MentorDisputeItem>> {
  @override
  Future<List<MentorDisputeItem>> build() async {
    ref.watch(authenticatedUserIdProvider);
    return ref.watch(mentorOperationsRepositoryProvider).loadDisputes(
          page: 1,
          pageSize: 50,
        );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final mentorDisputeDetailProvider =
    FutureProvider.autoDispose.family<MentorDisputeDetail, int>((
      ref,
      disputeId,
    ) {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(mentorOperationsRepositoryProvider).loadDisputeDetail(
            disputeId,
          );
    }, retry: (_, _) => null);
