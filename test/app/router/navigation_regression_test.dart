import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/mentor_registration_intent.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/account_settings_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/change_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/update_email_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:rikipath_mobile/features/calendar/presentation/learner_calendar_screen.dart';
import 'package:rikipath_mobile/features/calendar/presentation/mentor_calendar_screen.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/data/fixture_home_repository.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/data/fixture_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_detail_screen.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_library_screen.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_media_driver.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/lesson_screen.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/learner_my_courses_screen.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/mentor_cohorts_screen.dart';
import 'package:rikipath_mobile/features/meeting/application/upcoming_meeting_provider.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_kpi_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_schedule_v3_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_schedule_v3_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_schedule_v3.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_profile_screen.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/session_demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/application/push_notification_service.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';
import 'package:rikipath_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/practice_session_repository.dart';
import 'package:rikipath_mobile/features/practice/presentation/daily_review_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';
import '../../support/test_json_preference_store.dart';
import '../../support/test_jwt.dart';
import '../../support/test_live_mock_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Onboarding Origin & Back / Dirty-Check Matrix', () {
    testWidgets(
      'Case B (auth): hides header back, skip goes home, dirty step1 prompts pause -> home',
      (tester) async {
        final session = createTestAuthSession();
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.onboardingWithOrigin(OnboardingOrigin.auth),
          authSession: session,
          profileRepository: _RegProfileRepository(withGoal: false),
        );

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('onboarding_skip_button')),
          findsOneWidget,
        );

        // Make step 1 dirty, trigger system back -> pause dialog (NEVER logout).
        await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Tạm dừng thiết lập mục tiêu?'), findsOneWidget);
        expect(find.textContaining('Đăng xuất'), findsNothing);

        // Stay on step 1
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsOneWidget);

        // Confirm Về Trang chủ -> goes to /home, stays authenticated
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Về Trang chủ'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(session.value, AuthSessionState.authenticated);
      },
    );

    testWidgets(
      'Case B (auth): skip goes home and step-by-step system back rewinds cleanly',
      (tester) async {
        final session = createTestAuthSession();
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.onboardingWithOrigin(OnboardingOrigin.auth),
          authSession: session,
          profileRepository: _RegProfileRepository(withGoal: false),
        );

        // Advance steps 1 -> 2 -> 3 -> 4
        await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('jlpt_n4')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey<String>('jlpt_n4')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('study_time_45')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('onboarding_study_continue_button'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('onboarding_complete_button')),
          findsOneWidget,
        );

        // System Back 4 -> 3 -> 2 -> 1
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('study_time_45')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey<String>('jlpt_n4')), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('current_level_n5')),
          findsOneWidget,
        );

        // Tap skip -> goes directly to /home
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_skip_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          AppRoutes.home,
        );
      },
    );

    testWidgets(
      'Case A (profile & roadmap): returns cleanly to caller and guards dirty edits',
      (tester) async {
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profile,
          profileRepository: _RegProfileRepository(withGoal: false),
        );

        router.push(
          AppRoutes.onboardingWithOrigin(
            OnboardingOrigin.profile,
            returnTo: AppRoutes.profile,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
          findsOneWidget,
        );

        // Clean back immediately returns to Profile without dialog
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        // Re-open, make dirty, confirm discard -> returns to Profile
        router.push(
          AppRoutes.onboardingWithOrigin(
            OnboardingOrigin.profile,
            returnTo: AppRoutes.profile,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rời thiết lập mục tiêu?'), findsOneWidget);

        await tester.tap(find.text('Rời đi'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Case C (profileGoal): Goal -> Edit opens Step 2, Back returns to Goal without logout dialog',
      (tester) async {
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileJlptGoal,
          profileRepository: _RegProfileRepository(withGoal: true),
        );

        expect(find.byType(JlptGoalScreen), findsOneWidget);
        final editButton = find.byKey(
          const ValueKey<String>('jlpt_goal_edit_button'),
        );
        await tester.ensureVisible(editButton);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('current_level_n5')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pumpAndSettle();
        // Step 2 target level card visible
        expect(find.byKey(const ValueKey<String>('jlpt_n4')), findsOneWidget);

        // Step 2 back returns to Step 1; Step 1 clean header back returns straight to JlptGoalScreen (never logout!)
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_back_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(JlptGoalScreen), findsOneWidget);
        expect(find.textContaining('Đăng xuất'), findsNothing);
      },
    );

    testWidgets(
      'Onboarding completion start button honors Roadmap returnTo context',
      (tester) async {
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.onboardingWithOrigin(
            OnboardingOrigin.roadmap,
            returnTo: AppRoutes.learnRoadmap,
          ),
          profileRepository: _RegProfileRepository(withGoal: false),
        );

        await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('jlpt_n4')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('onboarding_continue_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('onboarding_study_continue_button'),
          ),
        );
        await tester.pumpAndSettle();
        final completeButton = find.byKey(
          const ValueKey<String>('onboarding_complete_button'),
        );
        await tester.ensureVisible(completeButton);
        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('onboarding_start_button')),
          findsOneWidget,
        );

        // System back from completion returns to examPlan (NOT logging out)
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(completeButton, findsOneWidget);
        await tester.ensureVisible(completeButton);
        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        final startButton = find.byKey(
          const ValueKey<String>('onboarding_start_button'),
        );
        await tester.ensureVisible(startButton);
        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(find.byType(LearningRoadmapScreen), findsOneWidget);
      },
    );
  });

  group('Learner & Mentor 5-Tab Shell Isolation & Stack Parity', () {
    testWidgets(
      'Learner preserves branch state across tab switches and Android Back moves tab -> Tab 0',
      (tester) async {
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.home,
        );

        final homeElement = tester.element(find.byType(HomeScreen));

        // Switch to Learn tab & open nested LearningRoadmapScreen
        await tester.tap(
          find.descendant(
            of: find.byType(SakuraBottomNavigation),
            matching: find.text('Học tập'),
          ),
        );
        await tester.pumpAndSettle();
        router.go(AppRoutes.learnRoadmap);
        await tester.pumpAndSettle();
        expect(find.byType(LearningRoadmapScreen), findsOneWidget);

        // Switch to Practice tab, verify tab 2 selected
        await tester.tap(
          find.descendant(
            of: find.byType(SakuraBottomNavigation),
            matching: find.text('Luyện tập'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PracticeScreen), findsOneWidget);
        expect(
          tester
              .widget<SakuraBottomNavigation>(
                find.byType(SakuraBottomNavigation),
              )
              .selectedIndex,
          2,
        );

        // Switch back to Learn tab -> LearningRoadmapScreen branch state preserved!
        await tester.tap(
          find.descendant(
            of: find.byType(SakuraBottomNavigation),
            matching: find.text('Học tập'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LearningRoadmapScreen), findsOneWidget);

        // Switch to Profile tab, press Android back -> lands back on Tab 0 (Home)
        await tester.tap(
          find.descendant(
            of: find.byType(SakuraBottomNavigation),
            matching: find.text('Cá nhân'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.element(find.byType(HomeScreen)), same(homeElement));
      },
    );

    testWidgets(
      'Mentor shell isolates tabs, hides calendar back button inside shell, and Back returns to Tab 0',
      (tester) async {
        final session = createTestAuthSession(role: BackendUserRole.mentor);
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.mentor,
          authSession: session,
        );

        expect(find.byType(MentorHomeScreen), findsOneWidget);

        // Switch to Mentor Calendar tab -> no redundant calendar_back_button
        await tester.tap(
          find.descendant(
            of: find.byType(SakuraBottomNavigation),
            matching: find.text('Lịch dạy'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MentorCalendarScreen), findsOneWidget);
        expect(find.byKey(const Key('calendar_back_button')), findsNothing);

        // Android back from Mentor Profile tab returns to Tab 0 (MentorHomeScreen)
        await tester.tap(
          find.descendant(
            of: find.byType(SakuraBottomNavigation),
            matching: find.text('Cá nhân'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MentorProfileScreen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(MentorHomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Logout resets bottom bar & prevents back into authenticated routes across role switch',
      (tester) async {
        final store = _InMemoryKeyValueStore();
        final tokenStorage = TokenStorage(store);
        await tokenStorage.saveAuthenticatedSession(
          accessToken: createTestJwt(userId: 42, role: 'Learner'),
          userId: 42,
          role: 'Learner',
        );
        final session = AuthSessionController(tokenStorage);

        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profile,
          authSession: session,
          settle: false,
        );
        await session.restore();
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        await session.signOut();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SakuraBottomNavigation), findsNothing);

        // System Back while logged out stays safely on LoginScreen (never re-enters /profile)
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);

        // Switch to Mentor session -> arrives at Mentor shell with Mentor bar only
        await tokenStorage.saveAuthenticatedSession(
          accessToken: createTestJwt(userId: 84, role: 'Mentor'),
          userId: 84,
          role: 'Mentor',
        );
        session.markAuthenticated(
          userId: 84,
          role: BackendUserRole.mentor,
        );
        await tester.pumpAndSettle();
        expect(find.byType(MentorHomeScreen), findsOneWidget);
        expect(
          find.byKey(const Key('mentor_bottom_navigation_bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('learner_bottom_navigation_bar')),
          findsNothing,
        );
      },
    );
  });

  group('Cross-Branch Push, Multi-Stage Back Parity & Focused Overlays', () {
    testWidgets(
      'pushing Roadmap from Home preserves Home stack and pops directly back to Home',
      (tester) async {
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.home,
        );

        router.push(AppRoutes.learnRoadmap);
        await tester.pumpAndSettle();
        expect(find.byType(LearningRoadmapScreen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          tester
              .widget<SakuraBottomNavigation>(
                find.byType(SakuraBottomNavigation),
              )
              .selectedIndex,
          0,
        );
      },
    );

    testWidgets(
      'LessonScreen multi-stage system back rewinds Video -> Detail -> pops to Roadmap',
      (tester) async {
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.learnRoadmap,
        );

        router.push(AppRoutes.lesson(FixtureLessonRepository.lesson19RouteId));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('lesson_detail_view')),
          findsOneWidget,
        );

        final startButton = find.byKey(
          const ValueKey<String>('lesson_start_button'),
        );
        await tester.scrollUntilVisible(
          startButton,
          240,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey<String>('lesson_detail_view')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('lesson_video_status_playing')),
          findsOneWidget,
        );

        // Stage back: Video -> Detail (still on LessonScreen)
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('lesson_detail_view')),
          findsOneWidget,
        );

        // Route back: Detail -> LearningRoadmapScreen
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LearningRoadmapScreen), findsOneWidget);
      },
    );

    testWidgets(
      'KanjiDetailScreen stroke-order system back closes strokes before popping to Kanji library',
      (tester) async {
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.kanji,
        );

        router.push(AppRoutes.kanjiDetail(FixtureKanjiRepository.kenRouteKey));
        await tester.pumpAndSettle();
        expect(find.byType(KanjiDetailScreen), findsOneWidget);

        final strokeButton = find.byKey(
          const ValueKey<String>('kanji_open_strokes_button'),
        );
        await tester.scrollUntilVisible(
          strokeButton,
          240,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey<String>('kanji_detail_view')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(strokeButton);
        await tester.pumpAndSettle();
        await tester.tap(strokeButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('kanji_stroke_order_view')),
          findsOneWidget,
        );

        // First system Back closes stroke order stage
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('kanji_stroke_order_view')),
          findsNothing,
        );
        expect(find.byType(KanjiDetailScreen), findsOneWidget);

        // Second system Back pops to KanjiLibraryScreen
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(KanjiLibraryScreen), findsOneWidget);
      },
    );

    testWidgets(
      'DailyReviewScreen & MockTestScreen open as root focused overlays without bottom nav and pop cleanly',
      (tester) async {
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.practice,
        );

        router.push(AppRoutes.dailyReview);
        await tester.pumpAndSettle();
        expect(find.byType(DailyReviewScreen), findsOneWidget);
        expect(find.byType(SakuraBottomNavigation), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(PracticeScreen), findsOneWidget);
        expect(find.byType(SakuraBottomNavigation), findsOneWidget);

        router.push(AppRoutes.mockTest('731'));
        await tester.pumpAndSettle();
        expect(find.byType(MockTestScreen), findsOneWidget);
        expect(find.byType(SakuraBottomNavigation), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(PracticeScreen), findsOneWidget);
      },
    );
  });

  group('Calendar, Notifications & Push Role Deep Links', () {
    testWidgets(
      'LearnerCalendarScreen deep-linked backs to Home via header & system Back',
      (tester) async {
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.calendar,
        );

        expect(find.byType(LearnerCalendarScreen), findsOneWidget);
        expect(find.byKey(const Key('calendar_back_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('calendar_back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'MentorCalendarScreen standalone outside shell shows calendar_back_button and falls back to /mentor',
      (tester) async {
        final session = createTestAuthSession(role: BackendUserRole.mentor);
        final router = GoRouter(
          initialLocation: AppRoutes.mentorCalendar,
          routes: [
            GoRoute(
              path: AppRoutes.mentor,
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('mentor-home'))),
            ),
            GoRoute(
              path: AppRoutes.mentorCalendar,
              builder: (_, _) => const MentorCalendarScreen(),
            ),
          ],
        );
        addTearDown(session.dispose);
        addTearDown(router.dispose);

        await _pumpScopedRouter(
          tester,
          router: router,
          authSession: session,
        );

        expect(find.byType(MentorCalendarScreen), findsOneWidget);
        expect(find.byKey(const Key('calendar_back_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('calendar_back_button')));
        await tester.pumpAndSettle();
        expect(find.text('mentor-home'), findsOneWidget);
      },
    );

    testWidgets(
      'NotificationsScreen falls back to Home for Learner and MentorHome for Mentor',
      (tester) async {
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.notifications,
          authSession: createTestAuthSession(role: BackendUserRole.learner),
        );
        expect(find.byType(NotificationsScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);

        final mentorSession = createTestAuthSession(
          role: BackendUserRole.mentor,
        );
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.notifications,
          authSession: mentorSession,
        );
        expect(find.byType(NotificationsScreen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(MentorHomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'PushNotificationService resolves booking & dispute deep links by stored JWT role',
      (tester) async {
        final store = _InMemoryKeyValueStore();
        final storage = TokenStorage(store);
        await storage.saveAuthenticatedSession(
          accessToken: createTestJwt(userId: 42, role: 'Learner'),
          userId: 42,
          role: 'Learner',
        );
        final learnerSession = AuthSessionController(storage);
        await learnerSession.restore();

        final learnerRouter = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.home,
          authSession: learnerSession,
        );
        final pushService = PushNotificationService(
          apiClient: _NoopPushApiClient(),
          tokenStorage: storage,
        );
        addTearDown(pushService.dispose);

        await pushService.handleNotificationTap(
          learnerRouter,
          PushNotificationPayload.fromMap({
            'notification': {'title': 'Booking', 'body': 'Updated'},
            'data': {'screen': 'booking_detail', 'bookingId': '88'},
          }),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LearnerMyCoursesScreen), findsOneWidget);

        // Mentor role resolves to canonical Mentor cohort routes
        await storage.saveAuthenticatedSession(
          accessToken: createTestJwt(userId: 5, role: 'Mentor'),
          userId: 5,
          role: 'Mentor',
        );
        final mentorSession = AuthSessionController(storage);
        await mentorSession.restore();
        final mentorRouter = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.mentor,
          authSession: mentorSession,
        );

        await pushService.handleNotificationTap(
          mentorRouter,
          PushNotificationPayload.fromMap({
            'notification': {'title': 'Cohort', 'body': 'Confirmed'},
            'data': {'screen': 'booking_detail', 'bookingId': '88'},
          }),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MentorCohortsScreen), findsOneWidget);
      },
    );
  });

  group('Auth Subflow Back Parity', () {

    testWidgets(
      'Auth subflows Back parity: Register, deep-linked ForgotPassword & VerifyEmail -> Login, authenticated VerifyEmail hides login link',
      (tester) async {
        final session = createTestAuthSession(
          initialState: AuthSessionState.unauthenticated,
        );
        final router = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.login,
          authSession: session,
        );

        router.push(AppRoutes.register);
        await tester.pumpAndSettle();
        expect(find.byType(RegisterScreen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Deep-linked ForgotPassword falls back to Login
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.forgotPassword,
          authSession: createTestAuthSession(
            initialState: AuthSessionState.unauthenticated,
          ),
        );
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Deep-linked unauthenticated VerifyEmail shows login prompt & falls back to Login
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.verifyEmail,
          authSession: createTestAuthSession(
            initialState: AuthSessionState.unauthenticated,
          ),
        );
        expect(find.byType(VerifyEmailScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Authenticated Learner deep-linked on /profile/verify-email hides login CTA & backs to Profile
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileVerifyEmail,
          authSession: createTestAuthSession(role: BackendUserRole.learner),
        );
        expect(find.byType(VerifyEmailScreen), findsOneWidget);
        expect(find.text('Đã xác thực? Đăng nhập'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        // Pushed from AccountSettingsScreen returns back to AccountSettingsScreen
        final profileRouter = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileAccount,
          authSession: createTestAuthSession(role: BackendUserRole.learner),
        );
        expect(find.byType(AccountSettingsScreen), findsOneWidget);
        profileRouter.push(AppRoutes.profileVerifyEmail);
        await tester.pumpAndSettle();
        expect(find.byType(VerifyEmailScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsScreen), findsOneWidget);

        // Authenticated Mentor on /mentor/verify-email hides login CTA & backs to MentorProfile
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.mentorVerifyEmail,
          authSession: createTestAuthSession(role: BackendUserRole.mentor),
        );
        expect(find.byType(VerifyEmailScreen), findsOneWidget);
        expect(find.text('Đã xác thực? Đăng nhập'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(MentorProfileScreen), findsOneWidget);
      },
    );
  });

  group('Form Unsaved-Changes PopScope & Header Back Guards', () {
    testWidgets(
      'EditProfileScreen prompts discard only when dirty; header & system Back match',
      (tester) async {
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileEdit,
        );
        expect(find.byType(EditProfileScreen), findsOneWidget);

        // Edit first name field
        await tester.enterText(
          _textField('profile_first_name_field'),
          'Tên Đã Sửa',
        );
        await tester.pumpAndSettle();

        // Header BackButton triggers discard prompt
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsOneWidget);

        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileScreen), findsOneWidget);

        // Android system Back confirms leave -> exits to ProfileScreen
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsOneWidget);
        await tester.tap(find.text('Rời đi'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'ChangePasswordScreen guards dirty edits on both Learner & Mentor with role fallbacks',
      (tester) async {
        // Learner deep-linked clean back -> Profile; pushed from AccountSettings -> AccountSettings
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileChangePassword,
          authSession: createTestAuthSession(role: BackendUserRole.learner),
        );
        expect(find.byType(ChangePasswordScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        final accountRouter = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileAccount,
          authSession: createTestAuthSession(role: BackendUserRole.learner),
        );
        accountRouter.push(AppRoutes.profileChangePassword);
        await tester.pumpAndSettle();
        expect(find.byType(ChangePasswordScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsScreen), findsOneWidget);

        // Mentor dirty guard -> prompt -> confirm exits to MentorProfile
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.mentorChangePassword,
          authSession: createTestAuthSession(role: BackendUserRole.mentor),
        );
        expect(find.byType(ChangePasswordScreen), findsOneWidget);
        await tester.enterText(
          _textField('change_password_current_field'),
          'oldpass',
        );
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsOneWidget);
        await tester.tap(find.text('Rời đi'));
        await tester.pumpAndSettle();
        expect(find.byType(MentorProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'UpdateEmailScreen guards unsaved email before submit and skips prompt after successful save',
      (tester) async {
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileChangeEmail,
        );
        expect(find.byType(UpdateEmailScreen), findsOneWidget);

        await tester.enterText(
          _textField('update_email_field'),
          'updated@example.com',
        );
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsOneWidget);
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();

        // Submit -> saved -> next Back exits cleanly without prompt
        final submit = find.byKey(const Key('update_email_submit_button'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsNothing);
        expect(find.byType(ProfileScreen), findsOneWidget);

        final accountRouter = await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.profileAccount,
        );
        accountRouter.push(AppRoutes.profileChangeEmail);
        await tester.pumpAndSettle();
        expect(find.byType(UpdateEmailScreen), findsOneWidget);
        await tester.enterText(
          _textField('update_email_field'),
          'account-updated@example.com',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('update_email_submit_button')),
        );
        await tester.tap(find.byKey(const Key('update_email_submit_button')));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsScreen), findsOneWidget);
      },
    );

    testWidgets(
      'MentorProfileScreen(applicationMode: true) & standalone MentorAvailabilityScreen guard dirty changes',
      (tester) async {
        // Standalone MentorProfileScreen(applicationMode: true) with Learner role
        await _pumpRegressionRouter(
          tester,
          initialLocation: AppRoutes.mentorApplication,
          authSession: createTestAuthSession(role: BackendUserRole.learner),
        );
        expect(find.byType(MentorProfileScreen), findsOneWidget);

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Giới thiệu cố vấn mới');
          await tester.pumpAndSettle();

          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Hủy thay đổi?'), findsOneWidget);
          await tester.tap(find.text('Ở lại'));
          await tester.pumpAndSettle();
        }

        // Standalone MentorAvailabilityScreen (outside shell) + MentorScheduleV3Card dirty check
        final mentorSession = createTestAuthSession(
          role: BackendUserRole.mentor,
        );
        final standaloneRouter = GoRouter(
          initialLocation: AppRoutes.mentorAvailability,
          routes: [
            GoRoute(
              path: AppRoutes.mentorCalendar,
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('mentor-calendar'))),
            ),
            GoRoute(
              path: AppRoutes.mentorAvailability,
              builder: (_, _) => const MentorAvailabilityScreen(),
            ),
          ],
        );
        addTearDown(mentorSession.dispose);
        addTearDown(standaloneRouter.dispose);

        await _pumpScopedRouter(
          tester,
          router: standaloneRouter,
          authSession: mentorSession,
        );

        expect(find.byType(MentorAvailabilityScreen), findsOneWidget);
        final v3Switch = find.descendant(
          of: find.byKey(const Key('mentor_schedule_v3_card')),
          matching: find.byType(SwitchListTile),
        );
        await tester.scrollUntilVisible(
          v3Switch,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(v3Switch);
        await tester.pumpAndSettle();
        expect(v3Switch, findsOneWidget);
        await tester.ensureVisible(v3Switch);
        await tester.tap(v3Switch);
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsOneWidget);
        await tester.tap(find.text('Rời đi'));
        await tester.pumpAndSettle();
        expect(find.text('mentor-calendar'), findsOneWidget);
      },
    );
  });
}

