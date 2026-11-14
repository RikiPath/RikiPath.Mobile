import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_learner_header.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_glass_notification.dart';
import 'package:rikipath_mobile/core/widgets/sakura_loading.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';

void main() {
  testWidgets('success toast renders the unified Sakura Glass treatment', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .success(
          title: l10n.toastProfileUpdateSuccessTitle,
          description: l10n.profileUpdateSuccess,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));

    final card = find.byKey(const ValueKey<String>('riki_toast_success'));
    expect(card, findsOneWidget);
    expect(find.text(l10n.toastProfileUpdateSuccessTitle), findsOneWidget);

    final backdrop = tester.widget<BackdropFilter>(
      find.descendant(of: card, matching: find.byType(BackdropFilter)),
    );
    expect(backdrop, isNotNull);

    final surface = tester.widget<DecoratedBox>(
      find.descendant(
        of: card,
        matching: find.byKey(const ValueKey<String>('sakura_glass_surface')),
      ),
    );
    final box = surface.decoration as BoxDecoration;
    expect(box.gradient, isNull);
    expect(box.color, SakuraGlassNotificationTokens.glassFill);
    expect(box.border?.top.color, SakuraGlassNotificationTokens.glassBorder);
    expect(
      (box.borderRadius! as BorderRadius).topLeft.x,
      inInclusiveRange(20, 24),
    );

    final emblemPaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey<String>('riki_toast_icon_success')),
    );
    expect(
      (emblemPaint.painter! as SakuraGlassBlossomPainter).type,
      RikiToastType.success,
    );

    final titleText = tester.widget<Text>(
      find.text(l10n.toastProfileUpdateSuccessTitle),
    );
    final descText = tester.widget<Text>(find.text(l10n.profileUpdateSuccess));
    expect(titleText.style?.color, SakuraGlassNotificationTokens.titleColor);
    expect(titleText.style?.fontWeight, FontWeight.w700);
    expect(
      descText.style?.color,
      SakuraGlassNotificationTokens.descriptionColor,
    );
  });

  testWidgets('all six notification states share the unified Sakura Glass surface and differ only in emblem glyph and copy', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    const allStates = <RikiToastType>[
      RikiToastType.success,
      RikiToastType.error,
      RikiToastType.warning,
      RikiToastType.info,
      RikiToastType.loading,
      RikiToastType.confirmation,
    ];

    for (final type in allStates) {
      final id = container
          .read(rikiToastServiceProvider.notifier)
          .show(
            type: type,
            title: 'Tiêu đề ${type.name}',
            description: 'Mô tả ${type.name}',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));

      final card = find.byKey(ValueKey<String>('riki_toast_${type.name}'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );

      final surface = tester.widget<DecoratedBox>(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey<String>('sakura_glass_surface')),
        ),
      );
      final box = surface.decoration as BoxDecoration;
      expect(box.gradient, isNull);
      expect(box.color, SakuraGlassNotificationTokens.glassFill);
      expect(box.border?.top.color, SakuraGlassNotificationTokens.glassBorder);
      expect(
        (box.borderRadius! as BorderRadius).topLeft.x,
        inInclusiveRange(20, 24),
      );

      if (type == RikiToastType.loading) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('riki_toast_icon_loading')),
            matching: find.byType(SakuraLoadingIndicator),
          ),
          findsOneWidget,
        );
      } else {
        final blossom = tester.widget<CustomPaint>(
          find.byKey(ValueKey<String>('riki_toast_icon_${type.name}')),
        );
        expect((blossom.painter! as SakuraGlassBlossomPainter).type, type);
      }

      container.read(rikiToastServiceProvider.notifier).dismiss(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
    }
  });

  testWidgets('SakuraGlassNotification works cleanly as a standalone widget', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SakuraGlassNotification(
                type: RikiToastType.confirmation,
                title: 'Xác nhận đổi lịch',
                description: 'Bạn có muốn chuyển buổi học sang 20:00 không?',
                closeButtonKey: const ValueKey<String>('standalone_close'),
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SakuraGlassNotification), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Xác nhận đổi lịch'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('standalone_close')));
    expect(closed, isTrue);
  });

  testWidgets('major success uses a single centered celebration', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    container
        .read(rikiToastServiceProvider.notifier)
        .celebrate(
          title: 'Đăng nhập thành công',
          description: 'Chào mừng bạn trở lại RikiPath!',
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      find.byKey(const ValueKey<String>('riki_toast_celebration')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('riki_toast_success')),
      findsNothing,
    );
  });

  testWidgets('error toast is visually distinct and never exposes raw data', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: l10n.toastActionFailedTitle,
          description: l10n.profileErrorNetwork,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const ValueKey<String>('riki_toast_error')),
      findsOneWidget,
    );
    expect(find.text(l10n.profileErrorNetwork), findsOneWidget);
    expect(find.textContaining('traceId'), findsNothing);
  });

  testWidgets('toast automatically dismisses and consumes its event', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .info(
          title: l10n.appTitle,
          description: l10n.preparingLearningSubtext,
          duration: const Duration(milliseconds: 300),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.byKey(const ValueKey<String>('riki_toast_info')), findsNothing);
    expect(container.read(rikiToastServiceProvider), isEmpty);

    await tester.pump();
    expect(find.byKey(const ValueKey<String>('riki_toast_info')), findsNothing);
  });

  testWidgets('toast supports manual dismissal', (tester) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));
    final id = container
        .read(rikiToastServiceProvider.notifier)
        .warning(title: l10n.toastActionFailedTitle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    await tester.tap(find.byKey(ValueKey<String>('riki_toast_close_$id')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('riki_toast_warning')),
      findsNothing,
    );
    expect(container.read(rikiToastServiceProvider), isEmpty);
  });

  testWidgets('toast survives a route replacement', (tester) async {
    await _pumpToastApp(tester, home: const _RouteStart());

    await tester.tap(find.byKey(const ValueKey<String>('show_and_navigate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('destination'), findsOneWidget);
    expect(find.text('RikiPath'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('riki_toast_info')),
      findsOneWidget,
    );
  });

  for (final locale in const [Locale('vi'), Locale('ja')]) {
    testWidgets('toast uses ${locale.languageCode} localized resources', (
      tester,
    ) async {
      final container = await _pumpToastApp(tester, locale: locale);
      final l10n = appLocalizationsFor(locale);

      container
          .read(rikiToastServiceProvider.notifier)
          .success(
            title: l10n.toastVerifyEmailSuccessTitle,
            description: l10n.toastVerifyEmailSuccessDescription,
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text(l10n.toastVerifyEmailSuccessTitle), findsOneWidget);
      expect(
        find.text(l10n.toastVerifyEmailSuccessDescription),
        findsOneWidget,
      );
    });
  }

  testWidgets('toast fits a 320px portrait screen without overflow', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester, size: const Size(320, 568));
    final l10n = appLocalizationsFor(const Locale('ja'));

    container
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: l10n.toastActionFailedTitle,
          description: l10n.profileErrorNetwork,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(RikiToastHost)).width, 320);
  });

  for (final width in <double>[360, 393, 412]) {
    for (final scale in <double>[1.3, 2.0]) {
      testWidgets('glass toast fits ${width.toInt()}dp at ${scale}x text', (
        tester,
      ) async {
        final container = await _pumpToastApp(
          tester,
          size: Size(width, 720),
          textScale: scale,
        );
        container
            .read(rikiToastServiceProvider.notifier)
            .warning(
              title: 'Bạn có thay đổi chưa lưu',
              description: 'Hãy kiểm tra trước khi rời khỏi màn hình này.',
            );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey<String>('riki_toast_warning')),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('reduced motion displays feedback without a running entrance', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester, reducedMotion: true);
    container
        .read(rikiToastServiceProvider.notifier)
        .success(
          title: 'Đã đăng xuất',
          description: 'Hẹn gặp lại trên hành trình học tiếng Nhật!',
        );
    await tester.pump();
    expect(find.text('Đã đăng xuất'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuilding the app does not duplicate a one-shot toast', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester, home: const _RebuildBody());
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .success(title: l10n.toastProfileUpdateSuccessTitle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.byKey(const ValueKey<String>('rebuild_body')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('riki_toast_success')),
      findsOneWidget,
    );
    expect(container.read(rikiToastServiceProvider), hasLength(1));
  });

  testWidgets(
    'duplicate events share one toast and errors replace low priority',
    (tester) async {
      final container = await _pumpToastApp(tester);
      final service = container.read(rikiToastServiceProvider.notifier);
      final first = service.info(title: 'Đang cập nhật');
      final duplicate = service.info(title: 'Đang cập nhật');
      expect(duplicate, first);
      expect(container.read(rikiToastServiceProvider), hasLength(1));

      service.error(title: 'Không thể cập nhật');
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('riki_toast_error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('riki_toast_info')),
        findsNothing,
      );
    },
  );

  testWidgets('lower-priority feedback waits and logout clears old events', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final service = container.read(rikiToastServiceProvider.notifier);
    final errorId = service.error(title: 'Lỗi mạng');
    service.info(title: 'Đã cập nhật');
    expect(container.read(rikiToastServiceProvider).single.title, 'Lỗi mạng');
    service.dismiss(errorId);
    expect(
      container.read(rikiToastServiceProvider).single.title,
      'Đã cập nhật',
    );
    service.clear();
    expect(container.read(rikiToastServiceProvider), isEmpty);
  });

  testWidgets('toast clears SafeArea and shared header buttons for Learner and Mentor', (
    tester,
  ) async {
    for (final isMentor in <bool>[false, true]) {
      var bellPressed = false;
      final container = await _pumpToastApp(
        tester,
        viewPadding: const FakeViewPadding(top: 44, left: 10, right: 10),
        home: Scaffold(
          appBar: SakuraAppHeader(
            showStreak: !isMentor,
            streakDays: isMentor ? null : 5,
            unreadNotificationCount: 1,
            onNotificationsPressed: () => bellPressed = true,
            onCalendarPressed: () {},
          ),
          body: const SizedBox.expand(),
        ),
      );

      container
          .read(rikiToastServiceProvider.notifier)
          .info(
            title: isMentor ? 'Lịch dạy mới' : 'Cập nhật lộ trình',
            description: 'Thông báo nhẹ nhàng không che nút trên header.',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));

      final toastCard = find.byKey(const ValueKey<String>('riki_toast_info'));
      final headerBottom = tester
          .getBottomLeft(find.byType(SakuraAppHeader))
          .dy;
      final toastTop = tester.getTopLeft(toastCard).dy;
      expect(toastTop, greaterThanOrEqualTo(headerBottom + AppSpacing.space2));
      expect(toastTop, greaterThanOrEqualTo(44 + RikiLearnerHeader.height));

      // Header bell remains completely tappable while toast is displayed.
      await tester.tap(
        find.byKey(const ValueKey<String>('home_notification_bell_button')),
      );
      await tester.pump();
      expect(bellPressed, isTrue);

      container.read(rikiToastServiceProvider.notifier).clear();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('toast supports upward swipe dismissal', (tester) async {
    final container = await _pumpToastApp(tester);
    container
        .read(rikiToastServiceProvider.notifier)
        .success(
          title: 'Lưu thành công',
          description: 'Kéo lên để đóng thông báo nhanh.',
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));

    final card = find.byKey(const ValueKey<String>('riki_toast_success'));
    expect(card, findsOneWidget);
    await tester.fling(card, const Offset(0, -180), 900);
    await tester.pumpAndSettle();

    expect(card, findsNothing);
    expect(container.read(rikiToastServiceProvider), isEmpty);
  });
}

Future<ProviderContainer> _pumpToastApp(
  WidgetTester tester, {
  Locale locale = const Locale('vi'),
  Size size = const Size(390, 844),
  Widget home = const Scaffold(body: SizedBox.expand()),
  double textScale = 1,
  bool reducedMotion = false,
  FakeViewPadding? viewPadding,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  if (viewPadding != null) {
    tester.view.padding = viewPadding;
    tester.view.viewPadding = viewPadding;
  }
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(
        _FakeToastNotificationRepo(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reducedMotion,
            accessibleNavigation: reducedMotion,
          ),
          child: RikiToastHost(child: child ?? const SizedBox.shrink()),
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  return container;
}

class _RouteStart extends ConsumerWidget {
  const _RouteStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('show_and_navigate'),
          onPressed: () {
            ref
                .read(rikiToastServiceProvider.notifier)
                .info(title: context.l10n.appTitle);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('destination'))),
              ),
            );
          },
          child: const Text('show'),
        ),
      ),
    );
  }
}

class _RebuildBody extends StatefulWidget {
  const _RebuildBody();

  @override
  State<_RebuildBody> createState() => _RebuildBodyState();
}

class _FakeToastNotificationRepo implements NotificationRepository {
  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => const <AppNotification>[];

  @override
  Future<int> loadUnreadCount() async => 1;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

class _RebuildBodyState extends State<_RebuildBody> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('rebuild_body'),
          onPressed: () => setState(() => _count += 1),
          child: Text('rebuild $_count'),
        ),
      ),
    );
  }
}
