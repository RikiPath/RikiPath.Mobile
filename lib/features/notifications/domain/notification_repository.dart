import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> loadNotifications({bool unreadOnly = false});

  Future<int> loadUnreadCount();

  Future<void> markRead(int notificationId);

  Future<void> markAllRead();
}