Future<GoRouter> _pumpRegressionRouter(
  WidgetTester tester, {
  required String initialLocation,
  AuthSessionController? authSession,
  UserProfileRepository? profileRepository,
  bool settle = true,
}) async {
  final effectiveSession = authSession ?? createTestAuthSession();
  final router = createAppRouter(
    authSession: effectiveSession,
    initialLocation: initialLocation,
  );
  if (authSession == null) {
    addTearDown(effectiveSession.dispose);
  }
  addTearDown(router.dispose);

  await _pumpScopedRouter(
    tester,
    router: router,
    authSession: effectiveSession,
    profileRepository: profileRepository,
    settle: settle,
  );
  return router;
}

Future<void> _pumpScopedRouter(
  WidgetTester tester, {
  required GoRouter router,
  required AuthSessionController authSession,
  UserProfileRepository? profileRepository,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(const {
            'APP_ENV': 'development',
            'API_PROFILE': 'local-emulator',
          }),
        ),
        authSessionControllerProvider.overrideWithValue(authSession),
        authRepositoryProvider.overrideWithValue(_RegAuthRepository()),
        mentorRegistrationIntentProvider.overrideWithValue(
          MentorRegistrationIntent(TestJsonPreferenceStore()),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          profileRepository ?? _RegProfileRepository(),
        ),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        placementTestRepositoryProvider.overrideWithValue(
          _RegPlacementRepository(),
        ),
        homeRepositoryProvider.overrideWithValue(const FixtureHomeRepository()),
        learningRepositoryProvider.overrideWithValue(
          const FixtureLearningRepository(),
        ),
        learningPathRepositoryProvider.overrideWithValue(
          _RegLearningPathRepository(),
        ),
        standardRoadmapProvider.overrideWith(
          (ref) async => const StandardRoadmap(
            currentStudyLevelId: 101,
            currentStudyLevelName: 'N5',
            targetJlptLevelId: 204,
            targetJlptLevelName: 'N4',
            learningMode: LearningMode.standard,
            totalLessons: 1,
            completedLessons: 0,
            nextLessonId: 501,
            lessons: <StandardRoadmapLesson>[
              StandardRoadmapLesson(
                lessonId: 501,
                title: 'Bài 1',
                sortOrder: 1,
                progressPercent: 40,
                isCompleted: false,
              ),
            ],
          ),
        ),
        lessonRepositoryProvider.overrideWithValue(
          const FixtureLessonRepository(),
        ),
        lessonMediaDriverFactoryProvider.overrideWithValue(
          () => const FixtureLessonMediaDriver(),
        ),
        kanjiRepositoryProvider.overrideWithValue(
          const FixtureKanjiRepository(),
        ),
        analyticsRepositoryProvider.overrideWithValue(
          _RegAnalyticsRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          _RegNotificationRepository(),
        ),
        dailyReviewRepositoryProvider.overrideWithValue(
          const _RegDailyReviewRepository(),
        ),
        mockTestRepositoryProvider.overrideWithValue(
          TestLiveMockTestRepository(),
        ),
        practiceSessionRepositoryProvider.overrideWithValue(
          _RegPracticeSessionRepository(),
        ),
        jsonPreferenceStoreProvider.overrideWithValue(
          TestJsonPreferenceStore(),
        ),
        upcomingMeetingProvider.overrideWithValue(
          const AsyncData<UpcomingMeeting?>(null),
        ),
        demoNotebookRepositoryProvider.overrideWithValue(
          SessionDemoNotebookRepository(),
        ),
        notebookRepositoryProvider.overrideWithValue(_RegNotebookRepository()),
        learnerMyCoursesProvider.overrideWith(
          _StubLearnerMyCoursesController.new,
        ),
        mentorAssignedCohortsProvider.overrideWith((ref) async => const []),
        mentorRepositoryProvider.overrideWithValue(_RegMentorRepository()),
        mentorOperationsRepositoryProvider.overrideWithValue(
          _RegMentorOperationsRepository(),
        ),
        mentorScheduleV3RepositoryProvider.overrideWithValue(
          _RegMentorScheduleV3Repository(),
        ),
        mentorKpiRepositoryProvider.overrideWithValue(
          _RegMentorKpiRepository(),
        ),
        mentorMeetingLinkLauncherProvider.overrideWithValue(
          _NoopMeetingLinkLauncher(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Finder _textField(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
}

class _InMemoryKeyValueStore implements SecureKeyValueStore {
  final Map<String, String?> _values = <String, String?>{};

  @override
  Future<void> delete({required String key}) async => _values.remove(key);

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String? value}) async =>
      _values[key] = value;
}

class _NoopPushApiClient extends ApiClient {
  _NoopPushApiClient() : super(Dio(), const ApiErrorMapper());
}

class _NoopMeetingLinkLauncher implements MentorMeetingLinkLauncher {
  @override
  Future<bool> open(Uri uri) async => true;
}

class _RegAuthRepository implements AuthRepository {
  @override
  Future<void> changePassword(
    int userId,
    ChangePasswordRequestDto request,
  ) async {}

  @override
  Future<LoginResponseDto> login(
    LoginRequestDto request, {
    required bool persistSession,
  }) => throw UnimplementedError();

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> resendVerificationEmail(
    ResendVerificationEmailRequestDto request,
  ) async {}

  @override
  Future<void> updateEmail(int userId, UpdateEmailRequestDto request) async {}

  @override
  Future<void> verifyEmail(VerifyEmailRequestDto request) async {}
}

class _RegProfileRepository
    implements
        UserProfileRepository,
        TargetExamDateProfileRepository,
        ClearTargetExamDateProfileRepository,
        StudyLevelProfileRepository,
        AtomicLearningGoalProfileRepository {
  _RegProfileRepository({this.withGoal = true})
    : _currentStudyLevelId = withGoal ? 101 : null,
      _targetJlptLevelId = withGoal ? 204 : null,
      _dailyStudyMinutes = withGoal ? 30 : 0,
      _targetExamDate = withGoal ? DateTime.utc(2027, 7, 4) : null;

  static const Map<int, String> _levelNames = <int, String>{
    101: 'N5',
    204: 'N4',
    309: 'N3',
    418: 'N2',
    527: 'N1',
  };

  final bool withGoal;
  String _firstName = 'Minh Anh';
  String _lastName = 'Nguyễn';
  int? _currentStudyLevelId;
  int? _targetJlptLevelId;
  int _dailyStudyMinutes;
  DateTime? _targetExamDate;
  int? _certifiedJlptLevelId;
  int _learningGoalVersion = 1;

  String? _levelNameFor(int? levelId) =>
      levelId == null ? null : _levelNames[levelId];

  UserProfile _build() {
    return UserProfile(
      userId: 42,
      email: 'learner@example.com',
      firstName: _firstName,
      lastName: _lastName,
      avatarUrl: null,
      role: 'Learner',
      isEmailVerified: true,
      currentStudyLevelId: _currentStudyLevelId,
      currentStudyLevelName: _levelNameFor(_currentStudyLevelId),
      targetJlptLevelId: _targetJlptLevelId,
      targetJlptLevelName: _levelNameFor(_targetJlptLevelId),
      dailyStudyMinutes: _dailyStudyMinutes,
      targetExamDate: _targetExamDate,
      learningGoalVersion: _learningGoalVersion,
      certifiedJlptLevelId: _certifiedJlptLevelId,
      certifiedJlptLevelName: _levelNameFor(_certifiedJlptLevelId),
      emailNotificationsEnabled: true,
      systemNotificationsEnabled: true,
    );
  }

  @override
  Future<UserProfile> loadProfile() async => _build();

  @override
  Future<UserProfile> switchStudyLevel({
    required int currentStudyLevelId,
  }) async {
    _currentStudyLevelId = currentStudyLevelId;
    _learningGoalVersion += 1;
    return _build();
  }

  @override
  Future<UserProfile> saveLearningGoal({
    required int currentStudyLevelId,
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime? targetExamDate,
    required int? certifiedJlptLevelId,
    required int expectedVersion,
  }) async {
    _currentStudyLevelId = currentStudyLevelId;
    _targetJlptLevelId = targetJlptLevelId;
    _dailyStudyMinutes = dailyStudyMinutes;
    _targetExamDate = targetExamDate;
    _certifiedJlptLevelId = certifiedJlptLevelId;
    _learningGoalVersion += 1;
    return _build();
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    _targetJlptLevelId = targetJlptLevelId;
    _dailyStudyMinutes = dailyStudyMinutes;
    _learningGoalVersion += 1;
    return _build();
  }

  @override
  Future<UserProfile> setJlptGoalWithExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime targetExamDate,
  }) async {
    _targetJlptLevelId = targetJlptLevelId;
    _dailyStudyMinutes = dailyStudyMinutes;
    _targetExamDate = targetExamDate;
    _learningGoalVersion += 1;
    return _build();
  }

  @override
  Future<UserProfile> clearJlptGoalExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    _targetJlptLevelId = targetJlptLevelId;
    _dailyStudyMinutes = dailyStudyMinutes;
    _targetExamDate = null;
    _learningGoalVersion += 1;
    return _build();
  }

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => _build();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    _firstName = firstName;
    _lastName = lastName;
    return _build();
  }

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async => _build();
}

