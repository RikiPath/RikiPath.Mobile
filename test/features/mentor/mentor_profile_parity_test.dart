import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/account_settings_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/change_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/update_email_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_edit_profile_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_profile_screen.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_components.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_auth_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Mentor Profile Parity & Nested Settings Architecture', () {
    testWidgets(
      '1. Mentor Profile Home mirrors Learner compact layout with zero inline form controls',
      (tester) async {
        final learnerRepo = _SpyForbiddenLearnerRepository();
        await _pumpMentorParityRouter(
          tester,
          initialLocation: AppRoutes.mentorProfile,
          learnerRepo: learnerRepo,
        );

        expect(find.byType(MentorProfileScreen), findsOneWidget);
        expect(find.byType(ProfileHeroCard), findsOneWidget);
        expect(find.text('Ren Takahashi'), findsOneWidget);
        expect(find.text('mentor.ren@rikipath.local'), findsOneWidget);
        expect(find.text('Cố vấn'), findsOneWidget);
        expect(find.text('Đã xác minh'), findsOneWidget);

        // Zero inline form inputs / save / upload controls on Profile Home
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(find.byKey(const Key('mentor_profile_bio_input')), findsNothing);
        expect(find.byKey(const Key('mentor_profile_save_button')), findsNothing);
        expect(
          find.byKey(const Key('mentor_submit_verification_button')),
          findsNothing,
        );

        // Grouped navigation actions match spec
        expect(find.byKey(const Key('mentor_profile_edit_action')), findsOneWidget);
        expect(
          find.byKey(const Key('mentor_profile_verification_status_action')),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.byKey(const Key('mentor_profile_logout_action')),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const Key('mentor_profile_logout_action')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mentor_profile_settings_action')), findsOneWidget);
        expect(find.byKey(const Key('mentor_profile_logout_action')), findsOneWidget);
        expect(learnerRepo.calls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Edit Profile opens dedicated nested route with prefilled data and Back returns to Profile Home',
      (tester) async {
        await _pumpMentorParityRouter(
          tester,
          initialLocation: AppRoutes.mentorProfile,
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_edit_action')),
        );

        expect(find.byType(MentorEditProfileScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(MentorEditProfileScreen)),
          AppRoutes.mentorProfileEdit,
        );
        expect(find.text('Ren Takahashi'), findsOneWidget);
        expect(find.text('mentor.ren@rikipath.local'), findsOneWidget);
        expect(find.text('+84901234567'), findsOneWidget);
        expect(
          find.byKey(const Key('mentor_profile_account_readonly_banner')),
          findsOneWidget,
        );

        final bioField = tester.widget<TextField>(
          find.byKey(const Key('mentor_profile_bio_input')),
        );
        expect(bioField.controller?.text, 'Sensei 5 năm kinh nghiệm tại Tokyo');

        // Back button cleanly returns to Profile Home
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.byType(MentorEditProfileScreen), findsNothing);
        expect(find.byType(MentorProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      '3. Verification status variants render distinct badges and summary sheet navigates to Edit Profile',
      (tester) async {
        for (final entry in <String, String>{
          'Pending': 'Đang chờ duyệt',
          'ChangesRequested': 'Yêu cầu bổ sung',
          'Rejected': 'Hồ sơ bị từ chối',
          'Unverified': 'Chưa nộp hồ sơ',
        }.entries) {
          final repo = _FakeParityMentorRepository(
            profile: MentorProfileData(
              mentorId: 10,
              email: 'mentor.ren@rikipath.local',
              firstName: 'Ren',
              lastName: 'Takahashi',
              verificationStatus: entry.key,
              rejectionReason: entry.key == 'Rejected' ? 'Thiếu bản scan rõ nét' : null,
              reviewNotes: entry.key == 'ChangesRequested'
                  ? 'Bổ sung chứng chỉ N1'
                  : null,
            ),
          );
          await _pumpMentorParityRouter(
            tester,
            initialLocation: AppRoutes.mentorProfile,
            mentorRepo: repo,
          );
          expect(find.text(entry.value), findsWidgets);
        }

        // Verification tile opens sheet -> button navigates to /mentor/profile/edit
        await _pumpMentorParityRouter(
          tester,
          initialLocation: AppRoutes.mentorProfile,
          mentorRepo: _FakeParityMentorRepository(
            profile: const MentorProfileData(
              mentorId: 10,
              email: 'mentor.ren@rikipath.local',
              firstName: 'Ren',
              lastName: 'Takahashi',
              verificationStatus: 'ChangesRequested',
              reviewNotes: 'Bổ sung chứng chỉ N1',
            ),
          ),
        );
        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_verification_status_action')),
        );
        expect(find.textContaining('Bổ sung chứng chỉ N1'), findsWidgets);

        await tester.tap(
          find.byKey(const Key('mentor_verification_sheet_edit_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MentorEditProfileScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(MentorEditProfileScreen)),
          AppRoutes.mentorProfileEdit,
        );
      },
    );

    testWidgets(
      '4. MentorEditProfileScreen validates input, handles save failure without losing edits, saves cleanly & guards dirty Back',
      (tester) async {
        final repo = _FakeParityMentorRepository(
          profile: const MentorProfileData(
            mentorId: 10,
            email: 'mentor.ren@rikipath.local',
            firstName: 'Ren',
            lastName: 'Takahashi',
            bio: 'Bio ban đầu',
            expertise: 'JLPT N2',
            jlptLevel: 'N2',
            yearsOfExperience: 3,
            workplace: 'Tokyo',
            verificationStatus: 'Unverified',
          ),
        );
        await _pumpMentorParityRouter(
          tester,
          initialLocation: AppRoutes.mentorProfile,
          mentorRepo: repo,
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_edit_action')),
        );

        // Enter invalid years of experience & invalid video URL
        await _enterFieldText(tester, const Key('mentor_profile_exp_input'), '99');
        await _enterFieldText(
          tester,
          const Key('mentor_profile_video_input'),
          'ftp://invalid-scheme',
        );
        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_save_draft_button')),
        );

        expect(
          find.text('Số năm kinh nghiệm phải là số nguyên từ 0 đến 50.'),
          findsOneWidget,
        );
        expect(
          find.text('Link video cần là URL http(s) hợp lệ.'),
          findsOneWidget,
        );
        expect(repo.updateCalls, 0);

        // Fix fields and test API save failure preserves typed input
        await _enterFieldText(
          tester,
          const Key('mentor_profile_bio_input'),
          'Bio cập nhật thất bại',
        );
        await _enterFieldText(tester, const Key('mentor_profile_exp_input'), '4');
        await _enterFieldText(
          tester,
          const Key('mentor_profile_video_input'),
          'https://youtube.com/watch?v=demo',
        );

        // Dirty Back triggers discard prompt -> Stay keeps edits
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsOneWidget);
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();

        repo.failNextUpdate = true;
        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_save_draft_button')),
        );
        expect(repo.updateCalls, 1);
        final toastsAfterFail = ProviderScope.containerOf(
          tester.element(find.byType(MentorEditProfileScreen)),
        ).read(rikiToastServiceProvider);
        expect(
          toastsAfterFail.any((t) => t.type == RikiToastType.error),
          isTrue,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('mentor_profile_bio_input')))
              .controller
              ?.text,
          'Bio cập nhật thất bại',
        );

        // Successful save syncs baseline so Back returns cleanly without prompt
        repo.failNextUpdate = false;
        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_save_draft_button')),
        );
        expect(repo.updateCalls, 2);

        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.text('Hủy thay đổi?'), findsNothing);
        expect(find.byType(MentorEditProfileScreen), findsNothing);
        expect(find.byType(MentorProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      '5. Settings, Security (Change Password & Change Email), Notifications & Back navigation preserve nested parity and role safety',
      (tester) async {
        final learnerRepo = _SpyForbiddenLearnerRepository();
        await _pumpMentorParityRouter(
          tester,
          initialLocation: AppRoutes.mentorProfile,
          learnerRepo: learnerRepo,
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_settings_action')),
        );

        expect(find.byType(AccountSettingsScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(AccountSettingsScreen)),
          AppRoutes.mentorSettings,
        );
        expect(
          find.byKey(const ValueKey<String>('account_change_password_action')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('account_change_email_action')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('account_language_settings_action')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>('account_notification_settings_action'),
          ),
          findsOneWidget,
        );
        expect(learnerRepo.calls, 0);

        // Notification Settings renders honest server-unsupported banner + Notification Center tile
        await _tapVisible(
          tester,
          find.byKey(
            const ValueKey<String>('account_notification_settings_action'),
          ),
        );
        expect(find.byType(NotificationSettingsScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(NotificationSettingsScreen)),
          AppRoutes.mentorNotifications,
        );
        expect(find.byType(SwitchListTile), findsNothing);
        expect(
          find.byKey(
            const ValueKey<String>('mentor_notification_channel_unsupported_notice'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('mentor_open_notifications_center_action')),
          findsOneWidget,
        );

        // Open Notification Center -> Back pops to NotificationSettingsScreen
        await _tapVisible(
          tester,
          find.byKey(
            const ValueKey<String>('mentor_open_notifications_center_action'),
          ),
        );
        expect(find.byType(NotificationsScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(NotificationsScreen)),
          AppRoutes.notifications,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsScreen), findsNothing);
        expect(find.byType(NotificationSettingsScreen), findsOneWidget);

        // Back from NotificationSettingsScreen pops to Settings
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.byType(NotificationSettingsScreen), findsNothing);
        expect(find.byType(AccountSettingsScreen), findsOneWidget);

        // Change Password -> Back pops back to Settings
        await _tapVisible(
          tester,
          find.byKey(const ValueKey<String>('account_change_password_action')),
        );
        expect(find.byType(ChangePasswordScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(ChangePasswordScreen)),
          AppRoutes.mentorChangePassword,
        );
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.byType(ChangePasswordScreen), findsNothing);
        expect(find.byType(AccountSettingsScreen), findsOneWidget);

        // Change Email pre-fills Mentor email & Back pops back to Settings
        await _tapVisible(
          tester,
          find.byKey(const ValueKey<String>('account_change_email_action')),
        );
        expect(find.byType(UpdateEmailScreen), findsOneWidget);
        expect(
          _matchedPath(tester, find.byType(UpdateEmailScreen)),
          AppRoutes.mentorChangeEmail,
        );
        expect(find.text('mentor.ren@rikipath.local'), findsOneWidget);
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.byType(UpdateEmailScreen), findsNothing);
        expect(find.byType(AccountSettingsScreen), findsOneWidget);

        // Switching tab to Meetings & back to Profile preserves Settings in Profile branch!
        await tester.tap(find.text('Buổi tư vấn'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cá nhân'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsScreen), findsOneWidget);

        // Back from Settings returns to Profile Home
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsScreen), findsNothing);
        expect(find.byType(MentorProfileScreen), findsOneWidget);
        expect(learnerRepo.calls, 0);
      },
    );

    testWidgets(
      '6. Language switching updates Mentor Profile, Edit Profile, Settings & Notifications to Japanese with zero leftover strings',
      (tester) async {
        await _pumpMentorParityRouter(
          tester,
          initialLocation: AppRoutes.mentorSettings,
        );

        await _tapVisible(
          tester,
          find.byKey(const ValueKey<String>('account_language_settings_action')),
        );
        await tester.tap(find.textContaining('日本語'));
        await tester.pumpAndSettle();

        expect(find.text('設定'), findsWidgets);
        expect(find.text('パスワードを変更'), findsOneWidget);
        expect(find.text('メールアドレスを変更'), findsOneWidget);
        expect(find.text('通知設定'), findsOneWidget);

        // Back to Mentor Profile Home renders full Japanese labels
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        expect(find.byType(MentorProfileScreen), findsOneWidget);
        expect(find.text('メンター'), findsOneWidget);
        expect(find.text('認証済み'), findsOneWidget);
        expect(find.text('プロフィールを編集'), findsWidgets);

        // Enter Edit Profile in Japanese while edit action is at top of scroll
        await _tapVisible(
          tester,
          find.byKey(const Key('mentor_profile_edit_action')),
        );
        expect(find.text('個人情報'), findsOneWidget);
        expect(find.text('専門分野と経験'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('mentor_profile_save_button')),
        );
        expect(find.text('変更を保存'), findsOneWidget);

        // Back to Profile Home and scroll down to verify Japanese Account section
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('mentor_profile_logout_action')),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('アカウント'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Responsive widths (360dp, 393dp, 412dp) and large text scale (1.6x) render with zero RenderFlex overflow',
      (tester) async {
        for (final size in const [
          Size(360, 640),
          Size(393, 851),
          Size(412, 915),
        ]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          for (final route in const [
            AppRoutes.mentorProfile,
            AppRoutes.mentorProfileEdit,
            AppRoutes.mentorSettings,
            AppRoutes.mentorNotifications,
          ]) {
            await _pumpMentorParityRouter(
              tester,
              initialLocation: route,
              textScaleFactor: 1.6,
            );
            expect(tester.takeException(), isNull, reason: 'Failed on $route @ $size');
          }
        }
      },
    );
  });
}

