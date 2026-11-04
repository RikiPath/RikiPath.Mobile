import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
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

final learnerMentorListControllerProvider =
    AsyncNotifierProvider<LearnerMentorListController, List<BookableMentor>>(
      LearnerMentorListController.new,
      retry: (_, _) => null,
    );

final learnerMentorAvailabilityControllerProvider =
    AsyncNotifierProvider<
      LearnerMentorAvailabilityController,
      List<LearnerMentorAvailability>
    >(LearnerMentorAvailabilityController.new, retry: (_, _) => null);

final learnerMentorAvailabilityByMentorControllerProvider =
    AsyncNotifierProvider.autoDispose.family<
      LearnerMentorAvailabilityByMentorController,
      List<LearnerMentorAvailability>,
      int?
    >(LearnerMentorAvailabilityByMentorController.new, retry: (_, _) => null);

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

final learnerCreditBalanceControllerProvider =
    AsyncNotifierProvider<LearnerCreditBalanceController, LearnerCreditBalance>(
      LearnerCreditBalanceController.new,
      retry: (_, _) => null,
    );

final mentorRatingSummaryControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MentorRatingSummaryController, MentorRatingSummary, int>(
      MentorRatingSummaryController.new,
      retry: (_, _) => null,
    );

final learnerDisputesControllerProvider =
    AsyncNotifierProvider<LearnerDisputesController, List<LearnerDisputeItem>>(
      LearnerDisputesController.new,
      retry: (_, _) => null,
    );

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

class LearnerMentorListController extends AsyncNotifier<List<BookableMentor>> {
  @override
  Future<List<BookableMentor>> build() {
    return ref.watch(learnerMentorRepositoryProvider).loadMentors();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<BookableMentor>>();
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

class LearnerMentorAvailabilityByMentorController
    extends AsyncNotifier<List<LearnerMentorAvailability>> {
  LearnerMentorAvailabilityByMentorController(this.mentorId);

  final int? mentorId;

  @override
  Future<List<LearnerMentorAvailability>> build() {
    final from = DateTime.now().toUtc();
    return ref
        .watch(learnerMentorRepositoryProvider)
        .loadAvailability(
          from: from,
          to: from.add(const Duration(days: 60)),
          mentorId: mentorId,
        );
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

class LearnerCreditBalanceController
    extends AsyncNotifier<LearnerCreditBalance> {
  @override
  Future<LearnerCreditBalance> build() {
    return ref.watch(learnerMentorRepositoryProvider).loadCreditBalance();
  }

  Future<void> retry() async {
    state = const AsyncLoading<LearnerCreditBalance>();
    state = await AsyncValue.guard(build);
  }
}

class MentorRatingSummaryController extends AsyncNotifier<MentorRatingSummary> {
  MentorRatingSummaryController(this.mentorId);

  final int mentorId;

  @override
  Future<MentorRatingSummary> build() {
    return ref
        .watch(learnerMentorRepositoryProvider)
        .loadMentorReviewSummary(mentorId);
  }

  Future<void> retry() async {
    state = const AsyncLoading<MentorRatingSummary>();
    state = await AsyncValue.guard(build);
  }
}

class LearnerDisputesController
    extends AsyncNotifier<List<LearnerDisputeItem>> {
  @override
  Future<List<LearnerDisputeItem>> build() {
    return ref.watch(learnerMentorRepositoryProvider).loadMyDisputes();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<LearnerDisputeItem>>();
    state = await AsyncValue.guard(build);
  }
}

class LearnerBookingIntent {
  const LearnerBookingIntent({
    this.planId,
    this.plan,
    this.subscriptionId,
    this.mentorAvailabilityId,
    this.slot,
    this.question,
    this.jlptLevel,
  });

  final int? planId;
  final MentorMeetingPlan? plan;
  final int? subscriptionId;
  final int? mentorAvailabilityId;
  final LearnerMentorAvailability? slot;
  final String? question;
  final String? jlptLevel;

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'subscriptionId': subscriptionId,
    'mentorAvailabilityId': mentorAvailabilityId,
    if (slot != null) 'slot': slot!.toJson(),
    'question': question,
    'jlptLevel': jlptLevel,
  };

  factory LearnerBookingIntent.fromJson(Map<String, dynamic> json) =>
      LearnerBookingIntent(
        planId: json['planId'] as int?,
        subscriptionId: json['subscriptionId'] as int?,
        mentorAvailabilityId: json['mentorAvailabilityId'] as int?,
        slot: json['slot'] != null
            ? LearnerMentorAvailability.fromJson(
                Map<String, dynamic>.from(json['slot'] as Map),
              )
            : null,
        question: json['question'] as String?,
        jlptLevel: json['jlptLevel'] as String?,
      );

  LearnerBookingIntent copyWith({
    int? planId,
    MentorMeetingPlan? plan,
    int? subscriptionId,
    int? mentorAvailabilityId,
    LearnerMentorAvailability? slot,
    String? question,
    String? jlptLevel,
  }) => LearnerBookingIntent(
    planId: planId ?? this.planId,
    plan: plan ?? this.plan,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    mentorAvailabilityId: mentorAvailabilityId ?? this.mentorAvailabilityId,
    slot: slot ?? this.slot,
    question: question ?? this.question,
    jlptLevel: jlptLevel ?? this.jlptLevel,
  );
}

class LearnerBookingIntentNotifier extends Notifier<LearnerBookingIntent?> {
  static const _storageKey = 'learner_booking_intent';

  @override
  LearnerBookingIntent? build() {
    _restoreFromStorage();
    return null;
  }

  Future<void> _restoreFromStorage() async {
    try {
      final store = ref.read(jsonPreferenceStoreProvider);
      final raw = await store.read(_storageKey);
      if (raw != null && raw.isNotEmpty && state == null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        state = LearnerBookingIntent.fromJson(data);
      }
    } catch (_) {
      // Bỏ qua lỗi deserialize intent cũ
    }
  }

  void setIntent(LearnerBookingIntent? intent) {
    state = intent;
    final store = ref.read(jsonPreferenceStoreProvider);
    if (intent != null) {
      try {
        store.write(_storageKey, jsonEncode(intent.toJson()));
      } catch (_) {}
    } else {
      store.remove(_storageKey);
    }
  }

  void clear() {
    state = null;
    ref.read(jsonPreferenceStoreProvider).remove(_storageKey);
  }
}

final learnerBookingIntentProvider =
    NotifierProvider<LearnerBookingIntentNotifier, LearnerBookingIntent?>(
      LearnerBookingIntentNotifier.new,
    );

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
    state = await AsyncValue.guard(() async {
      try {
        return await ref
            .read(learnerMentorRepositoryProvider)
            .syncPurchaseStatus(subscriptionId);
      } catch (_) {
        return await ref
            .read(learnerMentorRepositoryProvider)
            .loadPurchaseStatus(subscriptionId);
      }
    });
  }

  Future<void> poll() async {
    if (state.isLoading || state.value?.isSettled == true) return;
    state = await AsyncValue.guard(() async {
      try {
        return await ref
            .read(learnerMentorRepositoryProvider)
            .syncPurchaseStatus(subscriptionId);
      } catch (_) {
        return await ref
            .read(learnerMentorRepositoryProvider)
            .loadPurchaseStatus(subscriptionId);
      }
    });
  }
}

enum LearnerMentorMutationType {
  purchase,
  creditBooking,
  cancellation,
  reschedule,
  review,
  dispute,
}

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
    int? mentorAvailabilityId,
    String? idempotencyKey,
    String? jlptLevel,
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
            idempotencyKey: idempotencyKey,
            jlptLevel: jlptLevel,
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

