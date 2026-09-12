import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';

import '../../support/test_auth_session.dart';

void main() {
  test('learner JLPT choices are typed and limited to N5, N4, and N3', () {
    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
    ]);
    expect(JlptLevel.values.map((level) => level.label), <String>[
      'N5',
      'N4',
      'N3',
    ]);
  });

  test('daily study choices are exactly 15, 30, 45, and 60 minutes', () {
    expect(DailyStudyTime.values.map((choice) => choice.minutes), <int>[
      15,
      30,
      45,
      60,
    ]);
  });

  testWidgets('target step shows only N5, N4, and N3 choices', (tester) async {
    await _pumpOnboarding(tester);

    expect(find.byKey(const ValueKey<String>('jlpt_n5')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('jlpt_n4')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('jlpt_n3')), findsOneWidget);
    expect(find.text('N1'), findsNothing);
    expect(find.text('N2'), findsNothing);
  });

  testWidgets('continue is disabled before a JLPT target is selected', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    final button = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a JLPT target stores the typed level', (tester) async {
    final harness = await _pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey<String>('jlpt_n4')));
    await tester.pump();

    expect(
      harness.container.read(onboardingControllerProvider).selectedJlptLevel,
      JlptLevel.n4,
    );
  });

  testWidgets('continue advances from target to study-time selection', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n5);

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.studyTime);
    expect(find.text('Bạn muốn học bao lâu mỗi ngày?'), findsOneWidget);
  });

  testWidgets('study-time step displays all four supported choices', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);

    for (final minutes in <int>[15, 30, 45, 60]) {
      expect(find.text('$minutes phút/ngày'), findsOneWidget);
    }
  });

  testWidgets('completion is disabled until study time is selected', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);

    final button = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('back from study time preserves both selections', (tester) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n4);
    await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
    await tester.pump();

    await tester.tap(find.byTooltip('Quay lại bước chọn mục tiêu'));
    await tester.pump();

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.jlptTarget);
    expect(state.selectedJlptLevel, JlptLevel.n4);
    expect(state.selectedStudyTime, DailyStudyTime.fortyFive);
  });

  testWidgets('completion summary uses the selected JLPT target', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n5,
      studyTime: DailyStudyTime.thirty,
    );

    expect(find.text('Mục tiêu JLPT N5'), findsOneWidget);
    expect(find.text('Mục tiêu JLPT N3'), findsNothing);
  });

  testWidgets('completion summary uses the selected daily study time', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n4,
      studyTime: DailyStudyTime.sixty,
    );

    expect(find.text('60 phút/ngày · Chuyên sâu'), findsOneWidget);
    expect(find.text('30 phút/ngày · Cân bằng'), findsNothing);
  });

  testWidgets('back from completion keeps choices and returns to study time', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n3,
      studyTime: DailyStudyTime.fifteen,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.studyTime);
    expect(state.selectedJlptLevel, JlptLevel.n3);
    expect(state.selectedStudyTime, DailyStudyTime.fifteen);
  });

  testWidgets('start action navigates to home inside the learner shell', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n4,
      studyTime: DailyStudyTime.fortyFive,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_start_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_start_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
  });

  testWidgets('onboarding route stays outside the learner tab shell', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });
}

class _OnboardingHarness {
  const _OnboardingHarness({required this.container});

  final ProviderContainer container;
}

Future<_OnboardingHarness> _pumpOnboarding(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.onboarding,
  );
  addTearDown(container.dispose);
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _OnboardingHarness(container: container);
}

Future<void> _reachStudyTime(WidgetTester tester, JlptLevel level) async {
  await tester.tap(find.byKey(ValueKey<String>('jlpt_${level.name}')));
  await tester.pump();
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.pumpAndSettle();
}

Future<void> _reachCompletion(
  WidgetTester tester, {
  required JlptLevel level,
  required DailyStudyTime studyTime,
}) async {
  await _reachStudyTime(tester, level);
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('study_time_${studyTime.minutes}')),
  );
  await tester.tap(
    find.byKey(ValueKey<String>('study_time_${studyTime.minutes}')),
  );
  await tester.pump();
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('onboarding_complete_button')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_complete_button')),
  );
  await tester.pumpAndSettle();
}
