import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/calendar/presentation/mentor_calendar_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_profile_screen.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../support/test_auth_session.dart';

class _VisualNotificationRepo implements NotificationRepository {
  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => [
    AppNotification(
      id: 501,
      title: 'Buổi tư vấn mới được gán',
      message: 'Học viên Nguyễn Minh Anh vừa đặt lịch tư vấn 1-1 lúc 19:30.',
      type: 'Consultation',
      isRead: false,
      createdAt: DateTime(2026, 11, 14, 10, 30),
    ),
    AppNotification(
      id: 502,
      title: 'Hồ sơ cố vấn đã duyệt',
      message: 'Chúc mừng Sensei! Hồ sơ JLPT N1 đã được phê duyệt.',
      type: 'System',
      isRead: false,
      createdAt: DateTime(2026, 11, 14, 9, 0),
    ),
  ];

  @override
  Future<int> loadUnreadCount() async => 2;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

class _VisualMentorRepo implements MentorRepository {
  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async => [
    MentorAvailabilitySlot(
      id: 101,
      startTime: MentorTimestamp.parse('2026-11-15T19:00:00+07:00'),
      endTime: MentorTimestamp.parse('2026-11-15T20:00:00+07:00'),
      isBooked: false,
    ),
    MentorAvailabilitySlot(
      id: 102,
      startTime: MentorTimestamp.parse('2026-11-16T20:00:00+07:00'),
      endTime: MentorTimestamp.parse('2026-11-16T21:00:00+07:00'),
      isBooked: false,
    ),
    MentorAvailabilitySlot(
      id: 103,
      startTime: MentorTimestamp.parse('2026-11-14T18:00:00+07:00'),
      endTime: MentorTimestamp.parse('2026-11-14T19:00:00+07:00'),
      isBooked: true,
    ),
  ];

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() async => [
    MentorMeetingSummary(
      id: 301,
      learnerName: 'Nguyễn Minh Anh',
      scheduledAt: MentorTimestamp.parse('2026-11-15T19:30:00+07:00'),
      status: MentorMeetingStatus.accepted,
      meetingLink: 'https://meet.rikipath.edu.vn/301',
    ),
    MentorMeetingSummary(
      id: 302,
      learnerName: 'Trần Hoàng Nam',
      scheduledAt: MentorTimestamp.parse('2026-11-12T20:00:00+07:00'),
      status: MentorMeetingStatus.completed,
      meetingLink: 'https://meet.rikipath.edu.vn/302',
    ),
  ];

  @override
  Future<MentorProfileData> loadProfile() async => const MentorProfileData(
    mentorId: 84,
    email: 'tanaka.mentor@rikipath.edu.vn',
    firstName: 'Kenji',
    lastName: 'Tanaka',
    bio: 'Cố vấn lộ trình JLPT N2–N1 với 6 năm kinh nghiệm luyện thi tại Tokyo.',
    expertise: 'Chuyên gia Đọc hiểu & Ngữ pháp N1',
    yearsOfExperience: 6,
    jlptLevel: 'N1',
    workplace: 'Học viện Nhật ngữ RikiPath Tokyo',
    verificationStatus: 'Approved',
    isBookable: true,
  );

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(
    DateTime weekStart,
  ) async => const <WeeklyAvailabilityItem>[];

  @override
  Future<bool> cancelMeeting(int bookingId, String reason) async => true;

  @override
  Future<bool> replyReview(int reviewId, String reply) async => true;

  @override
  Future<bool> respondDispute(int disputeId, String responseText) async => true;

  @override
  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async => loadProfile();

  @override
  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async => loadProfile();

