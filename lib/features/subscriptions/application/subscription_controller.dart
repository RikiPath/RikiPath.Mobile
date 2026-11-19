import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/subscriptions/data/subscription_repository.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => ApiSubscriptionRepository(ref.watch(apiClientProvider)),
);

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanOffer>>((ref) {
      return ref.watch(subscriptionRepositoryProvider).fetchPlans();
    });

final studyAccessProvider = FutureProvider.autoDispose<StudyAccessStatus>((
  ref,
) {
  ref.watch(authenticatedUserIdProvider);
  return ref.watch(subscriptionRepositoryProvider).fetchMyAccess();
});

final subscriptionActionsProvider = Provider<SubscriptionActions>(
  (ref) => SubscriptionActions(ref),
);

class SubscriptionActions {
  const SubscriptionActions(this._ref);

  final Ref _ref;

  Future<SubscriptionCheckoutResult> purchasePlan(int planId) async {
    final checkout = await _ref
        .read(subscriptionRepositoryProvider)
        .purchasePlan(planId);
    _ref.invalidate(studyAccessProvider);
    return checkout;
  }

  Future<String> checkPurchaseStatus(int purchaseId) async {
    final status = await _ref
        .read(subscriptionRepositoryProvider)
        .checkPurchaseStatus(purchaseId);
    if (status == 'Paid' || status == 'Failed') {
      _ref.invalidate(studyAccessProvider);
    }
    return status;
  }
}