class _RegPlacementRepository
    implements PlacementTestRepository, PlacementSkipRepository {
  PlacementDecision _decision = PlacementDecision.notTaken;

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<PlacementTestStatus> loadStatus() async => PlacementTestStatus(
    hasCompletedPlacementTest: false,
    placementDecision: _decision,
  );

  @override
  Future<PlacementTestStatus> skip() async {
    _decision = PlacementDecision.skipped;
    return loadStatus();
  }

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();
}

class _RegLearningPathRepository
    implements LearningPathRepository, LearningPathVersionRepository {
  @override
  Future<RecommendedLearningPath> cancelPreview(int pathId) =>
      throw UnimplementedError();

  @override
  Future<RecommendedLearningPath> confirmPreview(int pathId) =>
      throw UnimplementedError();

  @override
  Future<RecommendedLearningPath> generate() => throw UnimplementedError();

  @override
  Future<RecommendedLearningPath?> loadActive() async => null;

  @override
  Future<List<RecommendedLearningPath>> loadHistory() async => const [];

  @override
  Future<RecommendedLearningPath?> loadLatest() async => null;

  @override
  Future<RecommendedLearningPath> preview({
    required int startingJlptLevelId,
    int? targetJlptLevelId,
  }) => throw UnimplementedError();
}