  @override
  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async => loadProfile();
}

void main() {
  final targetDir = Directory(
    r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce',
  );

  Future<void> loadRealFontsAndIcons() async {
    Future<ByteData> readFileBytes(String path) async {
      final bytes = await File(path).readAsBytes();
      return ByteData.sublistView(bytes);
    }

    for (final family in [
      'FlutterTest',
      'Noto Sans',
      'Noto Sans JP',
      'Roboto',
      'Ahem',
      '.SF UI Text',
      '.SF UI Display',
      'sans-serif',
    ]) {
      final loader = FontLoader(family);
      for (final fontPath in [
        r'C:\Windows\Fonts\segoeui.ttf',
        r'C:\Windows\Fonts\segoeuib.ttf',
        r'C:\Windows\Fonts\seguisb.ttf',
        r'C:\Windows\Fonts\seguiemj.ttf',
        r'C:\Windows\Fonts\YuGothM.ttc',
      ]) {
        if (File(fontPath).existsSync()) {
          loader.addFont(readFileBytes(fontPath));
        }
      }
      await loader.load();
    }

    const materialFontPath =
        r'D:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf';
    if (File(materialFontPath).existsSync()) {
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(readFileBytes(materialFontPath));
      await iconLoader.load();
    }
  }

  Future<void> saveBoundaryPng(
    WidgetTester tester,
    GlobalKey boundaryKey,
    String fileName,
  ) async {
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${targetDir.path}\\$fileName');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
  }

  Widget wrapMentorApp({
    required GlobalKey boundaryKey,
    required AuthSessionController session,
    required Widget home,
  }) {
    return ProviderScope(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        mentorRepositoryProvider.overrideWithValue(_VisualMentorRepo()),
        notificationRepositoryProvider.overrideWithValue(
          _VisualNotificationRepo(),
        ),
      ],
      child: RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light.copyWith(
            textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
            filledButtonTheme: FilledButtonThemeData(
              style: AppTheme.light.filledButtonTheme.style?.copyWith(
                textStyle: WidgetStatePropertyAll<TextStyle>(
                  AppTypography.buttonLabel.copyWith(fontFamily: 'Roboto'),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: AppTheme.light.outlinedButtonTheme.style?.copyWith(
                textStyle: WidgetStatePropertyAll<TextStyle>(
                  AppTypography.buttonLabel.copyWith(fontFamily: 'Roboto'),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: AppTheme.light.textButtonTheme.style?.copyWith(
                textStyle: WidgetStatePropertyAll<TextStyle>(
                  AppTypography.buttonLabel.copyWith(fontFamily: 'Roboto'),
                ),
              ),
            ),
          ),
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('ja')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              RikiToastHost(child: child ?? const SizedBox.shrink()),
          home: home,
        ),
      ),
    );
  }

  testWidgets('Capture 01-05: Mentor Experience & Learner Parity Visuals', (
    tester,
  ) async {
    await tester.runAsync(loadRealFontsAndIcons);
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = createTestAuthSession(
      userId: 84,
      role: BackendUserRole.mentor,
    );
    addTearDown(session.dispose);

    // 1. Mentor Home Screen
    final homeKey = GlobalKey();
    await tester.pumpWidget(
      wrapMentorApp(
        boundaryKey: homeKey,
        session: session,
        home: const MentorHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await saveBoundaryPng(tester, homeKey, 'sakura_mentor_home_parity.png');

    // 2. Mentor Calendar Screen
    final calendarKey = GlobalKey();
    await tester.pumpWidget(
      wrapMentorApp(
        boundaryKey: calendarKey,
        session: session,
        home: const MentorCalendarScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await saveBoundaryPng(
      tester,
      calendarKey,
      'sakura_mentor_calendar_parity.png',
    );

    // 3. Mentor Profile Screen (scrolled to Account Settings & Security)
    final profileKey = GlobalKey();
    await tester.pumpWidget(
      wrapMentorApp(
        boundaryKey: profileKey,
        session: session,
        home: const MentorProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('mentor_profile_logout_action')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await saveBoundaryPng(
      tester,
      profileKey,
      'sakura_mentor_profile_parity.png',
    );

    // 4. Mentor Logout Confirmation Sheet
    await tester.tap(find.byKey(const Key('mentor_profile_logout_action')));
    await tester.pumpAndSettle();
    await saveBoundaryPng(
      tester,
      profileKey,
      'sakura_mentor_logout_confirmation_sheet.png',
    );

    // 5. Mentor Logout Success Toast on Login Screen
    final loginKey = GlobalKey();
    await tester.pumpWidget(
      wrapMentorApp(
        boundaryKey: loginKey,
        session: session,
        home: Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(rikiToastServiceProvider.notifier)
                  .success(
                    title: 'Đã đăng xuất',
                    description:
                        'Hẹn gặp lại bạn trong phiên làm việc tiếp theo.',
                  );
            });
            return const LoginScreen();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await saveBoundaryPng(
      tester,
      loginKey,
      'sakura_mentor_logout_success_toast.png',
    );
  });
}
