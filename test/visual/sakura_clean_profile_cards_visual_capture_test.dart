import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';

import '../support/test_jlpt_catalog.dart';

class _VisualProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
    userId: 10,
    email: 'linh.nguyen@rikipath.edu.vn',
    firstName: 'Linh',
    lastName: 'Nguyen',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: 101,
    targetJlptLevelName: 'N5',
    currentStudyLevelId: 101,
    currentStudyLevelName: 'N5',
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) => loadProfile();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) => loadProfile();

  @override
  Future<UserProfile> updateProfile({required String fullName}) => loadProfile();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) => loadProfile();
}

class _VisualNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => const <AppNotification>[];

  @override
  Future<int> loadUnreadCount() async => 0;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

Future<void> _loadSystemFontsForVisualCapture() async {
  Future<ByteData?> readFont(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }

  final segoeRegular = await readFont(r'C:\Windows\Fonts\segoeui.ttf');
  final segoeSemiBold = await readFont(r'C:\Windows\Fonts\seguisb.ttf');
  final segoeBold = await readFont(r'C:\Windows\Fonts\segoeuib.ttf');
  final segoeSymbol = await readFont(r'C:\Windows\Fonts\seguisym.ttf');
  final segoeEmoji = await readFont(r'C:\Windows\Fonts\seguiemj.ttf');
  final yuGothic = await readFont(r'C:\Windows\Fonts\YuGothM.ttc');

  for (final family in <String>[
    'Ahem',
    'FlutterTest',
    'Roboto',
    'Noto Sans',
    'Noto Sans JP',
    'sans-serif',
  ]) {
    final loader = FontLoader(family);
    if (segoeRegular != null) loader.addFont(Future.value(segoeRegular));
    if (segoeSemiBold != null) loader.addFont(Future.value(segoeSemiBold));
    if (segoeBold != null) loader.addFont(Future.value(segoeBold));
    if (yuGothic != null) loader.addFont(Future.value(yuGothic));
    await loader.load();
  }

  if (segoeEmoji != null) {
    final emojiLoader = FontLoader('Segoe UI Emoji')
      ..addFont(Future.value(segoeEmoji));
    await emojiLoader.load();
  }
  if (segoeSymbol != null) {
    final symbolLoader = FontLoader('Segoe UI Symbol')
      ..addFont(Future.value(segoeSymbol));
    await symbolLoader.load();
  }

  final sdkRoot = Platform.environment['FLUTTER_ROOT'];
  final materialCandidates = <String>[
    if (sdkRoot != null)
      '$sdkRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    r'C:\src\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    r'C:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
  ];
  for (final path in materialCandidates) {
    final data = await readFont(path);
    if (data != null) {
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(Future.value(data));
      await iconLoader.load();
      break;
    }
  }
}

ThemeData _visualTheme() {
  final base = AppTheme.light;
  const fontFallback = <String>[
    'Roboto',
    'Noto Sans',
    'Noto Sans JP',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
  ];
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: AppTypography.sectionTitle.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: fontFallback,
      ),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: fontFallback,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: fontFallback,
    ),
  );
}

Future<void> _capturePng(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outPath,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  });
  final file = File(outPath);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
}

void main() {
  const artifactDir =
      r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce';

  setUpAll(() async {
    await _loadSystemFontsForVisualCapture();
  });

  testWidgets('Capture Learner Profile Clean White Cards (Top & Scrolled)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final boundaryKey = GlobalKey();
    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(
          _VisualProfileRepository(),
        ),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          _VisualNotificationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _visualTheme(),
            locale: const Locale('vi'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: const ProfileScreen(),
                bottomNavigationBar: SakuraBottomNavigation(
                  destinations: LearnerNavigationConfiguration.buildDestinations(
                    context.l10n,
                  ),
                  selectedIndex: 4,
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(ProfileScreen));
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(img.image, ctx);
      }
    });
    await tester.pumpAndSettle();

    // 1. Top view (Hero + Học tập + Dịch vụ + Tài khoản)
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_profile_clean_cards_top.png',
    );

    // 2. Scrolled view (Học tập + Dịch vụ + Tài khoản full with Đăng xuất)
    await tester.drag(
      find.byKey(const ValueKey<String>('profile_success_view')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_profile_clean_cards_account_logout.png',
    );
  });
}
