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
    AsyncNotifierProvider<
      LearnerMentorListController,
      List<BookableMentor>
    >(LearnerMentorListController.new, retry: (_, _) => null);

final learnerMentorAvailabilityControllerProvider =
    AsyncNotifierProvider<
      LearnerMentorAvailabilityController,
      List<LearnerMentorAvailability>
    >(LearnerMentorAvailabilityController.new, retry: (_, _) => null);

final learnerMentorAvailabilityByMentorControllerProvider = AsyncNotifierProvider
    .autoDispose
    .family<
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

class LearnerMentorListController
    extends AsyncNotifier<List<BookableMentor>> {
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
    return ref.watch(learnerMentorRepositoryProvider).loadAvailability(
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

class LearnerBookingIntent {
  const LearnerBookingIntent({
    this.planId,
    this.plan,
    this.subscriptionId,
    this.mentorAvailabilityId,
    this.slot,
    this.question,
  });

  final int? planId;
  final MentorMeetingPlan? plan;
  final int? subscriptionId;
  final int? mentorAvailabilityId;
  final LearnerMentorAvailability? slot;
  final String? question;

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'subscriptionId': subscriptionId,
    'mentorAvailabilityId': mentorAvailabilityId,
    if (slot != null) 'slot': slot!.toJson(),
    'question': question,
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
      );

  LearnerBookingIntent copyWith({
    int? planId,
    MentorMeetingPlan? plan,
    int? subscriptionId,
    int? mentorAvailabilityId,
    LearnerMentorAvailability? slot,
    String? question,
  }) => LearnerBookingIntent(
    planId: planId ?? this.planId,
    plan: plan ?? this.plan,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    mentorAvailabilityId: mentorAvailabilityId ?? this.mentorAvailabilityId,
    slot: slot ?? this.slot,
    question: question ?? this.question,
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
    int? mentorAvailabilityId,
    String? idempotencyKey,
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
    String? question,
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
            question: question,
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