String _matchedPath(WidgetTester tester, Finder finder) =>
    GoRouterState.of(tester.element(finder)).uri.path;

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        220,
        scrollable: scrollables.first,
      );
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterFieldText(
  WidgetTester tester,
  Key key,
  String text,
) async {
  final root = find.byKey(key);
  await tester.ensureVisible(root);
  await tester.pumpAndSettle();
  final widget = tester.widget(root);
  final target = widget is TextField
      ? root
      : find.descendant(of: root, matching: find.byType(TextField));
  await tester.enterText(target, text);
  await tester.pumpAndSettle();
}

Future<GoRouter> _pumpMentorParityRouter(
  WidgetTester tester, {
  required String initialLocation,
  MentorRepository? mentorRepo,
  _SpyForbiddenLearnerRepository? learnerRepo,
  double textScaleFactor = 1.0,
}) async {
  final session = createTestAuthSession(
    role: BackendUserRole.mentor,
  );
  final effectiveMentorRepo =
      mentorRepo ??
      _FakeParityMentorRepository(
        profile: const MentorProfileData(
          mentorId: 10,
          email: 'mentor.ren@rikipath.local',
          firstName: 'Ren',
          lastName: 'Takahashi',
          phoneNumber: '+84901234567',
          bio: 'Sensei 5 năm kinh nghiệm tại Tokyo',
          expertise: 'JLPT N1, N2',
          jlptLevel: 'N1',
          yearsOfExperience: 5,
          workplace: 'Tokyo Japanese Academy',
          hasVerificationDocument: true,
          verificationDocumentUrl: '/documents/cert.png',
          verificationStatus: 'Approved',
          isBookable: true,
        ),
      );
  final effectiveLearnerRepo =
      learnerRepo ?? _SpyForbiddenLearnerRepository();

  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        mentorRepositoryProvider.overrideWithValue(effectiveMentorRepo),
        mentorOperationsRepositoryProvider.overrideWithValue(
          _FakeParityMentorOperationsRepository(),
        ),
        userProfileRepositoryProvider.overrideWithValue(effectiveLearnerRepo),
        notificationRepositoryProvider.overrideWithValue(
          _FakeParityNotificationRepository(),
        ),
        jsonPreferenceStoreProvider.overrideWithValue(
          _InMemoryJsonPreferenceStore(),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeControllerProvider);
          return MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: MaterialApp.router(
              theme: AppTheme.light,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _InMemoryJsonPreferenceStore implements JsonPreferenceStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class _SpyForbiddenLearnerRepository implements UserProfileRepository {
  int calls = 0;

  @override
  Future<UserProfile> loadProfile() {
    calls++;
    throw StateError('Learner UserProfileRepository must not be called for Mentor');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Learner UserProfileRepository must not be called for Mentor');
  }
}

class _FakeParityMentorRepository implements MentorRepository {
  _FakeParityMentorRepository({required this.profile});

  MentorProfileData profile;
  int updateCalls = 0;
  bool failNextUpdate = false;

  @override
  Future<MentorProfileData> loadProfile() async => profile;

  @override
  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async {
    updateCalls++;
    if (failNextUpdate) {
      throw Exception('Simulated update failure');
    }
    profile = MentorProfileData(
      mentorId: profile.mentorId,
      email: profile.email,
      firstName: profile.firstName,
      lastName: profile.lastName,
      phoneNumber: profile.phoneNumber,
      avatarUrl: profile.avatarUrl,
      bio: bio ?? profile.bio,
      expertise: expertise ?? profile.expertise,
      jlptLevel: jlptLevel ?? profile.jlptLevel,
      yearsOfExperience: yearsOfExperience ?? profile.yearsOfExperience,
      workplace: workplace ?? profile.workplace,
      verificationDocumentUrl: profile.verificationDocumentUrl,
      hasVerificationDocument: profile.hasVerificationDocument,
      introductionVideoUrl:
          introductionVideoUrl ?? profile.introductionVideoUrl,
      verificationStatus: profile.verificationStatus,
      isBookable: profile.isBookable,
    );
    return profile;
  }

  @override
  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async {
    profile = MentorProfileData(
      mentorId: profile.mentorId,
      email: profile.email,
      firstName: profile.firstName,
      lastName: profile.lastName,
      verificationStatus: 'Pending',
      hasVerificationDocument: profile.hasVerificationDocument,
    );
    return profile;
  }

  @override
  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async => profile;

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async => const [];

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() async => const [];

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(
    DateTime weekStart,
  ) async => const [];

  @override
  Future<bool> saveWeeklySchedule({
    required DateTime weekStart,
    required List<WeeklyPeriodItem> periods,
  }) async => true;

  @override
  Future<bool> cancelMeeting(int bookingId, String reason) async => true;

  @override
  Future<bool> replyReview(int reviewId, String reply) async => true;

  @override
  Future<bool> respondDispute(int disputeId, String responseText) async => true;
}

class _FakeParityMentorOperationsRepository
    implements MentorOperationsRepository {
  @override
  Future<MentorBookingDetail> loadBookingDetail(int bookingId) async =>
      throw UnimplementedError();

  @override
  Future<MentorCancellationEligibility> checkCancellationEligibility(
    int bookingId,
  ) async => throw UnimplementedError();

  @override
  Future<List<MentorAttendanceRecord>> loadBookingAttendance(
    int bookingId,
  ) async => const [];

  @override
  Future<MentorRoomAccessStatus> checkRoomAccess(String roomId) async =>
      MentorRoomAccessStatus(roomId: roomId, canAccess: true, isRoomReady: true);

  @override
  Future<MentorVerificationDocumentData> loadVerificationDocument() async =>
      const MentorVerificationDocumentData();

  @override
  Future<MentorRatingSummary> loadRatingSummary(int mentorId) async =>
      MentorRatingSummary(
        mentorId: mentorId,
        averageRating: 5,
        totalReviews: 0,
        ratingBreakdown: const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        positiveRatePercent: 100,
      );

  @override
  Future<List<MentorReviewItem>> loadReviews(
    int mentorId, {
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<List<MentorDisputeItem>> loadDisputes({
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<MentorDisputeDetail> loadDisputeDetail(int disputeId) async =>
      throw UnimplementedError();
}

class _FakeParityNotificationRepository implements NotificationRepository {
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