class _RegAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<LearnerAnalytics> loadLearnerAnalytics() async =>
      const LearnerAnalytics(
        streakDays: 4,
        completedLessons: 7,
        totalLessons: 20,
        skills: <SkillBreakdown>[
          SkillBreakdown(skill: 'Kanji', averageScore: 30, attemptCount: 10),
        ],
      );
}

class _RegNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => const [];

  @override
  Future<int> loadUnreadCount() async => 0;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

class _RegDailyReviewRepository implements DailyReviewRepository {
  const _RegDailyReviewRepository();

  @override
  Future<DailyReviewQueue> loadDailyQueue() async =>
      const DailyReviewQueue(totalDue: 0, items: <DailyReviewCard>[]);

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) => throw UnimplementedError();
}

class _RegPracticeSessionRepository implements PracticeSessionRepository {
  DemoPracticeSessions? _sessions;

  @override
  Future<DemoPracticeSessions?> load({
    required List<DemoReviewCard> reviewCards,
    required DemoMockTest mockTest,
  }) async =>
      _sessions ??
      DemoPracticeSessions(
        reviewSession: DemoReviewSession(cards: reviewCards),
      );

  @override
  Future<void> reset() async => _sessions = null;

  @override
  Future<void> save(DemoPracticeSessions sessions) async => _sessions = sessions;
}

