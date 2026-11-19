import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';

abstract interface class SubscriptionRepository {
  Future<List<SubscriptionPlanOffer>> fetchPlans();

  Future<StudyAccessStatus> fetchMyAccess();

  Future<SubscriptionCheckoutResult> purchasePlan(int planId);

  Future<String> checkPurchaseStatus(int purchaseId);
}

class ApiSubscriptionRepository implements SubscriptionRepository {
  const ApiSubscriptionRepository(this._apiClient);

  final ApiClient _apiClient;

  static Object? _unwrap(Object? raw) {
    if (raw is Map && raw.containsKey('result')) return raw['result'];
    return raw;
  }

  static Map<String, Object?> _asMap(Object? raw) {
    final unwrapped = _unwrap(raw);
    if (unwrapped is Map<String, Object?>) return unwrapped;
    if (unwrapped is Map) {
      return unwrapped.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  static int _int(Object? v, [int fallback = 0]) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;

  static double _double(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static DateTime? _date(Object? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  @override
  Future<List<SubscriptionPlanOffer>> fetchPlans() async {
    final res = await _apiClient.get<Object?>('/api/subscriptions/plans');
    final list = _unwrap(res.data);
    if (list is! Iterable) return const [];
    return list
        .whereType<Map>()
        .map((raw) {
          final m = raw.map((k, v) => MapEntry(k.toString(), v));
          return SubscriptionPlanOffer(
            id: _int(m['id']),
            name: m['name']?.toString() ?? '',
            description: m['description']?.toString(),
            price: _double(m['price']),
            durationDays: _int(m['durationDays']),
            aiUses: _int(m['aiUses'] ?? m['aiGradingQuota']),
            isPopular: m['isPopular'] == true,
            kind: m['kind']?.toString() ?? 'self_study',
          );
        })
        .toList();
  }

  @override
  Future<StudyAccessStatus> fetchMyAccess() async {
    final res = await _apiClient.get<Object?>('/api/subscriptions/me');
    final m = _asMap(res.data);
    final rawPurchases = m['purchases'];
    final purchases = rawPurchases is Iterable
        ? rawPurchases.whereType<Map>().map((raw) {
            final p = raw.map((k, v) => MapEntry(k.toString(), v));
            return PurchasedSubscriptionRecord(
              id: _int(p['id']),
              planId: _int(p['planId']),
              planName: p['planName']?.toString() ?? '',
              amountPaid: _double(p['amountPaid']),
              startDate: _date(p['startDate']),
              endDate: _date(p['endDate']),
              active: p['active'] == true,
              aiUsesRemaining: _int(p['aiUsesRemaining']),
            );
          }).toList()
        : const <PurchasedSubscriptionRecord>[];

    return StudyAccessStatus(
      active: m['active'] == true,
      planName: m['planName']?.toString(),
      speaking: m['speaking'] == true,
      writing: m['writing'] == true,
      aiGradingUsesRemaining: _int(m['aiGradingUsesRemaining']),
      speakingUsesRemaining: _int(m['speakingUsesRemaining']),
      writingUsesRemaining: _int(m['writingUsesRemaining']),
      learningPathUsesRemaining: _int(m['learningPathUsesRemaining']),
      selfStudyExpiresAt: _date(m['selfStudyExpiresAt']),
      selfStudyDaysRemaining: m['selfStudyDaysRemaining'] is num
          ? (m['selfStudyDaysRemaining'] as num).toInt()
          : null,
      purchases: purchases,
    );
  }

  @override
  Future<SubscriptionCheckoutResult> purchasePlan(int planId) async {
    final res = await _apiClient.post<Object?>(
      '/api/subscriptions/purchase',
      data: {'subscriptionPlanId': planId},
    );
    final m = _asMap(res.data);
    return SubscriptionCheckoutResult(
      purchaseId: _int(m['purchaseId']),
      checkoutUrl: m['checkoutUrl']?.toString() ?? '',
    );
  }

  @override
  Future<String> checkPurchaseStatus(int purchaseId) async {
    final res = await _apiClient.get<Object?>(
      '/api/subscriptions/purchases/$purchaseId',
    );
    final unwrapped = _unwrap(res.data);
    if (unwrapped is Map) {
      return unwrapped['status']?.toString() ?? 'Pending';
    }
    return unwrapped?.toString() ?? 'Pending';
  }
}
