import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notifications/data/notification_api_paths.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  const ApiNotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get<Object?>(
      NotificationApiPaths.list,
      queryParameters: unreadOnly ? const {'unreadOnly': true} : null,
    );
    final body = _unwrap(response.data);
    final rawItems = body is Map ? body['items'] : null;
    if (rawItems is! List) throw _malformedNotifications;
    final notifications = <AppNotification>[];
    for (final item in rawItems) {
      try {
        if (item is! Map<Object?, Object?>) throw _malformedNotifications;
        notifications.add(_notificationFromMap(item));
      } catch (_) {
        // A corrupt record is ignored without inventing an ID for mutations.
      }
    }
    if (rawItems.isNotEmpty && notifications.isEmpty) {
      throw _malformedNotifications;
    }
    return List<AppNotification>.unmodifiable(notifications);
  }

  @override
  Future<int> loadUnreadCount() async {
    final response = await _apiClient.get<Object?>(
      NotificationApiPaths.unreadCount,
    );
    final body = _unwrap(response.data);
    final count = switch (body) {
      int value => value,
      num value when value.isFinite && value == value.roundToDouble() =>
        value.toInt(),
      _ => null,
    };
    if (count == null || count < 0) throw _malformedNotifications;
    return count;
  }

  @override
  Future<void> markRead(int notificationId) async {
    await _apiClient.patch<Object?>(
      NotificationApiPaths.markRead(notificationId),
    );
  }

  @override
  Future<void> markAllRead() async {
    await _apiClient.patch<Object?>(NotificationApiPaths.markAllRead);
  }

  AppNotification _notificationFromMap(Map<Object?, Object?> item) {
    final map = item.map((key, value) => MapEntry(key.toString(), value));
    final id = map['id'];
    final title = map['title'];
    final message = map['message'];
    final type = map['type'];
    final isRead = map['isRead'];
    final createdAt = map['createdAt'];
    final parsedDate = createdAt is String
        ? DateTime.tryParse(createdAt)
        : null;
    if (id is! int ||
        id <= 0 ||
        title is! String ||
        message is! String ||
        type is! String ||
        isRead is! bool ||
        parsedDate == null) {
      throw _malformedNotifications;
    }
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead,
      createdAt: parsedDate,
    );
  }

  Object? _unwrap(Object? body) {
    if (body is Map && body.containsKey('result')) return body['result'];
    return body;
  }
}

const _malformedNotifications = UnknownError(
  message: 'The notification response was malformed.',
);