class _RegNotebookRepository implements NotebookRepository {
  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  }) => throw UnimplementedError();

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) => throw UnimplementedError();

  @override
  Future<bool> isVocabularySaved(String vocabularyRouteKey) async => false;

  @override
  Future<List<NotebookCollection>> loadCollections() async => const [];

  @override
  Future<List<NotebookEntry>> loadEntries(
    NotebookCollection collection,
  ) async => const [];

  @override
  Future<void> removeEntry(NotebookEntry entry) async {}

  @override
  Stream<Set<String>> watchSavedVocabularyKeys() => Stream.value(const {});
}

class _StubLearnerMyCoursesController extends LearnerMyCoursesController {
  @override
  Future<List<LearnerStudyCourseDetail>> build() async => const [];
}

class _RegMentorRepository implements MentorRepository {
  static const _profile = MentorProfileData(
    mentorId: 5,
    email: 'mentor@rikipath.local',
    firstName: 'Tanaka',
    lastName: 'Sensei',
    jlptLevel: 'N2',
    verificationStatus: 'Approved',
    isBookable: true,
    hasVerificationDocument: true,
  );

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async => [
    MentorAvailabilitySlot(
      id: 501,
      startTime: MentorTimestamp.parse('2026-11-20T18:00:00+07:00'),
      endTime: MentorTimestamp.parse('2026-11-20T19:30:00+07:00'),
      isBooked: false,
      isApproved: true,
    ),
  ];