  Future<LearnerMentorBooking?> bookWithCredit({
    required int slotId,
    required String operationKey,
    String? notes,
    String? jlptLevel,
  }) async {
    if (state.isLoading) return null;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.creditBooking,
    );
    try {
      final result = await ref
          .read(learnerMentorRepositoryProvider)
          .bookWithCredit(
            slotId: slotId,
            operationKey: operationKey,
            notes: notes,
            jlptLevel: jlptLevel,
          );
      state = LearnerMentorMutationState.bookingSuccess(result);
      ref.invalidate(learnerMentorBookingsControllerProvider);
      ref.invalidate(learnerCreditBalanceControllerProvider);
      return result;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.creditBooking,
        error,
      );
      return null;
    }
  }

  Future<bool> cancelBooking({
    required int bookingId,
    required String reason,
    bool requestException = false,
    String? exceptionReason,
  }) async {
    if (state.isLoading) return false;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.cancellation,
    );
    try {
      final ok = await ref
          .read(learnerMentorRepositoryProvider)
          .cancelBooking(
            bookingId: bookingId,
            reason: reason,
            requestException: requestException,
            exceptionReason: exceptionReason,
          );
      state = const LearnerMentorMutationState.idle();
      ref.invalidate(learnerMentorBookingsControllerProvider);
      ref.invalidate(learnerCreditBalanceControllerProvider);
      return ok;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.cancellation,
        error,
      );
      return false;
    }
  }

  Future<bool> rescheduleBooking({
    required int bookingId,
    required int newSlotId,
  }) async {
    if (state.isLoading) return false;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.reschedule,
    );
    try {
      final ok = await ref
          .read(learnerMentorRepositoryProvider)
          .rescheduleBooking(bookingId: bookingId, newSlotId: newSlotId);
      state = const LearnerMentorMutationState.idle();
      ref.invalidate(learnerMentorBookingsControllerProvider);
      return ok;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.reschedule,
        error,
      );
      return false;
    }
  }

  Future<MentorReviewItem?> createReview({
    required int bookingId,
    required int rating,
    String? comment,
    int? mentorId,
  }) async {
    if (state.isLoading) return null;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.review,
    );
    try {
      final result = await ref
          .read(learnerMentorRepositoryProvider)
          .createReview(bookingId: bookingId, rating: rating, comment: comment);
      state = const LearnerMentorMutationState.idle();
      if (mentorId != null) {
        ref.invalidate(mentorRatingSummaryControllerProvider(mentorId));
      }
      return result;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.review,
        error,
      );
      return null;
    }
  }

  Future<LearnerDisputeItem?> createDispute({
    required int bookingId,
    required int category,
    required String reason,
    String? evidenceNotes,
  }) async {
    if (state.isLoading) return null;
    state = const LearnerMentorMutationState.loading(
      LearnerMentorMutationType.dispute,
    );
    try {
      final result = await ref
          .read(learnerMentorRepositoryProvider)
          .createDispute(
            bookingId: bookingId,
            category: category,
            reason: reason,
            evidenceNotes: evidenceNotes,
          );
      state = const LearnerMentorMutationState.idle();
      ref.invalidate(learnerDisputesControllerProvider);
      return result;
    } catch (error) {
      state = LearnerMentorMutationState.failure(
        LearnerMentorMutationType.dispute,
        error,
      );
      return null;
    }
  }

  void reset() => state = const LearnerMentorMutationState.idle();
}
