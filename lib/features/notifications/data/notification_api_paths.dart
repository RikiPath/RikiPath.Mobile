abstract final class NotificationApiPaths {
  static const String list = '/api/Notification';
  static const String unreadCount = '/api/Notification/unread-count';
  static const String markAllRead = '/api/Notification/mark-all-read';

  static String markRead(int notificationId) =>
      '/api/Notification/$notificationId/read';
}
