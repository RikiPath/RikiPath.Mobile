import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notifications/data/api_notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => ApiNotificationRepository(ref.watch(apiClientProvider)),
);

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
      retry: (_, _) => null,
    );

class NotificationController extends AsyncNotifier<NotificationState> {
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationState> build() async {
    final (listResult, countResult) = await (
      _capture(_repository.loadNotifications),
      _capture(_repository.loadUnreadCount),
    ).wait;
    if (listResult.error != null && countResult.error != null) {
      throw listResult.error!;
    }
    return NotificationState(
      items: listResult.data ?? const <AppNotification>[],
      unreadCount: countResult.data,
      isListUnavailable: listResult.error != null,
      isUnreadCountUnavailable: countResult.error != null,
    );
  }

  Future<_ReadResult<T>> _capture<T>(Future<T> Function() read) async {
    try {
      return _ReadResult<T>.success(await read());
    } catch (error) {
      return _ReadResult<T>.failure(error);
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading<NotificationState>();
    state = await AsyncValue.guard(build);
  }

  Future<bool> markRead(AppNotification notification) async {
    if (notification.isRead) return true;
    final current = state.value;
    if (current == null || current.isMutating) return false;
    final optimistic = current.optimisticRead(notification.id);
    state = AsyncData(optimistic);
    try {
      await _repository.markRead(notification.id);
      state = AsyncData(optimistic.finishMutation());
      return true;
    } catch (_) {
      state = AsyncData(current);
      return false;
    }
  }

  Future<bool> markAllRead() async {
    final current = state.value;
    if (current == null || current.isMutating) return false;
    if (current.items.every((item) => item.isRead)) return true;
    final optimistic = current.allRead();
    state = AsyncData(optimistic);
    try {
      await _repository.markAllRead();
      state = AsyncData(optimistic.finishMutation());
      return true;
    } catch (_) {
      state = AsyncData(current);
      return false;
    }
  }
}

class NotificationState {
  const NotificationState({
    required this.items,
    required this.unreadCount,
    this.isListUnavailable = false,
    this.isUnreadCountUnavailable = false,
    this.isMutating = false,
  });

  final List<AppNotification> items;
  final int? unreadCount;
  final bool isListUnavailable;
  final bool isUnreadCountUnavailable;
  final bool isMutating;

  NotificationState optimisticRead(int id) {
    return NotificationState(
      items: items
          .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
          .toList(growable: false),
      unreadCount: unreadCount == null
          ? null
          : (unreadCount! - 1).clamp(0, 1 << 31),
      isListUnavailable: isListUnavailable,
      isUnreadCountUnavailable: isUnreadCountUnavailable,
      isMutating: true,
    );
  }

  NotificationState allRead() {
    return NotificationState(
      items: items
          .map((item) => item.copyWith(isRead: true))
          .toList(growable: false),
      unreadCount: unreadCount == null ? null : 0,
      isListUnavailable: isListUnavailable,
      isUnreadCountUnavailable: isUnreadCountUnavailable,
      isMutating: true,
    );
  }

  NotificationState finishMutation() {
    return NotificationState(
      items: items,
      unreadCount: unreadCount,
      isListUnavailable: isListUnavailable,
      isUnreadCountUnavailable: isUnreadCountUnavailable,
    );
  }
}

class _ReadResult<T> {
  const _ReadResult.success(this.data) : error = null;

  const _ReadResult.failure(this.error) : data = null;

  final T? data;
  final Object? error;
}
