import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/account_settings_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/data/profile_avatar_picker.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_components.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_ja.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

import '../../support/test_jlpt_catalog.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('shows controlled loading and API-backed success data', (
      tester,
    ) async {
      final completer = Completer<UserProfile>();
      final repository = _ProfileRepository(loadCompleter: completer);
      await _pump(tester, const ProfileScreen(), repository: repository);

      expect(
        find.byKey(const ValueKey<String>('profile_loading_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_hero_skeleton')),
        findsOneWidget,
      );
      completer.complete(_profile());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_success_view')),
        findsOneWidget,
      );
      expect(find.text('Minh Anh Nguyễn'), findsOneWidget);
      expect(find.text('learner@example.com'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('profile_hero_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_learning_snapshot')),
        findsNothing,
      );
      expect(find.text('Hồ sơ học tập'), findsNothing);
      expect(repository.loadCalls, 1);
    });

    testWidgets('uses the avatar fallback when no API image is available', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_avatar_fallback')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_avatar_image')),
        findsNothing,
      );
    });

    testWidgets('shows verified and unverified email states with labels', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(profile: _profile()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_verified_status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_summary_verification')),
        findsNothing,
      );

      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(
          profile: _profile(isEmailVerified: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_unverified_status')),
        findsOneWidget,
      );
      expect(find.text('Chưa xác thực'), findsWidgets);
    });

    testWidgets('missing JLPT goal keeps its learning action available', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(
          profile: _profile(targetJlptLevelId: null, targetJlptLevelName: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_jlpt_goal_action')),
        findsOneWidget,
      );
      expect(find.text('Hồ sơ học tập'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('renders grouped premium action tiles without fake metrics', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(),
      );
      await tester.pumpAndSettle();

      final expectedIcons = <String, SakuraColorfulIconType>{
        'profile_jlpt_goal_action': SakuraColorfulIconType.learningGoal,
        'profile_placement_test_action': SakuraColorfulIconType.placementTest,
        'profile_progress_action': SakuraColorfulIconType.learningProgress,
        'profile_mentor_application_action':
            SakuraColorfulIconType.mentorApplication,
        'profile_edit_action': SakuraColorfulIconType.editProfile,
        'profile_settings_action': SakuraColorfulIconType.settings,
        'profile_logout_action': SakuraColorfulIconType.logout,
      };
      for (final entry in expectedIcons.entries) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey<String>(entry.key)),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        final tile = tester.widget<ProfileActionTile>(
          find.byKey(ValueKey<String>(entry.key)),
        );
        expect(tile.colorfulIcon, entry.value);
        final icon = tester.widget<SakuraColorfulIcon>(
          find.descendant(
            of: find.byKey(ValueKey<String>(entry.key)),
            matching: find.byType(SakuraColorfulIcon),
          ),
        );
        expect(icon.type, entry.value);
        expect(icon.useEmoji, entry.value != SakuraColorfulIconType.logout);
      }

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('profile_consultation_action')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      final consultationTile = tester.widget<ProfileActionTile>(
        find.byKey(const ValueKey<String>('profile_consultation_action')),
      );
      expect(
        consultationTile.colorfulIcon,
        SakuraColorfulIconType.consultation,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('profile_consultation_action')),
          matching: find.byType(SakuraColorfulIcon),
        ),
        findsOneWidget,
      );
      expect(find.text('🧑‍🏫'), findsOneWidget);
      expect(consultationTile.emphasized, isTrue);

      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('xếp hạng'), findsNothing);
      expect(find.textContaining('chuỗi học'), findsNothing);
      expect(find.text('Lớp học nhóm của tôi'), findsOneWidget);
      expect(
        find.text('Xem lịch buổi học, bài tập về nhà và điểm danh'),
        findsOneWidget,
      );
      expect(find.text('Khám phá'), findsNothing);
    });

    testWidgets(
      'profile menu cards use borderless white surfaces, soft elevation, and neutral dividers',
      (tester) async {
        await _pump(
          tester,
          const ProfileScreen(),
          repository: _ProfileRepository(),
        );
        await tester.pumpAndSettle();

        final heroContainer = tester.widget<Container>(
          find.byKey(const ValueKey<String>('profile_hero_card')),
        );
        final heroDecoration = heroContainer.decoration! as BoxDecoration;
        expect(heroDecoration.color, AppColors.surface);
        expect(heroDecoration.border, isNull);
        expect(heroDecoration.borderRadius, BorderRadius.circular(19));
        expect(heroDecoration.boxShadow, AppShadows.profileCard);

        final sectionFinders = find.byType(ProfileSection);
        expect(sectionFinders, findsWidgets);
        for (final element in sectionFinders.evaluate()) {
          final decoratedBox = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byWidget(element.widget),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final boxDecoration = decoratedBox.decoration as BoxDecoration;
          expect(boxDecoration.color, AppColors.surface);
          expect(boxDecoration.border, isNull);
          expect(boxDecoration.borderRadius, BorderRadius.circular(19));
          expect(boxDecoration.boxShadow, AppShadows.profileCard);
        }

        final dividers = tester.widgetList<Divider>(find.byType(Divider));
        for (final divider in dividers) {
          expect(divider.color, const Color(0xFFEFEDEE));
          expect(divider.thickness, 0.7);
          expect(divider.indent, 70);
        }
      },
    );

    for (final width in <double>[360, 393, 412]) {
      testWidgets(
        'profile menu cards render cleanly without overflow at ${width.toInt()}dp',
        (tester) async {
          await _pump(
            tester,
            const ProfileScreen(),
            repository: _ProfileRepository(),
            size: Size(width, 852),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byKey(const ValueKey<String>('profile_success_view')),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('error state retries without exposing raw exception text', (
      tester,
    ) async {
      final repository = _ProfileRepository(
        loadErrors: <Object>[const NetworkError(message: 'raw transport')],
      );
      await _pump(tester, const ProfileScreen(), repository: repository);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_error_view')),
        findsOneWidget,
      );
      expect(find.textContaining('raw transport'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_retry_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_success_view')),
        findsOneWidget,
      );
      expect(repository.loadCalls, 2);
    });

    testWidgets('renders Japanese labels and does not overflow at 320px', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(),
        locale: const Locale('ja'),
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_jlpt_goal_action')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('profile_edit_action')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('プロフィールを編集'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at a large phone width', (tester) async {
      await _pump(
        tester,
        const ProfileScreen(),
        repository: _ProfileRepository(),
        size: const Size(430, 932),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey<String>('profile_success_view')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('edit action keeps the existing Profile route', (tester) async {
      await _pumpProfileRouter(tester, repository: _ProfileRepository());
      await tester.pumpAndSettle();
      final editAction = find.byKey(
        const ValueKey<String>('profile_edit_action'),
      );
      await tester.scrollUntilVisible(
        editAction,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(editAction);
      await tester.pumpAndSettle();

      await tester.tap(editAction);
      await tester.pumpAndSettle();

      expect(find.text('profile-edit-route'), findsOneWidget);
    });

    testWidgets('Placement remains reachable after onboarding', (tester) async {
      await _pumpProfileRouter(tester, repository: _ProfileRepository());
      await tester.pumpAndSettle();
      final placementAction = find.byKey(
        const ValueKey<String>('profile_placement_test_action'),
      );
      await tester.ensureVisible(placementAction);
      await tester.tap(placementAction);
      await tester.pumpAndSettle();

      expect(find.text('placement-test-route'), findsOneWidget);
    });

    testWidgets(
      'logout action shows confirmation sheet and executes sign out',
      (tester) async {
        var signedOut = false;
        final authSessionController = _TestAuthSessionController(
          onSignOut: () => signedOut = true,
        );
        await _pump(
          tester,
          const ProfileScreen(),
          repository: _ProfileRepository(),
          authSessionController: authSessionController,
        );
        await tester.pumpAndSettle();

        final logoutAction = find.byKey(
          const ValueKey<String>('profile_logout_action'),
        );
        await tester.scrollUntilVisible(
          logoutAction,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(logoutAction);
        await tester.pumpAndSettle();
        await tester.tap(logoutAction);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
        );
        await tester.pumpAndSettle();

        expect(signedOut, isTrue);
        expect(
          find.byKey(const ValueKey<String>('riki_toast_success')),
          findsOneWidget,
        );
        expect(find.text('Đã đăng xuất'), findsOneWidget);
        expect(
          find.text('Hẹn gặp lại trên hành trình học tiếng Nhật!'),
          findsOneWidget,
        );
      },
    );
  });

  group('EditProfileScreen', () {
    testWidgets('validates fullName field locally', (
      tester,
    ) async {
      final repository = _ProfileRepository();
      await _pump(tester, const EditProfileScreen(), repository: repository);
      await tester.pumpAndSettle();
      await tester.enterText(_field('profile_full_name_field'), '');

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_save_button')),
      );
      await tester.pump();

      expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
      expect(repository.updateCalls, 0);
    });

    testWidgets('submits fullName and publishes the returned profile', (
      tester,
    ) async {
      final completer = Completer<UserProfile>();
      final repository = _ProfileRepository(updateCompleter: completer);
      await _pump(tester, const EditProfileScreen(), repository: repository);
      await tester.pumpAndSettle();
      await tester.enterText(_field('profile_full_name_field'), 'Sato Aiko');

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_save_button')),
      );
      await tester.pump();

      expect(find.text('Đang lưu...'), findsOneWidget);
      expect(repository.lastFullName, 'Sato Aiko');

      completer.complete(_profile(fullName: 'Sato Aiko'));
      await tester.pumpAndSettle();
      expect(find.text('Cập nhật hồ sơ thành công'), findsOneWidget);
    });

    testWidgets('confirms supported avatar before upload and refreshes state', (
      tester,
    ) async {
      final repository = _ProfileRepository();
      final picker = _AvatarPicker(_avatarUpload());
      await _pump(
        tester,
        const EditProfileScreen(),
        repository: repository,
        picker: picker,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_avatar_action')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('avatar_preview')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('avatar_confirm_upload')),
      );
      await tester.pumpAndSettle();

      expect(repository.uploadCalls, 1);
      expect(repository.lastUpload?.contentType, 'image/png');
      expect(find.text('Cập nhật ảnh đại diện thành công'), findsOneWidget);
    });

    testWidgets('avatar upload failure is localized and controlled', (
      tester,
    ) async {
      final repository = _ProfileRepository(
        uploadError: const NetworkError(message: 'raw avatar error'),
      );
      await _pump(
        tester,
        const EditProfileScreen(),
        repository: repository,
        picker: _AvatarPicker(_avatarUpload()),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_avatar_action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('avatar_confirm_upload')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Không thể kết nối mạng'), findsOneWidget);
      expect(find.textContaining('raw avatar error'), findsNothing);
    });

    testWidgets('Japanese edit form remains usable at 320px', (tester) async {
      await _pump(
        tester,
        const EditProfileScreen(),
        repository: _ProfileRepository(),
        locale: const Locale('ja'),
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('profile_save_button')),
        220,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('プロフィールを編集'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AccountSettingsScreen', () {
    testWidgets('exposes change password and omits duplicate logout', (
      tester,
    ) async {
      await _pump(
        tester,
        const AccountSettingsScreen(),
        repository: _ProfileRepository(),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('account_change_email_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('account_change_password_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('account_logout_button')),
        findsNothing,
      );
      final expectedIcons = <String, SakuraColorfulIconType>{
        'account_change_password_action': SakuraColorfulIconType.password,
        'account_language_settings_action': SakuraColorfulIconType.language,
        'account_notification_settings_action':
            SakuraColorfulIconType.notifications,
      };
      for (final entry in expectedIcons.entries) {
        final tile = tester.widget<ProfileSettingsTile>(
          find.byKey(ValueKey<String>(entry.key)),
        );
        expect(tile.colorfulIcon, entry.value);
      }
    });

    testWidgets('Japanese account groups fit a narrow 320px screen', (
      tester,
    ) async {
      await _pump(
        tester,
        const AccountSettingsScreen(),
        repository: _ProfileRepository(),
        locale: const Locale('ja'),
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey<String>('account_notification_settings_action'),
        ),
        240,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('セキュリティ'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
      expect(find.text('セッション'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('NotificationSettingsScreen', () {
    testWidgets('successful immediate save updates the supported toggle', (
      tester,
    ) async {
      final repository = _ProfileRepository();
      await _pump(
        tester,
        const NotificationSettingsScreen(),
        repository: repository,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('email_notifications_switch')),
      );
      await tester.pumpAndSettle();

      expect(repository.notificationCalls, 1);
      expect(repository.lastEmailNotifications, isFalse);
      expect(repository.lastSystemNotifications, isFalse);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(
                  const ValueKey<String>('email_notifications_switch'),
                ),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('failed immediate save keeps the previous toggle value', (
      tester,
    ) async {
      final repository = _ProfileRepository(
        notificationError: const NetworkError(),
      );
      await _pump(
        tester,
        const NotificationSettingsScreen(),
        repository: repository,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('email_notifications_switch')),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(
                  const ValueKey<String>('email_notifications_switch'),
                ),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isTrue,
      );
      expect(find.textContaining('Không thể kết nối mạng'), findsOneWidget);
    });

    testWidgets('Japanese preferences fit a narrow 320px screen', (
      tester,
    ) async {
      await _pump(
        tester,
        const NotificationSettingsScreen(),
        repository: _ProfileRepository(),
        locale: const Locale('ja'),
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();

      expect(find.text('通知設定'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('JlptGoalScreen', () {
    testWidgets('missing persisted goal opens create onboarding', (
      tester,
    ) async {
      final repository = _ProfileRepository(
        profile: _profile(targetJlptLevelId: null, targetJlptLevelName: null),
      );
      final router = GoRouter(
        initialLocation: AppRoutes.profileJlptGoal,
        routes: [
          GoRoute(
            path: AppRoutes.profileJlptGoal,
            builder: (context, state) => const JlptGoalScreen(),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) =>
                const Scaffold(body: Text('create-onboarding-route')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: supportedAppLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('create-onboarding-route'), findsOneWidget);
      expect(find.byType(JlptGoalScreen), findsNothing);
      expect(repository.jlptCalls, 0);
    });
    testWidgets('valid goal shows a read-only summary and one edit entry', (
      tester,
    ) async {
      final repository = _ProfileRepository(profile: _profile(noTargetExamDate: true));
      await _pump(tester, const JlptGoalScreen(), repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('Chưa thiết lập'), findsWidgets);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey<String>('jlpt_goal_edit_button')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('jlpt_goal_save_button')), findsNothing);
      expect(repository.jlptCalls, 0);
    });

    testWidgets(
      'profile load error shows Error State and Retry without redirecting to create wizard',
      (tester) async {
        final repository = _ProfileRepository(
          loadErrors: <Object>[const NetworkError(message: 'timeout')],
        );
        await _pump(tester, const JlptGoalScreen(), repository: repository);
        await tester.pumpAndSettle();

        expect(find.byType(RikiErrorBanner), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('profile_jlpt_create_redirect')),
          findsNothing,
        );

        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(find.byType(RikiErrorBanner), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
          findsOneWidget,
        );
        expect(repository.loadCalls, 2);
      },
    );

    testWidgets('goal summary remains usable at 320px', (tester) async {
      await _pump(
        tester,
        const JlptGoalScreen(),
        repository: _ProfileRepository(),
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  test('new Profile strings are generated for both supported locales', () {
    final vi = AppLocalizationsVi();
    final ja = AppLocalizationsJa();

    expect(vi.profileEdit, isNotEmpty);
    expect(vi.notificationSettingsTitle, isNotEmpty);
    expect(vi.jlptGoalMappingUnavailableMessage, isNotEmpty);
    expect(ja.profileEdit, isNotEmpty);
    expect(ja.notificationSettingsTitle, isNotEmpty);
    expect(ja.jlptGoalMappingUnavailableMessage, isNotEmpty);
    expect(vi.profileServicesSection, isNotEmpty);
    expect(ja.profileServicesSection, isNotEmpty);
    expect(vi.logoutConfirmationTitle, isNotEmpty);
    expect(ja.logoutConfirmationTitle, isNotEmpty);
    expect(vi.profileConsultationSubtitle, isNotEmpty);
    expect(ja.profileConsultationSubtitle, isNotEmpty);
  });

  test('Profile presentation contains no fake fields or legacy brand red', () {
    final source = <String>[
      File(
        'lib/features/profile/presentation/profile_screen.dart',
      ).readAsStringSync(),
      File(
        'lib/features/profile/presentation/widgets/profile_components.dart',
      ).readAsStringSync(),
    ].join().toLowerCase();

    for (final unsupported in <String>[
      'b7131a',
      'ranking',
      'lesson count',
      'study hours',
      'date of birth',
      'biography',
    ]) {
      expect(source, isNot(contains(unsupported)));
    }
    expect(AppColors.profileBackground, const Color(0xFFF7F6F7));
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required UserProfileRepository repository,
  ProfileAvatarPicker? picker,
  AuthSessionController? authSessionController,
  Locale locale = const Locale('vi'),
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repository),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        if (picker != null)
          profileAvatarPickerProvider.overrideWithValue(picker),
        if (authSessionController != null)
          authSessionControllerProvider.overrideWithValue(
            authSessionController,
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        builder: (context, child) =>
            RikiToastHost(child: child ?? const SizedBox.shrink()),
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpProfileRouter(
  WidgetTester tester, {
  required UserProfileRepository repository,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: AppRoutes.profile,
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.profileEditSegment,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('profile-edit-route'))),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.placementTest,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('placement-test-route'))),
      ),
      GoRoute(
        path: AppRoutes.learnProgress,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('learn-progress-route'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

Finder _field(String key) {
  return find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(TextField),
  );
}

UserProfile _profile({
  String? fullName,
  String firstName = 'Minh Anh',
  String lastName = 'Nguyễn',
  bool isEmailVerified = true,
  int? targetJlptLevelId = 309,
  String? targetJlptLevelName = 'N3',
  int dailyStudyMinutes = 30,
  DateTime? targetExamDate,
  bool noTargetExamDate = false,
  bool emailNotifications = true,
  bool systemNotifications = false,
  String? avatarUrl,
}) {
  return UserProfile(
    userId: 42,
    email: 'learner@example.com',
    fullName: fullName,
    firstName: firstName,
    lastName: lastName,
    avatarUrl: avatarUrl,
    role: 'Learner',
    isEmailVerified: isEmailVerified,
    targetJlptLevelId: targetJlptLevelId,
    targetJlptLevelName: targetJlptLevelName,
    currentStudyLevelId: 101,
    currentStudyLevelName: 'N5',
    dailyStudyMinutes: dailyStudyMinutes,
    targetExamDate: noTargetExamDate
        ? null
        : targetExamDate ?? DateTime(2030, 12, 1),
    emailNotificationsEnabled: emailNotifications,
    systemNotificationsEnabled: systemNotifications,
  );
}

ProfileAvatarUpload _avatarUpload() {
  return ProfileAvatarUpload(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    fileName: 'avatar.png',
    contentType: 'image/png',
  );
}

class _AvatarPicker implements ProfileAvatarPicker {
  const _AvatarPicker(this.upload);

  final ProfileAvatarUpload upload;

  @override
  Future<ProfileAvatarUpload?> pickFromGallery() async => upload;
}

class _ProfileRepository
    implements UserProfileRepository, ClearTargetExamDateProfileRepository {
  _ProfileRepository({
    this.profile,
    this.loadCompleter,
    this.updateCompleter,
    this.uploadError,
    this.notificationError,
    List<Object>? loadErrors,
  }) : _loadErrors = loadErrors ?? <Object>[];

  final UserProfile? profile;
  final Completer<UserProfile>? loadCompleter;
  final Completer<UserProfile>? updateCompleter;
  final Object? uploadError;
  final Object? notificationError;
  final List<Object> _loadErrors;

  int loadCalls = 0;
  int updateCalls = 0;
  int uploadCalls = 0;
  int notificationCalls = 0;
  int jlptCalls = 0;
  int clearExamDateCalls = 0;
  int? lastJlptLevelId;
  int? lastDailyStudyMinutes;
  String? lastFullName;
  ProfileAvatarUpload? lastUpload;
  bool? lastEmailNotifications;
  bool? lastSystemNotifications;

  @override
  Future<UserProfile> loadProfile() async {
    loadCalls += 1;
    if (_loadErrors.isNotEmpty) throw _loadErrors.removeAt(0);
    return loadCompleter?.future ?? profile ?? _profile();
  }

  @override
  Future<UserProfile> updateProfile({required String fullName}) {
    updateCalls += 1;
    lastFullName = fullName;
    return updateCompleter?.future ??
        Future<UserProfile>.value(_profile(fullName: fullName));
  }

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async {
    uploadCalls += 1;
    lastUpload = upload;
    if (uploadError != null) throw uploadError!;
    return _profile(avatarUrl: 'https://cdn.example.test/new-avatar.png');
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    jlptCalls += 1;
    lastJlptLevelId = targetJlptLevelId;
    lastDailyStudyMinutes = dailyStudyMinutes;
    final level = testJlptCatalog
        .where((item) => item.id == targetJlptLevelId)
        .firstOrNull;
    return _profile(
      targetJlptLevelId: targetJlptLevelId,
      targetJlptLevelName: level?.code,
      dailyStudyMinutes: dailyStudyMinutes,
      noTargetExamDate: profile != null && profile!.targetExamDate == null,
    );
  }

  @override
  Future<UserProfile> clearJlptGoalExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    clearExamDateCalls++;
    final level = testJlptCatalog
        .where((item) => item.id == targetJlptLevelId)
        .firstOrNull;
    return _profile(
      targetJlptLevelId: targetJlptLevelId,
      targetJlptLevelName: level?.code,
      dailyStudyMinutes: dailyStudyMinutes,
      noTargetExamDate: true,
    );
  }

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async {
    notificationCalls += 1;
    lastEmailNotifications = emailNotificationsEnabled;
    lastSystemNotifications = systemNotificationsEnabled;
    if (notificationError != null) throw notificationError!;
    return _profile(
      emailNotifications: emailNotificationsEnabled,
      systemNotifications: systemNotificationsEnabled,
    );
  }
}

class _FakeSecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String?> _store = {};

  @override
  Future<void> delete({required String key}) async => _store.remove(key);

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String? value}) async =>
      _store[key] = value;
}

class _TestAuthSessionController extends AuthSessionController {
  _TestAuthSessionController({this.onSignOut})
    : super(TokenStorage(_FakeSecureKeyValueStore()));

  final VoidCallback? onSignOut;

  @override
  Future<void> signOut({Future<void> Function()? onBeforeClear}) async {
    onSignOut?.call();
    await super.signOut(onBeforeClear: onBeforeClear);
  }
}
