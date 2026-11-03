abstract final class NotificationApiPaths {
  static const String list = '/api/Notification';
  static const String unreadCount = '/api/Notification/unread-count';
  static const String markAllRead = '/api/Notification/mark-all-read';

  static String markRead(int notificationId) =>
      '/api/Notification/$notificationId/read';

  // Device token registration & unregistration (FCM / APNs)
  static const String registerDeviceToken = '/api/devices/register';
  static const String refreshDeviceToken = '/api/devices/refresh';
  static const String unregisterDeviceToken = '/api/devices/unregister';
}
