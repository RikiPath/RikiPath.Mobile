import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/animated_notification_bell.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    '1 & 4. No notifications / initial load keeps golden bell static; new notification swings once from top crown pivot and settles to 0',
    (tester) async {
      final repo = _MutableNotificationRepository(
        items: <AppNotification>[
          _item(1, isRead: false),
        ],
        unreadCount: 1,
      );

      await tester.pumpWidget(_buildHeaderTestApp(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Preserves existing golden bell emoji icon
      final bellIcon = tester.widget<SakuraColorfulIcon>(
        find.descendant(
          of: find.byType(AnimatedNotificationBell),
          matching: find.byType(SakuraColorfulIcon),
        ),
      );
      expect(bellIcon.type, SakuraColorfulIconType.notifications);
      expect(bellIcon.useEmoji, isTrue);

      // Initial startup load must NOT swing the bell
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));
      expect(_currentBellAlignment(tester), AnimatedNotificationBell.bellPivotAlignment);
      expect(find.text('1'), findsOneWidget);

      // Now a new unread notification (id: 2) arrives from Backend
      repo.items = <AppNotification>[
        _item(2, isRead: false),
        _item(1, isRead: false),
      ];
      repo.unreadCount = 2;

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SakuraAppHeader)),
      );
      container.invalidate(notificationControllerProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      // The async refresh may start the animation on this frame. Advance a
      // further frame so the transform is sampled after it begins ticking.
      await tester.pump(const Duration(milliseconds: 120));

      // Bell is actively swinging mid-animation (non-zero damped angle)
      expect(container.read(notificationBellTriggerProvider).ringSequence, 1);
      final midAngle = _currentBellAngle(tester);
      expect(midAngle.abs(), greaterThan(0.05));
      expect(find.text('2'), findsOneWidget);

      // Let the 840ms damped pendulum complete
      await tester.pump(const Duration(milliseconds: 800));
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));
    },
  );

  test(
    '2 & 3. Multiple simultaneous notifications respect cooldown and refreshing same data never re-triggers swing',
    () async {
      var now = DateTime.utc(2026, 11, 14, 10, 0, 0);
      final repo = _MutableNotificationRepository(
        items: <AppNotification>[_item(10, isRead: false)],
        unreadCount: 1,
      );

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
          notificationBellClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      // Establish baseline
      await container.read(notificationControllerProvider.future);
      expect(container.read(notificationBellTriggerProvider).ringSequence, 0);

      // Refresh with identical notification IDs -> must NOT trigger
      container.invalidate(notificationControllerProvider);
      await container.read(notificationControllerProvider.future);
      expect(container.read(notificationBellTriggerProvider).ringSequence, 0);

      // Batch of 3 new notifications arriving together -> triggers only ONCE
      repo.items = <AppNotification>[
        _item(13, isRead: false),
        _item(12, isRead: false),
        _item(11, isRead: false),
        _item(10, isRead: false),
      ];
      repo.unreadCount = 4;
      container.invalidate(notificationControllerProvider);
      await container.read(notificationControllerProvider.future);
      expect(container.read(notificationBellTriggerProvider).ringSequence, 1);

      // Another realtime notification 300ms later (inside 1200ms cooldown) -> suppressed
      now = now.add(const Duration(milliseconds: 300));
      container
          .read(notificationBellTriggerProvider.notifier)
          .onRealtimeNotification(
            const PushNotificationPayload(
              notificationId: '14',
              title: 'Burst',
              body: 'Inside cooldown',
            ),
          );
      expect(container.read(notificationBellTriggerProvider).ringSequence, 1);

      // After cooldown expires (1500ms later), a new notification triggers sequence 2
      now = now.add(const Duration(milliseconds: 1500));
      container
          .read(notificationBellTriggerProvider.notifier)
          .onRealtimeNotification(
            const PushNotificationPayload(
              notificationId: '15',
              title: 'After cooldown',
              body: 'Allowed',
            ),
          );
      expect(container.read(notificationBellTriggerProvider).ringSequence, 2);
    },
  );

  testWidgets(
    '5. Unread badge formats 1-99 and 99+, updates when marked read, and never swings on read mutations',
    (tester) async {
      final repo = _MutableNotificationRepository(
        items: <AppNotification>[
          _item(1, isRead: false),
          _item(2, isRead: false),
        ],
        unreadCount: 120,
      );

      await tester.pumpWidget(_buildHeaderTestApp(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(const ValueKey<String>('home_notification_unread_badge')),
        findsOneWidget,
      );
      expect(find.text('99+'), findsOneWidget);

      // Update to 2 unread
      repo.unreadCount = 2;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SakuraAppHeader)),
      );
      container.invalidate(notificationControllerProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('2'), findsOneWidget);
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));

      // Mark one as read -> badge becomes 1, bell stays static
      await container
          .read(notificationControllerProvider.notifier)
          .markRead(repo.items.first);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));

      // Mark all as read -> badge disappears, bell stays static
      await container
          .read(notificationControllerProvider.notifier)
          .markAllRead();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('home_notification_unread_badge')),
        findsNothing,
      );
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));
    },
  );

  testWidgets(
    '6. Switching tabs after a notification does not replay the bell swing on the newly mounted header',
    (tester) async {
      final repo = _MutableNotificationRepository(
        items: <AppNotification>[_item(1, isRead: false)],
        unreadCount: 1,
      );
      final tabNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ValueListenableBuilder<int>(
              valueListenable: tabNotifier,
              builder: (context, tab, _) {
                return Scaffold(
                  key: ValueKey<String>('tab_scaffold_$tab'),
                  appBar: SakuraAppHeader(
                    key: ValueKey<String>('tab_header_$tab'),
                    streakDays: 3,
                  ),
                  body: Text('Tab $tab'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Trigger a new notification on Tab 0
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SakuraAppHeader)),
      );
      container
          .read(notificationBellTriggerProvider.notifier)
          .onRealtimeNotification(
            const PushNotificationPayload(
              notificationId: '99',
              title: 'New',
              body: 'Body',
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));

      // Switch to Tab 1 (mounts a fresh SakuraAppHeader) -> must NOT swing
      tabNotifier.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));
    },
  );

  test(
    '7. Logout / account switch clears stale notification state and resets bell trigger baseline',
    () async {
      final userIdNotifier = ValueNotifier<int?>(101);
      final repo = _MutableNotificationRepository(
        items: <AppNotification>[_item(1, isRead: false)],
        unreadCount: 3,
      );

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
          authenticatedUserIdProvider.overrideWith((ref) {
            void listener() => ref.invalidateSelf();
            userIdNotifier.addListener(listener);
            ref.onDispose(() => userIdNotifier.removeListener(listener));
            return userIdNotifier.value;
          }),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(notificationControllerProvider.future);
      expect(initial.unreadCount, 3);

      // Trigger one ring for user 101
      container
          .read(notificationBellTriggerProvider.notifier)
          .onRealtimeNotification(
            const PushNotificationPayload(
              notificationId: '50',
              title: 'User 101',
              body: 'Msg',
            ),
          );
      expect(container.read(notificationBellTriggerProvider).ringSequence, 1);

      // Logout (userId -> null)
      userIdNotifier.value = null;
      final afterLogout = await container.read(
        notificationControllerProvider.future,
      );
      expect(afterLogout.items, isEmpty);
      expect(afterLogout.unreadCount, 0);
      expect(container.read(notificationBellTriggerProvider).ringSequence, 0);
    },
  );

  testWidgets(
    '8, 9 & 10. Reduced motion disables swing while keeping badge, tap opens callback, and 360dp header has zero overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tappedNotifications = 0;
      final repo = _MutableNotificationRepository(
        items: <AppNotification>[_item(1, isRead: false)],
        unreadCount: 150,
      );

      await tester.pumpWidget(
        _buildHeaderTestApp(
          repo: repo,
          disableAnimations: true,
          onNotificationsPressed: () => tappedNotifications++,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SakuraAppHeader)),
      );
      container
          .read(notificationBellTriggerProvider.notifier)
          .onRealtimeNotification(
            const PushNotificationPayload(
              notificationId: '77',
              title: 'Reduced Motion',
              body: 'Static bell',
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Reduced motion keeps angle strictly 0.0
      expect(_currentBellAngle(tester), closeTo(0.0, 0.0001));
      expect(find.text('99+'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap bell -> triggers navigation callback
      await tester.tap(
        find.byKey(const ValueKey<String>('home_notification_bell_button')),
      );
      await tester.pump();
      expect(tappedNotifications, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _buildHeaderTestApp({
  required NotificationRepository repo,
  bool disableAnimations = false,
  VoidCallback? onNotificationsPressed,
}) {
  return ProviderScope(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 800),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: disableAnimations,
            ),
            child: Scaffold(
              appBar: SakuraAppHeader(
                streakDays: 12,
                onNotificationsPressed: onNotificationsPressed ?? () {},
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
}

double _currentBellAngle(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey<String>('notification_bell_swing_transform')),
  );
  final matrix = transform.transform;
  return matrix.entry(1, 0).asin();
}

AlignmentGeometry? _currentBellAlignment(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey<String>('notification_bell_swing_transform')),
  );
  return transform.alignment;
}

extension on double {
  double asin() {
    final clamped = clamp(-1.0, 1.0);
    // Small-angle / Taylor approximation or dart:math asin via atan2
    var x = clamped;
    return x + (x * x * x) / 6.0;
  }
}

AppNotification _item(int id, {required bool isRead}) {
  return AppNotification(
    id: id,
    title: 'Thông báo $id',
    message: 'Nội dung $id',
    type: 'General',
    isRead: isRead,
    createdAt: DateTime.utc(2026, 11, 14),
  );
}

class _MutableNotificationRepository implements NotificationRepository {
  _MutableNotificationRepository({
    required this.items,
    required this.unreadCount,
  });

  List<AppNotification> items;
  int unreadCount;

  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async {
    return unreadOnly
        ? items.where((item) => !item.isRead).toList(growable: false)
        : List<AppNotification>.from(items);
  }

  @override
  Future<int> loadUnreadCount() async => unreadCount;

  @override
  Future<void> markAllRead() async {
    items = items
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
    unreadCount = 0;
  }

  @override
  Future<void> markRead(int notificationId) async {
    items = items
        .map(
          (item) =>
              item.id == notificationId ? item.copyWith(isRead: true) : item,
        )
        .toList(growable: false);
    unreadCount = (unreadCount - 1).clamp(0, 1 << 30);
  }
}