  @override
  Future<MentorProfileData> loadProfile() async => _profile;

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(
    DateTime weekStart,
  ) async => const [];

  @override
  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async => _profile;

  @override
  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async => _profile;

  @override
  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async => _profile;
}

class _RegMentorOperationsRepository implements MentorOperationsRepository {
  @override
  Future<MentorRoomAccessStatus> checkRoomAccess(String roomId) async =>
      MentorRoomAccessStatus(roomId: roomId, canAccess: true, isRoomReady: true);

  @override
  Future<MentorVerificationDocumentData> loadVerificationDocument() async =>
      MentorVerificationDocumentData(
        bytes: Uint8List.fromList(const [137, 80, 78, 71]),
        contentType: 'image/png',
      );
}

class _RegMentorScheduleV3Repository implements MentorScheduleV3Repository {
  @override
  Future<void> deleteAvailability(int availabilityId) async {}

  @override
  Future<MentorScheduleV3> loadSchedule() async => MentorScheduleV3(
    scheduleId: 15,
    mentorId: 5,
    mentorName: 'Tanaka Sensei',
    policyVersion: 3,
    timeZoneId: 'Asia/Ho_Chi_Minh',
    autoPublish: true,
    effectiveFrom: DateTime.utc(2026, 11, 15),
    generatedThrough: DateTime.utc(2026, 11, 29),
    createdAtUtc: MentorTimestamp.parse('2026-11-01T00:00:00Z'),
    rules: [
      MentorScheduleRule(
        id: 71,
        scheduleId: 15,
        weekday: 1,
        weekdayName: 'Monday',
        daypart: MentorDaypart.evening,
        localStart: '18:00',
        localEnd: '22:00',
        effectiveFrom: DateTime.utc(2026, 11, 15),
      ),
    ],
  );

