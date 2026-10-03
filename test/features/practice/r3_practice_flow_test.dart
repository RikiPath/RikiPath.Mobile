import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_result_screen.dart';

import '../../support/test_auth_session.dart';

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

  testWidgets('mock result opens detailed review and keeps local answers', (
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
    final container = ProviderContainer();
    addTearDown(session.dispose);
    addTearDown(router.dispose);
    addTearDown(container.dispose);

    await container.read(demoPracticeControllerProvider.future);
    final controller = container.read(demoPracticeControllerProvider.notifier);
    final fixture = container
        .read(demoPracticeControllerProvider)
        .requireValue
        .mockTest;
    controller.startMockTest();
    controller.selectMockAnswer(
      fixture.questions.first.id,
      fixture.questions.first.correctOptionId,
    );
    controller.submitMockTest();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go(AppRoutes.mockTestResult(fixture.id));
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
          .read(demoPracticeControllerProvider)
          .requireValue
          .mockAnswers[fixture.questions.first.id],
      fixture.questions.first.correctOptionId,
    );

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MockTestResultScreen), findsOneWidget);
  });
}
