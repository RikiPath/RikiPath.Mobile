import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/locale_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/riki_auth_header.dart';
import 'package:rikipath_mobile/core/widgets/riki_language_switcher.dart';
import 'package:rikipath_mobile/features/auth/presentation/account_settings_screen.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_jlpt_catalog.dart';

void main() {
  group('Header Language Switcher differentiation', () {
    testWidgets('HomeHeader does not contain RikiLanguageSwitcher', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: HomeHeader(
              streakDays: 5,
              isStreakLoading: false,
              unreadNotificationCount: 2,
              onNotificationsPressed: () {},
              onCalendarPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RikiLanguageSwitcher), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('home_calendar_button')),
        findsOneWidget,
      );
      expect(find.byType(HomeHeader), findsOneWidget);
    });

    testWidgets('LearningHeader does not contain RikiLanguageSwitcher', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            appBar: LearningHeader.root(
              streakDays: 3,
              hasUnreadNotifications: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RikiLanguageSwitcher), findsNothing);
    });

    testWidgets(
      'RikiAuthHeader retains RikiLanguageSwitcher for unauthenticated screens',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SafeArea(
                  child: RikiAuthHeader(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RikiLanguageSwitcher), findsOneWidget);
      },
    );
  });

  group('AccountSettingsScreen Language Setting Card & Bottom Sheet', () {
    late _MemoryLocalePreferenceStore store;
    late _FakeProfileRepository profileRepository;

    setUp(() {
      store = _MemoryLocalePreferenceStore('vi');
      profileRepository = _FakeProfileRepository();
    });

    Future<void> pumpAccountSettings(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localePreferenceStoreProvider.overrideWithValue(store),
            userProfileRepositoryProvider.overrideWithValue(profileRepository),
            jlptCatalogRepositoryProvider.overrideWithValue(
              TestJlptCatalogRepository(),
            ),
          ],
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'AccountSettings displays language card with Vietnamese flag and title',
      (tester) async {
        await pumpAccountSettings(tester);

        final languageTile = find.byKey(
          const ValueKey<String>('account_language_settings_action'),
        );
        expect(languageTile, findsOneWidget);
        expect(find.text('Ngôn ngữ ứng dụng'), findsOneWidget);
        expect(find.text('Tiếng Việt'), findsOneWidget);

        // Verify SVG flag is rendered inside the tile
        final flagFinders = find.descendant(
          of: languageTile,
          matching: find.byType(SvgPicture),
        );
        expect(flagFinders, findsOneWidget);
      },
    );

    testWidgets(
      'tapping language card opens bottom sheet with both language options',
      (tester) async {
        await pumpAccountSettings(tester);

        await tester.tap(
          find.byKey(const ValueKey<String>('account_language_settings_action')),
        );
        await tester.pumpAndSettle();

        // Bottom sheet is visible
        expect(
          find.byKey(const ValueKey<String>('sakura_language_bottom_sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>('sakura_language_bottom_sheet_drag_handle'),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Chọn ngôn ngữ hiển thị trong ứng dụng'),
          findsOneWidget,
        );

        // Both options exist
        final viOption = find.byKey(
          const ValueKey<String>('language_bottom_sheet_option_vi'),
        );
        final jaOption = find.byKey(
          const ValueKey<String>('language_bottom_sheet_option_ja'),
        );
        expect(viOption, findsOneWidget);
        expect(jaOption, findsOneWidget);

        // Vietnamese is selected with checkmark
        expect(
          find.descendant(
            of: viOption,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsOneWidget,
        );
        // Japanese is not selected (no checkmark)
        expect(
          find.descendant(
            of: jaOption,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'selecting Japanese updates locale instantly, closes sheet, and persists choice',
      (tester) async {
        await pumpAccountSettings(tester);

        await tester.tap(
          find.byKey(const ValueKey<String>('account_language_settings_action')),
        );
        await tester.pumpAndSettle();

        // Tap Japanese option
        await tester.tap(
          find.byKey(const ValueKey<String>('language_bottom_sheet_option_ja')),
        );
        await tester.pumpAndSettle();

        // Bottom sheet closed
        expect(
          find.byKey(const ValueKey<String>('sakura_language_bottom_sheet')),
          findsNothing,
        );

        // Store persisted 'ja'
        expect(store.languageCode, equals('ja'));
        expect(store.writes, contains('ja'));

        // AccountSettingsScreen updated to Japanese!
        expect(find.text('アプリの言語'), findsOneWidget);
        expect(find.text('日本語'), findsOneWidget);
        expect(find.text('セキュリティ'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting Vietnamese switches back from Japanese and updates UI immediately',
      (tester) async {
        store.languageCode = 'ja';
        await pumpAccountSettings(tester);

        expect(find.text('アプリの言語'), findsOneWidget);
        expect(find.text('日本語'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('account_language_settings_action')),
        );
        await tester.pumpAndSettle();

        // Bottom sheet is in Japanese
        expect(find.text('アプリの表示言語を選択してください'), findsOneWidget);

        // Tap Vietnamese option
        await tester.tap(
          find.byKey(const ValueKey<String>('language_bottom_sheet_option_vi')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('sakura_language_bottom_sheet')),
          findsNothing,
        );

        expect(store.languageCode, equals('vi'));
        expect(find.text('Ngôn ngữ ứng dụng'), findsOneWidget);
        expect(find.text('Tiếng Việt'), findsOneWidget);
      },
    );

    testWidgets('bottom sheet renders without overflow at 320px, 360px, 412px', (
      tester,
    ) async {
      for (final width in [320.0, 360.0, 412.0]) {
        await pumpAccountSettings(tester, size: Size(width, 740));

        await tester.tap(
          find.byKey(const ValueKey<String>('account_language_settings_action')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('sakura_language_bottom_sheet')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Tap outside / dismiss
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
      }
    });
  });
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccountSettingsScreen(),
    );
  }
}

class _MemoryLocalePreferenceStore implements LocalePreferenceStore {
  _MemoryLocalePreferenceStore(this.languageCode);

  String? languageCode;
  final List<String> writes = <String>[];

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> writeLanguageCode(String code) async {
    languageCode = code;
    writes.add(code);
  }
}

class _FakeProfileRepository implements UserProfileRepository {
  UserProfile _profile() {
    return const UserProfile(
      userId: 42,
      email: 'learner@example.com',
      firstName: 'Minh Anh',
      lastName: 'Nguyễn',
      avatarUrl: null,
      role: 'Learner',
      isEmailVerified: true,
      targetJlptLevelId: 309,
      targetJlptLevelName: 'N5',
      dailyStudyMinutes: 30,
      emailNotificationsEnabled: true,
      systemNotificationsEnabled: false,
    );
  }

  @override
  Future<UserProfile> loadProfile() async => _profile();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async {
    throw UnimplementedError();
  }
}