  @override
  Future<MentorSlotPreviewResult> previewSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async => MentorSlotPreviewResult(
    totalCandidateSlots: 1,
    existingSlotsCount: 0,
    newSlotsCount: 1,
    conflictSlotsCount: 0,
    startDate: startDate,
    endDate: endDate,
    slots: const [],
  );

  @override
  Future<MentorPublishSlotsResult> publishSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async => MentorPublishSlotsResult(
    createdCount: 1,
    skippedExistingCount: 0,
    totalSlotsProcessed: 1,
    generatedThrough: endDate,
    publishedSlots: const [],
  );

  @override
  Future<void> requestCancelAvailabilities(
    List<int> ids, {
    String? reason,
  }) async {}

  @override
  Future<void> requestSlotChange(int slotId, String reason) async {}

  @override
  Future<MentorScheduleV3> updateSchedule(
    UpdateMentorScheduleV3Request request,
  ) async => loadSchedule();
}

class _RegMentorKpiRepository implements MentorKpiRepository {
  @override
  Future<MentorKpiSummary> loadSummary({
    String? fromDate,
    String? toDate,
  }) async =>
      MentorKpiSummary(
        mentorId: 5,
        mentorName: 'Tanaka Sensei',
        fromDate: fromDate ?? '2026-10-01',
        toDate: toDate ?? '2026-11-16',
      );
}
