import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_result_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_live_mock_data.dart';

void main() {
  test(
    'local review and fixture test controllers contain no live submit path',
    () {
      final source = File(
        'lib/features/practice/application/demo_practice_controller.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('/api/Review/submit-result')));
      expect(source, isNot(contains('ReviewApiPaths')));
      expect(source, isNot(contains('MockTestApiPaths')));
      expect(source, isNot(contains('ApiClient')));
    },
  );

  testWidgets('live result opens backend detailed review and keeps IDs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = createTestAuthSession();
    final router = createAppRouter(
      authSession: session,
      initialLocation: AppRoutes.practice,
    );
    final repository = TestLiveMockTestRepository();
    final container = ProviderContainer(
      overrides: [
        mockTestRepositoryProvider.overrideWithValue(repository),
        userProfileRepositoryProvider.overrideWithValue(
          const TestMockProfileRepository(),
        ),
      ],
    );
    addTearDown(session.dispose);
    addTearDown(router.dispose);
    addTearDown(container.dispose);

    await container.read(mockTestControllerProvider.future);
    final controller = container.read(mockTestControllerProvider.notifier);
    controller.selectTest(testLiveMockSummary.id);
    await controller.startSelectedTest();
    controller.selectAnswer(1201, 4402);
    await controller.submit();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go(AppRoutes.mockTestResult(testLiveMockSummary.id.toString()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MockTestResultScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('mock_test_result_view')),
      findsOneWidget,
    );
    final reviewButton = find.byKey(
      const ValueKey<String>('mock_detailed_review_button'),
    );
    await tester.scrollUntilVisible(reviewButton, 200);
    tester.widget<RikiPrimaryButton>(reviewButton).onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MockTestDetailedReviewScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('mock_detailed_review_view')),
      findsOneWidget,
    );
    expect(
      container
          .read(mockTestControllerProvider)
          .requireValue
          .attempt!
          .answers[1201],
      4402,
    );

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MockTestResultScreen), findsOneWidget);
  });
}
