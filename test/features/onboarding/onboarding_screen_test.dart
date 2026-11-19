import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_loading.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/onboarding/domain/jlpt_exam_session.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/widgets/sakura_animated_step_progress.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/widgets/sakura_learning_plan_preview.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  test('edit wizard prefills every persisted goal field and version', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingControllerProvider.notifier).startEditFromProfile(
      currentStudyLevel: testJlptCatalog[0],
      targetLevel: testJlptCatalog[2],
      dailyMinutes: 60,
      targetExamDate: DateTime(2030, 12, 1),
      certifiedJlptLevel: testJlptCatalog[1],
      goalVersion: 7,
    );
    final state = container.read(onboardingControllerProvider);
    expect(state.isEditing, isTrue);
    expect(state.selectedCurrentStudyLevel?.id, 101);
    expect(state.selectedJlptLevel?.id, 309);
    expect(state.dailyStudyMinutes, 60);
    expect(state.targetExamDate, DateTime(2030, 12, 1));
    expect(state.certifiedJlptLevel?.id, 204);
    expect(state.expectedGoalVersion, 7);
  });

  testWidgets('certificate checkbox requires a JLPT level and can be cleared', (tester) async {
    final harness = await _pumpOnboarding(tester);
    await _selectCurrentAndTarget(tester, JlptLevel.n5, JlptLevel.n4);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('onboarding_has_certificate')));
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_has_certificate')));
    await tester.pumpAndSettle();
    expect(harness.container.read(onboardingControllerProvider).canContinueTargetLevel, isFalse);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('certified_level_n5')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey<String>('certified_level_n5')));
    await tester.pump();
    expect(harness.container.read(onboardingControllerProvider).certifiedJlptLevel?.id, 101);
    harness.container.read(onboardingControllerProvider.notifier).setHasJlptCertificate(false);
    expect(harness.container.read(onboardingControllerProvider).certifiedJlptLevel, isNull);
  });

  test('learner JLPT choices support N5 through N1', () {
    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
      JlptLevel.n2,
      JlptLevel.n1,
    ]);
    expect(JlptLevel.values.map((level) => level.label), <String>[
      'N5',
      'N4',
      'N3',
      'N2',
      'N1',
    ]);
  });

  test('daily study choices match the Web 15 through 90 minute set', () {
    expect(DailyStudyTime.values.map((choice) => choice.minutes), <int>[
      15,
      30,
      45,
      60,
      90,
    ]);
  });

  testWidgets(
    'target step follows the live N5 through N2 catalog (excluding N1)',
    (tester) async {
      await _pumpOnboarding(tester);

      expect(
        find.byKey(const ValueKey<String>('current_level_n5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('current_level_n4')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('current_level_n3')),
        findsOneWidget,
      );
      await _advanceToTarget(tester);
      expect(find.byKey(const ValueKey<String>('jlpt_n5')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('jlpt_n4')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('jlpt_n3')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('jlpt_n2')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('jlpt_n1')), findsNothing);
    },
  );

  testWidgets('Placement Test call to action is localized in Japanese', (
    tester,
  ) async {
    await _pumpOnboarding(tester, locale: const Locale('ja'));

    expect(find.text('現在のレベルがまだ分かりませんか？'), findsOneWidget);
    expect(
      find.text('レベル診断テストを受けて、あなたに合ったJLPT目標レベルの提案を受け取りましょう。'),
      findsOneWidget,
    );
    expect(find.text('入門レベル診断を受ける'), findsOneWidget);

    await _advanceToTarget(tester);
    expect(find.text('現在のレベルがまだ分かりませんか？'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('onboarding_placement_test_button')),
      findsNothing,
    );
  });

  testWidgets('Placement Test call to action is localized in Vietnamese', (
    tester,
  ) async {
    await _pumpOnboarding(tester, locale: const Locale('vi'));

    expect(
      find.byKey(
        const ValueKey<String>('onboarding_placement_guidance_section'),
      ),
      findsOneWidget,
    );
    expect(find.text('Chưa rõ trình độ hiện tại?'), findsOneWidget);
    expect(
      find.text(
        'Làm bài kiểm tra đánh giá năng lực đầu vào để nhận đề xuất cấp độ JLPT phù hợp.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kiểm tra trình độ đầu vào'), findsOneWidget);

    await _advanceToTarget(tester);
    expect(find.text('Chưa rõ trình độ hiện tại?'), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('onboarding_placement_guidance_section'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_placement_test_button')),
      findsNothing,
    );
  });

  testWidgets('continue is disabled before a JLPT target is selected', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    final button = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    expect(button.onPressed, isNull);
    await _advanceToTarget(tester);
    final targetButton = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    expect(targetButton.onPressed, isNull);
  });

  testWidgets('selecting a JLPT target stores the typed level', (tester) async {
    final harness = await _pumpOnboarding(tester);

    await _selectCurrentAndTarget(tester, JlptLevel.n5, JlptLevel.n4);

    expect(
      harness.container
          .read(onboardingControllerProvider)
          .selectedJlptLevel
          ?.level,
      JlptLevel.n4,
    );
  });

  testWidgets(
    'steps 1 to 4 and back transitions make zero API calls and show no loading overlay',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      final initialProfileLoads = harness.profileRepository.loadCalls;

      void expectNoRequestsOrOverlay() {
        expect(
          harness.container.read(onboardingControllerProvider).isSubmitting,
          isFalse,
        );
        final overlay = tester.widget<AppLoadingOverlay>(
          find.byType(AppLoadingOverlay),
        );
        expect(overlay.visible, isFalse);
        expect(find.text('Đang tạo lộ trình'), findsNothing);
        expect(find.text('Đang lưu thông tin'), findsNothing);
        expect(harness.profileRepository.loadCalls, initialProfileLoads);
        expect(harness.profileRepository.goalCalls, 0);
        expect(harness.profileRepository.studyLevelCalls, 0);
        expect(harness.profileRepository.clearCalls, 0);
        expect(harness.placementRepository.loadStatusCalls, 0);
        expect(harness.placementRepository.skipCalls, 0);
        expect(harness.learningPathRepository.totalCalls, 0);
      }

      expectNoRequestsOrOverlay();

      // Step 1 -> Step 2
      await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pump();
      expectNoRequestsOrOverlay();
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.targetLevel,
      );
      expectNoRequestsOrOverlay();

      // Step 2 -> Step 3
      await tester.tap(find.byKey(const ValueKey<String>('jlpt_n4')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pump();
      expectNoRequestsOrOverlay();
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.studyTime,
      );
      expect(find.text('Mỗi ngày, bạn muốn học bao lâu?'), findsOneWidget);
      expectNoRequestsOrOverlay();

      // Step 3 -> Step 4
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study_time_45')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await tester.pump();
      expectNoRequestsOrOverlay();
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.examPlan,
      );
      expectNoRequestsOrOverlay();

      // Back 4 -> 3 -> 2 -> 1 preserves choices and calls zero APIs
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pump();
      expectNoRequestsOrOverlay();
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.studyTime,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pump();
      expectNoRequestsOrOverlay();
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.targetLevel,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pump();
      expectNoRequestsOrOverlay();
      await tester.pumpAndSettle();
      final state = harness.container.read(onboardingControllerProvider);
      expect(state.currentStep, OnboardingStep.currentLevel);
      expect(state.selectedCurrentStudyLevel?.level, JlptLevel.n5);
      expect(state.selectedJlptLevel?.level, JlptLevel.n4);
      expect(state.selectedStudyTime, DailyStudyTime.fortyFive);
      expectNoRequestsOrOverlay();
    },
  );

  testWidgets(
    'completing step 4 saves goal, records SKIPPED once, and triggers zero AI calls',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      await _reachExamPlan(
        tester,
        level: JlptLevel.n4,
        studyTime: DailyStudyTime.thirty,
      );

      expect(harness.profileRepository.goalCalls, 0);
      expect(harness.placementRepository.loadStatusCalls, 0);
      expect(harness.placementRepository.skipCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      expect(harness.profileRepository.goalCalls, 1);
      expect(harness.placementRepository.loadStatusCalls, 1);
      expect(harness.placementRepository.skipCalls, 1);
      expect(harness.learningPathRepository.totalCalls, 0);
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.complete,
      );
      expect(
        harness.container
            .read(onboardingControllerProvider)
            .placementDecisionRecorded,
        isTrue,
      );
    },
  );

  testWidgets('completed Placement is not overwritten when completing step 4', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    harness.placementRepository.status = const PlacementTestStatus(
      hasCompletedPlacementTest: true,
      placementDecision: PlacementDecision.completed,
    );
    await _reachExamPlan(
      tester,
      level: JlptLevel.n4,
      studyTime: DailyStudyTime.thirty,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    await tester.pumpAndSettle();

    expect(harness.profileRepository.goalCalls, 1);
    expect(harness.placementRepository.loadStatusCalls, 1);
    expect(harness.placementRepository.skipCalls, 0);
    expect(harness.learningPathRepository.totalCalls, 0);
    expect(
      harness.container.read(onboardingControllerProvider).currentStep,
      OnboardingStep.complete,
    );
  });

  testWidgets(
    'partial save at step 4 keeps learner on exam plan and retries placement sync cleanly',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      harness.placementRepository.skipFails = true;

      await _reachExamPlan(
        tester,
        level: JlptLevel.n4,
        studyTime: DailyStudyTime.thirty,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      final partialState = harness.container.read(onboardingControllerProvider);
      expect(partialState.currentStep, OnboardingStep.examPlan);
      expect(partialState.isSubmitting, isFalse);
      expect(partialState.placementSkipFailed, isTrue);
      expect(partialState.goalSavedPendingPlacementSync, isTrue);
      expect(harness.profileRepository.goalCalls, 1);
      expect(harness.placementRepository.skipCalls, 1);
      expect(
        find.byKey(
          const ValueKey<String>('onboarding_placement_skip_error_banner'),
        ),
        findsOneWidget,
      );

      // Retrying without editing skips re-saving goal and finishes placement sync.
      harness.placementRepository.skipFails = false;
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      final finalState = harness.container.read(onboardingControllerProvider);
      expect(finalState.currentStep, OnboardingStep.complete);
      expect(finalState.placementSkipFailed, isFalse);
      expect(finalState.goalSavedPendingPlacementSync, isFalse);
      expect(harness.profileRepository.goalCalls, 1);
      expect(harness.placementRepository.skipCalls, 2);
      expect(harness.learningPathRepository.totalCalls, 0);
    },
  );

  testWidgets(
    'editing choice after partial save failure clears pending sync flag and saves updated goal',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      harness.placementRepository.skipFails = true;

      await _reachExamPlan(
        tester,
        level: JlptLevel.n4,
        studyTime: DailyStudyTime.thirty,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.container
            .read(onboardingControllerProvider)
            .goalSavedPendingPlacementSync,
        isTrue,
      );
      expect(harness.profileRepository.goalCalls, 1);

      // Go back to Step 3 and change study minutes to 60.
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study_time_60')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('study_time_60')));
      await tester.pump();
      expect(
        harness.container
            .read(onboardingControllerProvider)
            .goalSavedPendingPlacementSync,
        isFalse,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await tester.pumpAndSettle();

      harness.placementRepository.skipFails = false;
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      expect(harness.profileRepository.goalCalls, 2);
      expect(harness.profileRepository.savedDailyMinutes, 60);
      expect(harness.profileRepository.savedExpectedVersion, 1);
      expect(harness.placementRepository.skipCalls, 2);
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.complete,
      );
    },
  );

  testWidgets('continue advances from target to study-time selection', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n5);

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.studyTime);
    expect(find.text('Mỗi ngày, bạn muốn học bao lâu?'), findsOneWidget);
  });

  testWidgets('study-time step displays all five supported choices', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);

    for (final minutes in <int>[15, 30, 45, 60, 90]) {
      expect(find.text('$minutes phút/ngày'), findsOneWidget);
    }
    expect(find.text('Nhẹ nhàng'), findsOneWidget);
    expect(find.text('Cân bằng'), findsOneWidget);
    expect(find.text('Tích cực'), findsOneWidget);
    expect(find.text('Chuyên sâu'), findsOneWidget);
    expect(find.text('Chuyên tâm'), findsOneWidget);
    expect(find.text('Thời gian tùy chỉnh'), findsOneWidget);
    expect(
      find.text('Từ 1 đến 1.440 phút theo giới hạn hồ sơ.'),
      findsNothing,
    );

    final iconTypes = tester
        .widgetList<SakuraColorfulIcon>(find.byType(SakuraColorfulIcon))
        .map((icon) => icon.type)
        .toList();
    expect(iconTypes, <SakuraColorfulIconType>[
      SakuraColorfulIconType.studySprout,
      SakuraColorfulIconType.studyBalance,
      SakuraColorfulIconType.studyFlame,
      SakuraColorfulIconType.studyBook,
      SakuraColorfulIconType.studyLightning,
      SakuraColorfulIconType.studyCustomClock,
    ]);
  });

  testWidgets('continuation is disabled until study time is selected', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);

    final button = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('custom daily minutes obey the backend profile range', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);
    expect(
      find.byKey(const ValueKey<String>('onboarding_custom_minutes_panel')),
      findsNothing,
    );
    final customCard = find.byKey(const ValueKey<String>('study_time_custom'));
    await tester.ensureVisible(customCard);
    await tester.tap(customCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('onboarding_custom_minutes_panel')),
      findsOneWidget,
    );
    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    await tester.enterText(field, '120');
    await tester.pump();
    expect(
      harness.container.read(onboardingControllerProvider).dailyStudyMinutes,
      120,
    );
    expect(
      harness.container.read(onboardingControllerProvider).canComplete,
      isTrue,
    );
    await tester.enterText(field, '1441');
    await tester.pump();
    expect(
      harness.container.read(onboardingControllerProvider).canComplete,
      isFalse,
    );
    expect(find.text('Vui lòng nhập từ 1 đến 1.440 phút.'), findsOneWidget);
  });

  testWidgets(
    'custom daily minutes persist across back and next and submit to backend',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      await _reachStudyTime(tester, JlptLevel.n4);
      final customCard = find.byKey(
        const ValueKey<String>('study_time_custom'),
      );
      await tester.ensureVisible(customCard);
      await tester.tap(customCard);
      await tester.pumpAndSettle();
      final field = find.byType(TextFormField);
      await tester.ensureVisible(field);
      await tester.enterText(field, '75');
      await tester.pump();

      await tester.tap(find.byTooltip('Quay lại bước chọn mục tiêu'));
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.targetLevel,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.studyTime,
      );
      expect(
        harness.container.read(onboardingControllerProvider).dailyStudyMinutes,
        75,
      );
      expect(find.textContaining('75 phút/ngày'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.examPlan,
      );
      expect(find.text('75 phút'), findsOneWidget);
    },
  );

  testWidgets('back from study time preserves both selections', (tester) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n4);
    await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
    await tester.pump();

    await tester.tap(find.byTooltip('Quay lại bước chọn mục tiêu'));
    await tester.pump();

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.targetLevel);
    expect(state.selectedCurrentStudyLevel?.level, JlptLevel.n5);
    expect(state.selectedJlptLevel?.level, JlptLevel.n4);
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

  testWidgets(
    'saving onboarding without an exam date persists levels and minutes',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      await _reachCompletion(
        tester,
        level: JlptLevel.n4,
        studyTime: DailyStudyTime.fortyFive,
      );

      expect(harness.profileRepository.savedCurrentStudyLevelId, 101);
      expect(harness.profileRepository.savedTargetLevelId, 204);
      expect(harness.profileRepository.savedDailyMinutes, 45);
      expect(harness.profileRepository.savedExamDate, isNull);
      expect(harness.profileRepository.clearCalls, 0);
    },
  );

  testWidgets('selecting a future exam session persists its estimated date', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachExamPlan(tester, level: JlptLevel.n4);
    final now = DateTime.now().toUtc();
    final year = JlptExamCalendar.availableYears(now).first;
    final session = JlptExamCalendar.futureSessions(year, now).first;

    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey<String>('exam_session_${session.month}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_confirm_exam_session')),
    );
    await tester.pumpAndSettle();
    expect(
      harness.container.read(onboardingControllerProvider).targetExamDate,
      session.date,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    await tester.pumpAndSettle();
    expect(harness.profileRepository.savedExamDate, session.date);
    expect(harness.profileRepository.clearCalls, 0);
  });

  testWidgets('changing exam year recalculates the selected session date', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachExamPlan(tester, level: JlptLevel.n4);
    final years = JlptExamCalendar.availableYears(DateTime.now().toUtc());
    final nextYear = years[1];
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_exam_year')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('$nextYear').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('exam_session_7')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_confirm_exam_session')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.container.read(onboardingControllerProvider).targetExamDate,
      JlptExamCalendar.estimatedDate(nextYear, DateTime.july),
    );
    expect(harness.profileRepository.goalCalls, 0);
  });

  testWidgets('clearing a saved date sends explicit clear intent', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachExamPlan(tester, level: JlptLevel.n5);
    final prior = JlptExamCalendar.estimatedDate(2030, DateTime.december);
    harness.container
        .read(onboardingControllerProvider.notifier)
        .selectTargetExamDate(prior);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_clear_exam_session')),
    );
    await tester.pumpAndSettle();
    expect(
      harness.container
          .read(onboardingControllerProvider)
          .examDateClearRequested,
      isTrue,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    await tester.pumpAndSettle();
    expect(harness.profileRepository.goalCalls, 1);
    expect(harness.profileRepository.savedExamDate, isNull);
  });

  testWidgets('mismatched Backend response cannot show completion', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    harness.profileRepository.returnMismatchedGoal = true;
    await _reachCompletion(
      tester,
      level: JlptLevel.n3,
      studyTime: DailyStudyTime.thirty,
    );
    expect(
      harness.container.read(onboardingControllerProvider).currentStep,
      OnboardingStep.examPlan,
    );
    expect(
      harness.container.read(onboardingControllerProvider).submissionFailed,
      isTrue,
    );
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
    expect(state.currentStep, OnboardingStep.examPlan);
    expect(state.selectedJlptLevel?.level, JlptLevel.n3);
    expect(state.selectedStudyTime, DailyStudyTime.fifteen);
  });

  testWidgets('start action opens the persisted Standard Roadmap', (
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

    expect(find.byType(LearningRoadmapScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
  });

  testWidgets('onboarding route stays outside the learner tab shell', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('all four steps keep the same Skip action without saving', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    void expectSkip() {
      expect(
        find.byKey(const ValueKey<String>('onboarding_skip_button')),
        findsOneWidget,
      );
      expect(find.text('Để sau'), findsOneWidget);
    }

    expectSkip();
    await _selectCurrentAndTarget(tester, JlptLevel.n5, JlptLevel.n4);
    expectSkip();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    await tester.pumpAndSettle();
    expectSkip();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('study_time_30')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('study_time_30')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
    );
    await tester.pumpAndSettle();
    expectSkip();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_skip_button')),
    );
    await tester.pumpAndSettle();
    expect(harness.profileRepository.goalCalls, 0);
    expect(harness.profileRepository.studyLevelCalls, 0);
    expect(harness.placementRepository.loadStatusCalls, 0);
    expect(harness.placementRepository.skipCalls, 0);
    expect(harness.learningPathRepository.roadmapMutationCalls, 0);
  });

  for (final width in <double>[360, 393, 412]) {
    testWidgets(
      'fixed onboarding footer remains usable at ${width.toInt()}dp',
      (tester) async {
        await _pumpOnboarding(tester);
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await _reachStudyTime(tester, JlptLevel.n4);
        expect(
          find.byKey(
            const ValueKey<String>('onboarding_study_continue_button'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('study_time_30')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('study_time_30')));
        await tester.pump();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('onboarding_study_continue_button'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in <double>[1.3, 2.0]) {
    testWidgets('exam plan and session sheet support ${scale}x text', (
      tester,
    ) async {
      await _pumpOnboarding(tester);
      await _reachExamPlan(tester, level: JlptLevel.n3);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('onboarding_exam_year')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'edit flow prefills all fields, updates via one atomic PUT, and returns to Goal Summary with Sakura toast',
    (tester) async {
      final harness = await _pumpOnboarding(
        tester,
        initialLocation: AppRoutes.profileJlptGoal,
        seededGoal: true,
      );

      expect(find.byType(JlptGoalScreen), findsOneWidget);
      expect(find.text('N5'), findsWidgets);
      expect(find.text('N4'), findsWidgets);
      expect(find.text('30 phút/ngày'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Hủy chỉnh sửa'), findsOneWidget);
      expect(find.text('Để sau'), findsNothing);

      // Step 1: Change current level from N5 to N4
      await tester.tap(find.byKey(const ValueKey<String>('current_level_n4')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pumpAndSettle();

      // Step 2: Change target level to N2 and add self-declared N4 certificate
      await tester.tap(find.byKey(const ValueKey<String>('jlpt_n2')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('onboarding_has_certificate')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_has_certificate')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('certified_level_n4')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('certified_level_n4')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pumpAndSettle();

      // Step 3: Select 60 minutes
      await tester.tap(find.byKey(const ValueKey<String>('study_time_60')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await tester.pumpAndSettle();

      // Step 4: Save changes
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      expect(harness.profileRepository.goalCalls, 1);
      expect(harness.profileRepository.studyLevelCalls, 0);
      expect(harness.profileRepository.savedCurrentStudyLevelId, 204);
      expect(harness.profileRepository.savedTargetLevelId, 418);
      expect(harness.profileRepository.savedDailyMinutes, 60);
      expect(harness.profileRepository.savedCertifiedLevelId, 204);
      expect(harness.profileRepository.savedExpectedVersion, 3);
      expect(find.byType(JlptGoalScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('riki_toast_success')),
        findsOneWidget,
      );
      expect(find.text('Cập nhật mục tiêu JLPT thành công'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('onboarding_completion_motion')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'edit cancel without changes returns directly; with unsaved changes confirms before discarding',
    (tester) async {
      await _pumpOnboarding(
        tester,
        initialLocation: AppRoutes.profileJlptGoal,
        seededGoal: true,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
      );
      await tester.pumpAndSettle();

      // Without changes, tapping Hủy chỉnh sửa returns directly to JlptGoalScreen
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_skip_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(JlptGoalScreen), findsOneWidget);
      expect(find.text('Hủy chỉnh sửa mục tiêu?'), findsNothing);

      // Re-open edit and modify Step 1
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('current_level_n3')));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_skip_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hủy chỉnh sửa mục tiêu?'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_skip_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy chỉnh sửa').last);
      await tester.pumpAndSettle();
      expect(find.byType(JlptGoalScreen), findsOneWidget);
    },
  );

  testWidgets(
    'API save error preserves form state across all 4 steps and succeeds on retry',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      harness.profileRepository.failNextSave = true;

      await _reachExamPlan(
        tester,
        level: JlptLevel.n3,
        studyTime: DailyStudyTime.sixty,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();

      final stateAfterError = harness.container.read(
        onboardingControllerProvider,
      );
      expect(stateAfterError.currentStep, OnboardingStep.examPlan);
      expect(stateAfterError.submissionFailed, isTrue);
      expect(stateAfterError.selectedCurrentStudyLevel?.level, JlptLevel.n5);
      expect(stateAfterError.selectedJlptLevel?.level, JlptLevel.n3);
      expect(stateAfterError.dailyStudyMinutes, 60);
      expect(
        find.byKey(const ValueKey<String>('onboarding_save_error_banner')),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng kiểm tra kết nối và thử lại.'),
        findsOneWidget,
      );

      // Retry succeeds
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await tester.pumpAndSettle();
      expect(
        harness.container.read(onboardingControllerProvider).currentStep,
        OnboardingStep.complete,
      );
    },
  );

  testWidgets('double submit is prevented while save is in flight', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    final saveCompleter = Completer<UserProfile>();
    harness.profileRepository.saveCompleter = saveCompleter;

    await _reachExamPlan(
      tester,
      level: JlptLevel.n4,
      studyTime: DailyStudyTime.thirty,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    await tester.pump();

    expect(
      harness.container.read(onboardingControllerProvider).isSubmitting,
      isTrue,
    );
    final overlayDuringSubmit = tester.widget<AppLoadingOverlay>(
      find.byType(AppLoadingOverlay),
    );
    expect(overlayDuringSubmit.visible, isTrue);
    expect(find.text('Đang lưu thông tin'), findsOneWidget);
    expect(find.text('Đang tạo lộ trình'), findsNothing);
    final buttonDuringSubmit = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    expect(buttonDuringSubmit.onPressed, isNull);
    expect(harness.profileRepository.goalCalls, 1);

    saveCompleter.complete(
      harness.profileRepository._profile(
        targetLevelId: 204,
        dailyStudyMinutes: 30,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      harness.container.read(onboardingControllerProvider).currentStep,
      OnboardingStep.complete,
    );
  });

  testWidgets('editing goal shows Đang lưu thay đổi and never Đang tạo lộ trình', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester, seededGoal: true);
    harness.container.read(onboardingControllerProvider.notifier).startEditFromProfile(
      currentStudyLevel: testJlptCatalog[0],
      targetLevel: testJlptCatalog[1],
      dailyMinutes: 30,
      targetExamDate: null,
      certifiedJlptLevel: null,
      goalVersion: 3,
    );
    await tester.pumpAndSettle();

    // Advance Steps 1 -> 2 -> 3 -> 4 without triggering API calls.
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
    );
    await tester.pumpAndSettle();
    expect(harness.profileRepository.goalCalls, 0);
    expect(harness.placementRepository.skipCalls, 0);
    expect(harness.learningPathRepository.totalCalls, 0);

    final saveCompleter = Completer<UserProfile>();
    harness.profileRepository.saveCompleter = saveCompleter;
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    await tester.pump();

    final overlay = tester.widget<AppLoadingOverlay>(
      find.byType(AppLoadingOverlay),
    );
    expect(overlay.visible, isTrue);
    expect(find.text('Đang lưu thay đổi'), findsOneWidget);
    expect(find.text('Đang tạo lộ trình'), findsNothing);

    saveCompleter.complete(
      harness.profileRepository._profile(
        targetLevelId: 204,
        dailyStudyMinutes: 30,
      ),
    );
    await tester.pumpAndSettle();
    expect(harness.profileRepository.goalCalls, 1);
    expect(harness.placementRepository.skipCalls, 0);
    expect(harness.learningPathRepository.roadmapMutationCalls, 0);
  });

  test('account switch invalidates onboarding and profile state', () async {
    final session = createTestAuthSession();
    final profileRepository = _OnboardingProfileRepository();
    final container = ProviderContainer(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(session.dispose);

    session.markAuthenticated(userId: 42, role: BackendUserRole.learner);
    container
        .read(onboardingControllerProvider.notifier)
        .selectCurrentStudyLevel(testJlptCatalog[2]);
    await container.read(userProfileControllerProvider.future);
    expect(
      container
          .read(onboardingControllerProvider)
          .selectedCurrentStudyLevel
          ?.id,
      309,
    );
    expect(profileRepository.loadCalls, 1);

    session.markAuthenticated(userId: 99, role: BackendUserRole.learner);
    expect(
      container.read(onboardingControllerProvider).selectedCurrentStudyLevel,
      isNull,
    );
    await container.read(userProfileControllerProvider.future);
    expect(profileRepository.loadCalls, 2);
  });

  testWidgets(
    'step 1 in auth create onboarding hides back button and only prompts pause when dirty',
    (tester) async {
      final harness = await _pumpOnboarding(
        tester,
        initialLocation: AppRoutes.onboardingWithOrigin(OnboardingOrigin.auth),
      );
      final session = harness.container.read(authSessionControllerProvider);
      expect(session.value, AuthSessionState.authenticated);

      // Auth Step 1 shows skip ("Để sau") instead of Header Back.
      expect(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('onboarding_skip_button')),
        findsOneWidget,
      );

      // Clean Android Back does not open Logout dialog or return to Login.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
        findsNothing,
      );
      expect(session.value, AuthSessionState.authenticated);
      expect(find.byType(LoginScreen), findsNothing);

      // Dirty Step 1 Android Back opens pause confirmation and goes Home on confirm.
      await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Tạm dừng thiết lập mục tiêu?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
        findsNothing,
      );

      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Về Trang chủ'), findsOneWidget);
      await tester.tap(find.text('Về Trang chủ'));
      await tester.pumpAndSettle();
      expect(session.value, AuthSessionState.authenticated);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'step 1 from profile returns to profile cleanly without logout dialog',
    (tester) async {
      final harness = await _pumpOnboarding(
        tester,
        initialLocation: AppRoutes.profile,
      );
      final session = harness.container.read(authSessionControllerProvider);
      expect(session.value, AuthSessionState.authenticated);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('profile_jlpt_goal_action')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('profile_jlpt_goal_action')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
        findsOneWidget,
      );
      expect(find.byTooltip('Đăng xuất'), findsNothing);
      expect(find.byTooltip('Rời thiết lập'), findsOneWidget);

      // Clean back returns directly to Profile without Logout or Discard dialogs.
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
        findsNothing,
      );
      expect(find.text('Hủy thay đổi?'), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Dirty back prompts Discard and returns cleanly to Profile when confirmed.
      await tester.tap(
        find.byKey(const ValueKey<String>('profile_jlpt_goal_action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rời thiết lập mục tiêu?'), findsOneWidget);
      await tester.tap(find.text('Rời đi'));
      await tester.pumpAndSettle();
      expect(session.value, AuthSessionState.authenticated);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'step 1 back in edit mode returns to JLPT Goal summary without logging out',
    (tester) async {
      final harness = await _pumpOnboarding(
        tester,
        initialLocation: AppRoutes.profileJlptGoal,
        seededGoal: true,
      );
      final session = harness.container.read(authSessionControllerProvider);

      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
        findsNothing,
      );
      expect(session.value, AuthSessionState.authenticated);
      expect(find.byType(JlptGoalScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sakura step progress animates smoothly forward and backward without resetting or changing height',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        double progressFraction() {
          final fill = tester.widget<FractionallySizedBox>(
            find.byKey(const ValueKey<String>('sakura_progress_fill')),
          );
          return fill.widthFactor!;
        }

        double trackHeight() {
          return tester
              .getSize(
                find.byKey(const ValueKey<String>('sakura_progress_track')),
              )
              .height;
        }

        String semanticsValue() {
          return tester
              .getSemantics(
                find.byKey(const ValueKey<String>('onboarding_step_progress')),
              )
              .value;
        }

        await _pumpOnboarding(tester);

        // Step 1 settled at 25%.
        expect(find.text('Bước 1 / 4'), findsOneWidget);
        expect(progressFraction(), closeTo(0.25, 0.001));
        expect(semanticsValue(), '25%');
        expect(trackHeight(), closeTo(7.0, 0.01));

        // Forward 1 -> 2.
        await tester.tap(find.text('JLPT N5'));
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        final mid1To2 = progressFraction();
        expect(mid1To2, greaterThan(0.25));
        expect(mid1To2, lessThan(0.50));
        expect(trackHeight(), closeTo(7.0, 0.01));
        final incomingStep2Dx = tester
            .getTopLeft(find.text('Bạn muốn đạt JLPT nào?'))
            .dx;
        final incomingStep2Fade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Bạn muốn đạt JLPT nào?'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(incomingStep2Fade.opacity.value, greaterThan(0.4));

        await tester.pumpAndSettle();
        final settledStep2Dx = tester
            .getTopLeft(find.text('Bạn muốn đạt JLPT nào?'))
            .dx;
        expect(incomingStep2Dx, greaterThan(settledStep2Dx));
        expect(find.text('Bước 2 / 4'), findsOneWidget);
        expect(progressFraction(), closeTo(0.50, 0.001));
        expect(semanticsValue(), '50%');

        // Forward straight to Step 4 from a fresh flow, then animate 4 -> 3 -> 4 -> 3 -> 2 -> 3.
        await _pumpOnboarding(tester);
        await _reachExamPlan(
          tester,
          level: JlptLevel.n3,
          studyTime: DailyStudyTime.sixty,
        );
        expect(find.text('Bước 4 / 4'), findsOneWidget);
        expect(progressFraction(), closeTo(1.0, 0.001));
        expect(semanticsValue(), '100%');
        expect(trackHeight(), closeTo(7.0, 0.01));

        // Backward 4 -> 3 does not reset to 0 and interpolates downward.
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        final mid4To3 = progressFraction();
        expect(mid4To3, greaterThan(0.75));
        expect(mid4To3, lessThan(1.0));
        expect(trackHeight(), closeTo(7.0, 0.01));
        final incomingStep3Dx = tester
            .getTopLeft(find.text('Mỗi ngày, bạn muốn học bao lâu?'))
            .dx;

        await tester.pumpAndSettle();
        final settledStep3Dx = tester
            .getTopLeft(find.text('Mỗi ngày, bạn muốn học bao lâu?'))
            .dx;
        expect(incomingStep3Dx, lessThan(settledStep3Dx));
        expect(find.text('Bước 3 / 4'), findsOneWidget);
        expect(progressFraction(), closeTo(0.75, 0.001));
        expect(semanticsValue(), '75%');

        // Forward 3 -> 4.
        await tester.tap(
          find.byKey(
            const ValueKey<String>('onboarding_study_continue_button'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        final mid3To4 = progressFraction();
        expect(mid3To4, greaterThan(0.75));
        expect(mid3To4, lessThan(1.0));
        await tester.pumpAndSettle();
        expect(progressFraction(), closeTo(1.0, 0.001));

        // Backward 4 -> 3 -> 2.
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        final mid3To2 = progressFraction();
        expect(mid3To2, greaterThan(0.50));
        expect(mid3To2, lessThan(0.75));
        await tester.pumpAndSettle();
        expect(find.text('Bước 2 / 4'), findsOneWidget);
        expect(progressFraction(), closeTo(0.50, 0.001));

        // Forward 2 -> 3.
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        final mid2To3 = progressFraction();
        expect(mid2To3, greaterThan(0.50));
        expect(mid2To3, lessThan(0.75));
        await tester.pumpAndSettle();
        expect(find.text('Bước 3 / 4'), findsOneWidget);
        expect(progressFraction(), closeTo(0.75, 0.001));
        expect(tester.takeException(), isNull);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );

  testWidgets(
    'sakura step progress reverses mid-flight safely and disposes cleanly',
    (tester) async {
      double progressFraction() {
        return tester
            .widget<FractionallySizedBox>(
              find.byKey(const ValueKey<String>('sakura_progress_fill')),
            )
            .widthFactor!;
      }

      await _pumpOnboarding(tester);
      await tester.tap(find.text('JLPT N5'));
      await tester.pump();

      // Start forward animation 1 -> 2.
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final atReversalStart = progressFraction();
      expect(atReversalStart, greaterThan(0.25));
      expect(atReversalStart, lessThan(0.50));

      // Reverse back to Step 1 while still animating.
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pump();
      expect(progressFraction(), closeTo(atReversalStart, 0.02));
      await tester.pump(const Duration(milliseconds: 140));
      expect(progressFraction(), lessThan(atReversalStart));
      await tester.pumpAndSettle();
      expect(find.text('Bước 1 / 4'), findsOneWidget);
      expect(progressFraction(), closeTo(0.25, 0.001));

      // Standalone disposal mid-flight must not leak tickers/controllers.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SakuraAnimatedStepProgress(
              currentStep: 1,
              semanticsLabel: 'Bước 1 / 4',
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SakuraAnimatedStepProgress(
              currentStep: 3,
              semanticsLabel: 'Bước 3 / 4',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion snaps step progress immediately and validation errors keep progress unchanged',
    (tester) async {
      double progressFraction() {
        return tester
            .widget<FractionallySizedBox>(
              find.byKey(const ValueKey<String>('sakura_progress_fill')),
            )
            .widthFactor!;
      }

      // 1. Reduced motion snaps forward and backward within a single frame.
      await _pumpOnboarding(tester, disableAnimations: true);
      await tester.tap(find.text('JLPT N5'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pump();
      expect(find.text('Bước 2 / 4'), findsOneWidget);
      expect(progressFraction(), closeTo(0.50, 0.001));

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pump();
      expect(find.text('Bước 1 / 4'), findsOneWidget);
      expect(progressFraction(), closeTo(0.25, 0.001));

      // 2. Failed validation never advances progress or transitions.
      await _pumpOnboarding(tester);
      // Step 1: deselect N5 by restarting fresh — no current level selected.
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bước 1 / 4'), findsOneWidget);
      expect(progressFraction(), closeTo(0.25, 0.001));

      // Step 2: no target selected.
      await _advanceToTarget(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bước 2 / 4'), findsOneWidget);
      expect(progressFraction(), closeTo(0.50, 0.001));

      // Step 3: invalid custom minutes (> 1440).
      await _pumpOnboarding(tester);
      await _reachStudyTime(tester, JlptLevel.n3);
      expect(progressFraction(), closeTo(0.75, 0.001));
      final customCard = find.byKey(const ValueKey<String>('study_time_custom'));
      await tester.ensureVisible(customCard);
      await tester.tap(customCard);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1441');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bước 3 / 4'), findsOneWidget);
      expect(progressFraction(), closeTo(0.75, 0.001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'learning plan preview reflects live edits across steps without persisting until submit',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      await _reachExamPlan(
        tester,
        level: JlptLevel.n3,
        studyTime: DailyStudyTime.thirty,
      );

      final preview = find.byKey(
        const ValueKey<String>('onboarding_learning_plan_preview'),
      );
      await tester.ensureVisible(preview);
      await tester.pumpAndSettle();

      expect(preview, findsOneWidget);
      expect(find.text('KẾ HOẠCH HỌC TẬP CỦA BẠN'), findsOneWidget);
      expect(find.text('Chinh phục JLPT N3'), findsOneWidget);
      expect(find.text('Một hành trình mới đang chờ bạn!'), findsOneWidget);

      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_target_level'),
          ),
          matching: find.text('JLPT N3'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_study_time'),
          ),
          matching: find.text('30 phút'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_certificate'),
          ),
          matching: find.text('Chưa có'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_exam_summary'),
          ),
          matching: find.text('Chưa chọn kỳ thi'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_exam_summary'),
          ),
          matching: find.text('Bạn có thể bổ sung sau.'),
        ),
        findsOneWidget,
      );
      expect(harness.profileRepository.goalCalls, 0);

      // Select a valid upcoming JLPT session and verify preview updates live.
      final nowUtc = DateTime.now().toUtc();
      final nextYear = JlptExamCalendar.availableYears(nowUtc).first;
      final nextSession = JlptExamCalendar.futureSessions(
        nextYear,
        nowUtc,
      ).first;
      harness.container
          .read(onboardingControllerProvider.notifier)
          .selectTargetExamDate(nextSession.date);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_exam_summary'),
          ),
          matching: find.text(
            'Tháng ${nextSession.month}, ${nextSession.year}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_exam_summary'),
          ),
          matching: find.textContaining('Dự kiến:'),
        ),
        findsOneWidget,
      );
      expect(harness.profileRepository.goalCalls, 0);

      // Go back to Step 3, change study time to 95m, and return to Step 4.
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_back_button')),
      );
      await tester.pumpAndSettle();
      final customCard = find.byKey(const ValueKey<String>('study_time_custom'));
      await tester.ensureVisible(customCard);
      await tester.tap(customCard);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '95');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_study_time'),
          ),
          matching: find.text('95 phút'),
        ),
        findsOneWidget,
      );
      expect(find.text('30 phút'), findsNothing);
      expect(harness.profileRepository.goalCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sakura learning plan preview handles certificate contract states, exam date fallback, and 2x font scaling cleanly',
    (tester) async {
      await _pumpOnboarding(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final delegates = app.localizationsDelegates;
      final supportedLocales = app.supportedLocales;

      // Case 1: Declared certificate level + date-only fallback + 2.0x text scale.
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: delegates,
          supportedLocales: supportedLocales,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(2.0),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SakuraLearningPlanPreview(
                  currentLevelCode: 'N4',
                  targetLevelCode: 'N2',
                  dailyMinutes: 60,
                  hasCertificate: true,
                  certifiedLevelCode: 'N4',
                  targetExamDate: DateTime(2026, 7, 5),
                  examSession: null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chinh phục JLPT N2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_current_level'),
          ),
          matching: find.text('JLPT N4'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_certificate'),
          ),
          matching: find.text('JLPT N4'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_exam_summary'),
          ),
          matching: find.textContaining('05/07/2026'),
        ),
        findsAtLeastNWidgets(1),
      );

      // Single-column stacking at 2.0x scale: tile 1 ends above tile 2 start.
      final tile1Rect = tester.getRect(
        find.byKey(
          const ValueKey<String>('onboarding_plan_tile_current_level'),
        ),
      );
      final tile2Rect = tester.getRect(
        find.byKey(const ValueKey<String>('onboarding_plan_tile_target_level')),
      );
      expect(tile1Rect.bottom, lessThanOrEqualTo(tile2Rect.top + 1.0));
      expect(tester.takeException(), isNull);

      // Case 2: Indeterminate certificate (hasCertificate=true, certifiedLevelCode=null).
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: delegates,
          supportedLocales: supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SakuraLearningPlanPreview(
                currentLevelCode: 'N5',
                targetLevelCode: 'N3',
                dailyMinutes: 45,
                hasCertificate: true,
                certifiedLevelCode: null,
                targetExamDate: null,
                examSession: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('onboarding_plan_tile_certificate'),
          ),
          matching: find.text('Chưa cung cấp thông tin'),
        ),
        findsOneWidget,
      );
      expect(find.text('Chưa có'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in const <Size>[
    Size(360, 640),
    Size(393, 852),
    Size(412, 915),
  ]) {
    testWidgets(
      'step 4 layout and pinned CTA render cleanly without overflow on ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpOnboarding(tester, viewportSize: size);
        await _reachExamPlan(
          tester,
          level: JlptLevel.n3,
          studyTime: DailyStudyTime.sixty,
        );

        final ctaFinder = find.byKey(
          const ValueKey<String>('onboarding_complete_button'),
        );
        expect(ctaFinder, findsOneWidget);
        final ctaRect = tester.getRect(ctaFinder);
        expect(ctaRect.bottom, lessThanOrEqualTo(size.height));
        expect(ctaRect.top, greaterThanOrEqualTo(0));

        await tester.ensureVisible(
          find.byKey(
            const ValueKey<String>('onboarding_learning_plan_preview'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>('onboarding_learning_plan_preview'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _OnboardingHarness {
  const _OnboardingHarness({
    required this.container,
    required this.profileRepository,
    required this.placementRepository,
    required this.learningPathRepository,
  });

  final ProviderContainer container;
  final _OnboardingProfileRepository profileRepository;
  final _OnboardingPlacementRepository placementRepository;
  final _SpyLearningPathRepository learningPathRepository;
}

Future<_OnboardingHarness> _pumpOnboarding(
  WidgetTester tester, {
  Locale? locale,
  String initialLocation = AppRoutes.onboarding,
  bool seededGoal = false,
  bool disableAnimations = false,
  Size viewportSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final profileRepository = _OnboardingProfileRepository(
    seededGoal: seededGoal,
  );
  final placementRepository = _OnboardingPlacementRepository();
  final learningPathRepository = _SpyLearningPathRepository();
  final session = createTestAuthSession();
  final container = ProviderContainer(
    overrides: [
      authSessionControllerProvider.overrideWithValue(session),
      jlptCatalogRepositoryProvider.overrideWithValue(
        TestJlptCatalogRepository(),
      ),
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
      placementTestRepositoryProvider.overrideWithValue(placementRepository),
      learningPathRepositoryProvider.overrideWithValue(learningPathRepository),
    ],
  );
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(container.dispose);
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: locale ?? const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final wrapped = RikiToastHost(child: child ?? const SizedBox.shrink());
          if (!disableAnimations) return wrapped;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: wrapped,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _OnboardingHarness(
    container: container,
    profileRepository: profileRepository,
    placementRepository: placementRepository,
    learningPathRepository: learningPathRepository,
  );
}

class _OnboardingProfileRepository
    implements
        UserProfileRepository,
        StudyLevelProfileRepository,
        TargetExamDateProfileRepository,
        ClearTargetExamDateProfileRepository,
        AtomicLearningGoalProfileRepository {
  _OnboardingProfileRepository({bool seededGoal = false}) {
    if (seededGoal) {
      savedCurrentStudyLevelId = 101;
      savedTargetLevelId = 204;
      savedDailyMinutes = 30;
      savedGoalVersion = 3;
    }
  }

  int loadCalls = 0;
  int goalCalls = 0;
  int clearCalls = 0;
  int studyLevelCalls = 0;
  int? savedCurrentStudyLevelId;
  int? savedTargetLevelId;
  int? savedDailyMinutes;
  DateTime? savedExamDate;
  int? savedCertifiedLevelId;
  int? savedExpectedVersion;
  int savedGoalVersion = 0;
  bool returnMismatchedGoal = false;
  bool failNextSave = false;
  Completer<UserProfile>? saveCompleter;

  @override
  Future<UserProfile> saveLearningGoal({
    required int currentStudyLevelId,
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime? targetExamDate,
    required int? certifiedJlptLevelId,
    required int expectedVersion,
  }) async {
    goalCalls++;
    if (failNextSave) {
      failNextSave = false;
      throw const NetworkError(message: 'Simulated network failure');
    }
    savedCurrentStudyLevelId = currentStudyLevelId;
    savedTargetLevelId = targetJlptLevelId;
    savedDailyMinutes = dailyStudyMinutes;
    savedExamDate = targetExamDate;
    savedCertifiedLevelId = certifiedJlptLevelId;
    savedExpectedVersion = expectedVersion;
    savedGoalVersion = expectedVersion + 1;
    if (saveCompleter != null) {
      final result = await saveCompleter!.future;
      saveCompleter = null;
      return result;
    }
    return _profile(
      targetLevelId: returnMismatchedGoal ? null : targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
      targetExamDate: targetExamDate,
    );
  }

  @override
  Future<UserProfile> switchStudyLevel({
    required int currentStudyLevelId,
  }) async {
    studyLevelCalls++;
    savedCurrentStudyLevelId = currentStudyLevelId;
    return _profile(targetLevelId: savedTargetLevelId);
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    goalCalls++;
    savedTargetLevelId = targetJlptLevelId;
    savedDailyMinutes = dailyStudyMinutes;
    return _profile(
      targetLevelId: returnMismatchedGoal ? null : targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
    );
  }

  @override
  Future<UserProfile> setJlptGoalWithExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime targetExamDate,
  }) async {
    goalCalls++;
    savedTargetLevelId = targetJlptLevelId;
    savedDailyMinutes = dailyStudyMinutes;
    savedExamDate = targetExamDate;
    return _profile(
      targetLevelId: returnMismatchedGoal ? null : targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
      targetExamDate: targetExamDate,
    );
  }

  @override
  Future<UserProfile> clearJlptGoalExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    goalCalls++;
    clearCalls++;
    savedTargetLevelId = targetJlptLevelId;
    savedDailyMinutes = dailyStudyMinutes;
    savedExamDate = null;
    return _profile(
      targetLevelId: targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
    );
  }

  @override
  Future<UserProfile> loadProfile() async {
    loadCalls++;
    return _profile(
      targetLevelId: savedTargetLevelId,
      dailyStudyMinutes: savedDailyMinutes ?? 30,
      targetExamDate: savedExamDate,
    );
  }

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => _profile();

  @override
  Future<UserProfile> updateProfile({required String fullName}) async =>
      _profile();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _profile();

  UserProfile _profile({
    int? targetLevelId,
    int dailyStudyMinutes = 30,
    DateTime? targetExamDate,
  }) => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetLevelId,
    targetJlptLevelName: targetLevelId == null ? null : 'N4',
    currentStudyLevelId: savedCurrentStudyLevelId,
    currentStudyLevelName: savedCurrentStudyLevelId == null ? null : 'N5',
    dailyStudyMinutes: dailyStudyMinutes,
    targetExamDate: targetExamDate,
    learningGoalVersion: savedGoalVersion,
    certifiedJlptLevelId: savedCertifiedLevelId,
    certifiedJlptLevelName: savedCertifiedLevelId == null ? null : 'N4',
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );
}

class _OnboardingPlacementRepository
    implements PlacementTestRepository, PlacementSkipRepository {
  int loadStatusCalls = 0;
  int skipCalls = 0;
  bool skipFails = false;
  PlacementTestStatus status = const PlacementTestStatus(
    hasCompletedPlacementTest: false,
  );

  @override
  Future<PlacementTestStatus> skip() async {
    skipCalls++;
    if (skipFails) throw StateError('QA Placement Skip failed');
    return const PlacementTestStatus(
      hasCompletedPlacementTest: false,
      placementDecision: PlacementDecision.skipped,
    );
  }

  @override
  Future<PlacementTestStatus> loadStatus() async {
    loadStatusCalls++;
    return status;
  }

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();
}

Future<void> _reachStudyTime(WidgetTester tester, JlptLevel level) async {
  await _selectCurrentAndTarget(tester, JlptLevel.n5, level);
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.pumpAndSettle();
}

Future<void> _advanceToTarget(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectCurrentAndTarget(
  WidgetTester tester,
  JlptLevel current,
  JlptLevel target,
) async {
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('current_level_${current.name}')),
  );
  await tester.tap(
    find.byKey(ValueKey<String>('current_level_${current.name}')),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('jlpt_${target.name}')),
  );
  await tester.tap(find.byKey(ValueKey<String>('jlpt_${target.name}')));
  await tester.pump();
}

Future<void> _reachCompletion(
  WidgetTester tester, {
  required JlptLevel level,
  required DailyStudyTime studyTime,
}) async {
  await _reachExamPlan(tester, level: level, studyTime: studyTime);
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('onboarding_complete_button')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_complete_button')),
  );
  await tester.pumpAndSettle();
}

Future<void> _reachExamPlan(
  WidgetTester tester, {
  required JlptLevel level,
  DailyStudyTime studyTime = DailyStudyTime.thirty,
}) async {
  await _reachStudyTime(tester, level);
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('study_time_${studyTime.minutes}')),
  );
  await tester.tap(
    find.byKey(ValueKey<String>('study_time_${studyTime.minutes}')),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
  );
  await tester.pumpAndSettle();
}

class _SpyLearningPathRepository
    implements LearningPathRepository, LearningPathVersionRepository {
  int loadLatestCalls = 0;
  int generateCalls = 0;
  int loadActiveCalls = 0;
  int loadHistoryCalls = 0;
  int previewCalls = 0;
  int confirmPreviewCalls = 0;
  int cancelPreviewCalls = 0;

  int get roadmapMutationCalls =>
      generateCalls + previewCalls + confirmPreviewCalls + cancelPreviewCalls;

  int get totalCalls =>
      loadLatestCalls +
      loadActiveCalls +
      loadHistoryCalls +
      roadmapMutationCalls;

  @override
  Future<RecommendedLearningPath?> loadLatest() async {
    loadLatestCalls++;
    return null;
  }

  @override
  Future<RecommendedLearningPath> generate() async {
    generateCalls++;
    throw UnimplementedError('Onboarding must not generate AI roadmap');
  }

  @override
  Future<RecommendedLearningPath?> loadActive() async {
    loadActiveCalls++;
    return null;
  }

  @override
  Future<List<RecommendedLearningPath>> loadHistory() async {
    loadHistoryCalls++;
    return const <RecommendedLearningPath>[];
  }

  @override
  Future<RecommendedLearningPath> preview({
    required int startingJlptLevelId,
    int? targetJlptLevelId,
  }) async {
    previewCalls++;
    throw UnimplementedError('Onboarding must not preview AI roadmap');
  }

  @override
  Future<RecommendedLearningPath> confirmPreview(int pathId) async {
    confirmPreviewCalls++;
    throw UnimplementedError('Onboarding must not confirm AI roadmap');
  }

  @override
  Future<RecommendedLearningPath> cancelPreview(int pathId) async {
    cancelPreviewCalls++;
    throw UnimplementedError('Onboarding must not cancel AI roadmap');
  }
}
