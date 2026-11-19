import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/subscriptions/application/subscription_controller.dart';
import 'package:rikipath_mobile/features/subscriptions/data/subscription_repository.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';
import 'package:rikipath_mobile/features/subscriptions/presentation/subscriptions_screen.dart';

void main() {
  group('Subscriptions Feature Tests', () {
    test('isSubscriptionOrAiGateError matches documented Backend codes', () {
      expect(
        isSubscriptionOrAiGateError(
          const ForbiddenError(errorCode: 'SELF_STUDY_PACKAGE_REQUIRED'),
        ),
        isTrue,
      );
      expect(
        isSubscriptionOrAiGateError(
          const ForbiddenError(errorCode: 'AI_CREDIT_REQUIRED'),
        ),
        isTrue,
      );
      expect(
        isSubscriptionOrAiGateError(
          const ForbiddenError(errorCode: 'WRITING_PACKAGE_REQUIRED'),
        ),
        isTrue,
      );
      expect(
        isSubscriptionOrAiGateError(
          const ConflictError(errorCode: 'HOMEWORK_SUBMISSION_CHANGED'),
        ),
        isFalse,
      );
    });

    test(
      'ApiSubscriptionRepository parses plans, access, purchase and status',
      () async {
        final calls = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add('${options.method} ${options.path}');
              if (options.path == '/api/subscriptions/plans') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': [
                        <String, Object?>{
                          'id': 1,
                          'name': 'Gói AI Tổng hợp',
                          'description': 'Full AI + Self study',
                          'price': 199000,
                          'durationDays': 30,
                          'aiUses': 50,
                          'isPopular': true,
                          'kind': 'self_study',
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              if (options.path == '/api/subscriptions/me') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{
                        'active': true,
                        'planName': 'Gói AI Tổng hợp',
                        'speaking': true,
                        'writing': true,
                        'aiGradingUsesRemaining': 12,
                        'speakingUsesRemaining': 5,
                        'writingUsesRemaining': 5,
                        'learningPathUsesRemaining': 2,
                        'selfStudyDaysRemaining': 28,
                        'purchases': const <Object?>[],
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path == '/api/subscriptions/purchase') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{
                        'purchaseId': 401,
                        'checkoutUrl': 'https://pay.payos.vn/web/401',
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path == '/api/subscriptions/purchases/401') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{'status': 'Paid'},
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final repo = ApiSubscriptionRepository(
          ApiClient(dio, const ApiErrorMapper()),
        );
        final plans = await repo.fetchPlans();
        final access = await repo.fetchMyAccess();
        final checkout = await repo.purchasePlan(1);
        final status = await repo.checkPurchaseStatus(checkout.purchaseId);

        expect(plans.single.name, 'Gói AI Tổng hợp');
        expect(plans.single.aiUses, 50);
        expect(access.active, isTrue);
        expect(access.aiGradingUsesRemaining, 12);
        expect(checkout.purchaseId, 401);
        expect(checkout.checkoutUrl, 'https://pay.payos.vn/web/401');
        expect(status, 'Paid');
        expect(calls, hasLength(4));
      },
    );

    testWidgets(
      'SubscriptionsScreen renders active access status and available plans',
      (tester) async {
        final fakeRepo = _FakeSubscriptionRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: const SubscriptionsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gói Pro N3'), findsWidgets);
        expect(find.text('199.000đ'), findsOneWidget);
        expect(find.textContaining('Gói Luyện Viết'), findsOneWidget);
      },
    );
  });
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlanOffer>> fetchPlans() async => const [
    SubscriptionPlanOffer(
      id: 9,
      name: 'Gói Luyện Viết AI',
      description: 'Quét ảnh OCR & chấm viết JLPT',
      price: 199000,
      durationDays: 30,
      aiUses: 20,
      isPopular: true,
      kind: 'writing',
    ),
  ];

  @override
  Future<StudyAccessStatus> fetchMyAccess() async => const StudyAccessStatus(
    active: true,
    planName: 'Gói Pro N3',
    speaking: true,
    writing: false,
    aiGradingUsesRemaining: 10,
    speakingUsesRemaining: 5,
    writingUsesRemaining: 0,
    learningPathUsesRemaining: 2,
    selfStudyDaysRemaining: 18,
    purchases: [],
  );

  @override
  Future<SubscriptionCheckoutResult> purchasePlan(int planId) async =>
      const SubscriptionCheckoutResult(
        purchaseId: 55,
        checkoutUrl: 'https://pay.payos.vn/web/55',
      );

  @override
  Future<String> checkPurchaseStatus(int purchaseId) async => 'Paid';
}
