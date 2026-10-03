import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('notification cards tolerate long content at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _NotificationRepository(
      items: [
        AppNotification(
          id: 1,
          title: 'Bài học mới dành cho lộ trình tiếng Nhật của bạn',
          message:
              'Nội dung hôm nay đã sẵn sàng. Hãy tiếp tục từ bài gần nhất trong lộ trình.',
          type: 'InternalSystemTypeThatShouldNotBeVisible',
          isRead: false,
          createdAt: DateTime.utc(2026, 10, 3),
        ),
        AppNotification(
          id: 2,
          title: 'Nhắc lịch ôn tập',
          message: 'Bạn có thẻ cần ôn hôm nay.',
          type: 'Reminder',
          isRead: true,
          createdAt: DateTime.utc(2026, 10, 3),
        ),
      ],
    );

    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(find.byType(RikiCard), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('notification_unread_indicator')),
      findsOneWidget,
    );
    expect(find.text('InternalSystemTypeThatShouldNotBeVisible'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty notifications use the shared empty state in Japanese', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const _NotificationRepository(items: []),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RikiEmptyState), findsOneWidget);
    expect(find.text('通知'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(
  NotificationRepository repository, {
  Locale locale = const Locale('vi'),
}) {
  return ProviderScope(
    overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationsScreen(),
    ),
  );
}

class _NotificationRepository implements NotificationRepository {
  const _NotificationRepository({required this.items});

  final List<AppNotification> items;

  @override
  Future<List<AppNotification>> loadNotifications({bool unreadOnly = false}) {
    return Future.value(
      unreadOnly ? items.where((item) => !item.isRead).toList() : items,
    );
  }

  @override
  Future<int> loadUnreadCount() async =>
      items.where((item) => !item.isRead).length;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}
