import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';

final learnerMentorRepositoryProvider = Provider<LearnerMentorRepository>(
  (ref) => ApiLearnerMentorRepository(ref.watch(apiClientProvider)),
);

final learnerMentorPlansControllerProvider =
    AsyncNotifierProvider<
      LearnerMentorPlansController,
      List<MentorMeetingPlan>
    >(LearnerMentorPlansController.new, retry: (_, _) => null);

final learnerMentorAvailabilityControllerProvider =
    AsyncNotifierProvider<
      LearnerMentorAvailabilityController,
      List<LearnerMentorAvailability>
    >(LearnerMentorAvailabilityController.new, retry: (_, _) => null);

final learnerMentorBookingsControllerProvider =
    AsyncNotifierProvider<
      LearnerMentorBookingsController,
      List<LearnerMentorBooking>
    >(LearnerMentorBookingsController.new, retry: (_, _) => null);

final learnerMentorPurchaseStatusControllerProvider = AsyncNotifierProvider
    .autoDispose
    .family<
      LearnerMentorPurchaseStatusController,
      MentorMeetingPurchaseStatus,
      int
    >(LearnerMentorPurchaseStatusController.new, retry: (_, _) => null);

final learnerMentorMutationControllerProvider =
    NotifierProvider<
      LearnerMentorMutationController,
      LearnerMentorMutationState
    >(LearnerMentorMutationController.new);

class LearnerMentorPlansController
    extends AsyncNotifier<List<MentorMeetingPlan>> {
  @override
  Future<List<MentorMeetingPlan>> build() {
    return ref.watch(learnerMentorRepositoryProvider).loadPlans();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<MentorMeetingPlan>>();
    state = await AsyncValue.guard(build);
  }
}

class LearnerMentorAvailabilityController
    extends AsyncNotifier<List<LearnerMentorAvailability>> {
  @override
  Future<List<LearnerMentorAvailability>> build() {
    final from = DateTime.now().toUtc();
    return ref
        .watch(learnerMentorRepositoryProvider)
        .loadAvailability(from: from, to: from.add(const Duration(days: 30)));
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<LearnerMentorAvailability>>();
    state = await AsyncValue.guard(build);
  }
}

class LearnerMentorBookingsController
    extends AsyncNotifier<List<LearnerMentorBooking>> {
  @override
  Future<List<LearnerMentorBooking>> build() {
    return ref.watch(learnerMentorRepositoryProvider).loadBookings();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<LearnerMentorBooking>>();
    state = await AsyncValue.guard(build);
  }
}

class LearnerMentorPurchaseStatusController
    extends AsyncNotifier<MentorMeetingPurchaseStatus> {
  LearnerMentorPurchaseStatusController(this.subscriptionId);

  final int subscriptionId;

  @override
  Future<MentorMeetingPurchaseStatus> build() {
    if (subscriptionId <= 0) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Must be positive',
      );
    }
    return ref
        .watch(learnerMentorRepositoryProvider)
        .loadPurchaseStatus(subscriptionId);
  }

  Future<void> refreshStatus() async {
    state = const AsyncLoading<MentorMeetingPurchaseStatus>();
    state = await AsyncValue.guard(build);
  }

  Future<void> poll() async {
    if (state.isLoading || state.value?.isSettled == true) return;
    state = await AsyncValue.guard(build);
  }
}

enum LearnerMentorMutationType { purchase, includedBooking }

class LearnerMentorMutationState {
  const LearnerMentorMutationState._({
    this.type,
    this.purchase,
    this.booking,
    this.error,
  });

  const LearnerMentorMutationState.idle() : this._();

  const LearnerMentorMutationState.loading(LearnerMentorMutationType type)
    : this._(type: type);

  const LearnerMentorMutationState.purchaseSuccess(
    MentorMeetingPurchase purchase,
  ) : this._(purchase: purchase);

  const LearnerMentorMutationState.bookingSuccess(LearnerMentorBooking booking)
    : this._(booking: booking);

  const LearnerMentorMutationState.failure(
    LearnerMentorMutationType type,
    Object error,
  ) : this._(type: type, error: error);

  final LearnerMentorMutationType? type;
  final MentorMeetingPurchase? purchase;
  final LearnerMentorBooking? booking;
  final Object? error;

  bool get isLoading => type != null && error == null;
}

class LearnerMentorMutationController
    extends Notifier<LearnerMentorMutationState> {
  @override
  LearnerMentorMutationState build() => const LearnerMentorMutationState.idle();

  Future<MentorMeetingPurchase?> purchase({
    required int subscriptionPlanId,
    required int mentorAvailabilityId,
  }) async {
    if (state.isLoading) return null;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.purchase,
    );
    try {
      final result = await ref
          .read(learnerMentorRepositoryProvider)
          .purchase(
            subscriptionPlanId: subscriptionPlanId,
            mentorAvailabilityId: mentorAvailabilityId,
          );
      state = LearnerMentorMutationState.purchaseSuccess(result);
      return result;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.purchase,
        error,
      );
      return null;
    }
  }

  Future<LearnerMentorBooking?> bookIncludedSession({
    required int subscriptionId,
    required int mentorAvailabilityId,
  }) async {
    if (state.isLoading) return null;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.includedBooking,
    );
    try {
      final result = await ref
          .read(learnerMentorRepositoryProvider)
          .bookIncludedSession(
            subscriptionId: subscriptionId,
            mentorAvailabilityId: mentorAvailabilityId,
          );
      state = LearnerMentorMutationState.bookingSuccess(result);
      ref.invalidate(learnerMentorBookingsControllerProvider);
      ref.invalidate(
        learnerMentorPurchaseStatusControllerProvider(subscriptionId),
      );
      return result;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.includedBooking,
        error,
      );
      return null;
    }
  }

  void reset() => state = const LearnerMentorMutationState.idle();
}
