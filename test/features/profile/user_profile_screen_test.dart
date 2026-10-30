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
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
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

      for (final key in <String>[
        'profile_jlpt_goal_action',
        'profile_placement_test_action',
        'profile_progress_action',
        'profile_edit_action',
        'profile_settings_action',
        'profile_consultation_action',
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey<String>(key)),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
      }

      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('xếp hạng'), findsNothing);
      expect(find.textContaining('chuỗi học'), findsNothing);
      expect(find.text('Học cùng Mentor'), findsOneWidget);
      expect(
        find.text('Khám phá gói học 1-1 và lịch học của bạn.'),
        findsOneWidget,
      );
      final consultationTile = tester.widget<ProfileActionTile>(
        find.byKey(const ValueKey<String>('profile_consultation_action')),
      );
      expect(consultationTile.emphasized, isTrue);
      expect(find.text('Khám phá'), findsNothing);
    });

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
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('profile_edit_action')),
        220,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_edit_action')),
      );
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
  });

  group('EditProfileScreen', () {
    testWidgets('validates both exact backend name fields locally', (
      tester,
    ) async {
      final repository = _ProfileRepository();
      await _pump(tester, const EditProfileScreen(), repository: repository);
      await tester.pumpAndSettle();
      await tester.enterText(_field('profile_last_name_field'), '');
      await tester.enterText(_field('profile_first_name_field'), '');

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_save_button')),
      );
      await tester.pump();

      expect(find.text('Vui lòng nhập họ.'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên.'), findsOneWidget);
      expect(repository.updateCalls, 0);
    });

    testWidgets('submits names and publishes the returned profile', (
      tester,
    ) async {
      final completer = Completer<UserProfile>();
      final repository = _ProfileRepository(updateCompleter: completer);
      await _pump(tester, const EditProfileScreen(), repository: repository);
      await tester.pumpAndSettle();
      await tester.enterText(_field('profile_last_name_field'), 'Sato');
      await tester.enterText(_field('profile_first_name_field'), 'Aiko');

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_save_button')),
      );
      await tester.pump();

      expect(find.text('Đang lưu...'), findsOneWidget);
      expect(repository.lastFirstName, 'Aiko');
      expect(repository.lastLastName, 'Sato');

      completer.complete(_profile(firstName: 'Aiko', lastName: 'Sato'));
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

      expect(find.textContaining('Không thể kết nối máy chủ'), findsOneWidget);
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
    testWidgets('does not expose backend-blocked account mutations', (
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
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('account_change_password_action')),
        findsNothing,
      );
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
        find.byKey(const ValueKey<String>('account_logout_button')),
        240,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('設定'), findsOneWidget);
      expect(find.text('セッション'), findsOneWidget);
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
      expect(find.textContaining('Không thể kết nối máy chủ'), findsOneWidget);
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
    testWidgets('offers N5 through N1 and submits the selected Backend ID', (
      tester,
    ) async {
      final repository = _ProfileRepository();
      await _pump(tester, const JlptGoalScreen(), repository: repository);
      await tester.pumpAndSettle();

      // The profile target is N3; the independent current study level may be N5.
      final currentGoal = find.ancestor(
        of: find.text('Mục tiêu hiện tại'),
        matching: find.byType(ProfileSettingsTile),
      );
      expect(
        find.descendant(of: currentGoal, matching: find.text('N3')),
        findsWidgets,
      );

      for (final level in <String>['N5', 'N4', 'N3', 'N2', 'N1']) {
        expect(
          find.byKey(ValueKey<String>('jlpt_goal_choice_$level')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey<String>('daily_study_choice_90')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_choice_N4')),
      );
      await tester.pump();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey<String>('jlpt_goal_choice_N4')),
            )
            .selected,
        isTrue,
      );
      expect(repository.jlptCalls, 0);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_save_button')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<RikiPrimaryButton>(
              find.byKey(const ValueKey<String>('jlpt_goal_save_button')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_save_button')),
      );
      await tester.pumpAndSettle();
      expect(repository.jlptCalls, 1);
      expect(repository.lastJlptLevelId, 204);
      expect(repository.lastDailyStudyMinutes, 30);
    });

    testWidgets('Japanese selectors do not overflow at 320px', (tester) async {
      await _pump(
        tester,
        const JlptGoalScreen(),
        repository: _ProfileRepository(),
        locale: const Locale('ja'),
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_save_button')),
        220,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('JLPT目標を選択'), findsOneWidget);
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
  String firstName = 'Minh Anh',
  String lastName = 'Nguyễn',
  bool isEmailVerified = true,
  int? targetJlptLevelId = 309,
  String? targetJlptLevelName = 'N3',
  int dailyStudyMinutes = 30,
  DateTime? targetExamDate,
  bool emailNotifications = true,
  bool systemNotifications = false,
  String? avatarUrl,
}) {
  return UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: firstName,
    lastName: lastName,
    avatarUrl: avatarUrl,
    role: 'Learner',
    isEmailVerified: isEmailVerified,
    targetJlptLevelId: targetJlptLevelId,
    targetJlptLevelName: targetJlptLevelName,
    dailyStudyMinutes: dailyStudyMinutes,
    targetExamDate: targetExamDate ?? DateTime(2030, 12, 1),
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

class _ProfileRepository implements UserProfileRepository {
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
  int? lastJlptLevelId;
  int? lastDailyStudyMinutes;
  String? lastFirstName;
  String? lastLastName;
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
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) {
    updateCalls += 1;
    lastFirstName = firstName;
    lastLastName = lastName;
    return updateCompleter?.future ??
        Future<UserProfile>.value(
          _profile(firstName: firstName, lastName: lastName),
        );
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
