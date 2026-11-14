import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/notifications/data/api_notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => ApiNotificationRepository(ref.watch(apiClientProvider)),
);

final notificationBellClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
      retry: (_, _) => null,
    );

final notificationBellTriggerProvider =
    NotifierProvider<
      NotificationBellTriggerController,
      NotificationBellTriggerState
    >(NotificationBellTriggerController.new);

class NotificationController extends AsyncNotifier<NotificationState> {
  int? _previousUserId;

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationState> build() async {
    final currentUserId = ref.watch(authenticatedUserIdProvider);
    final wasAuthenticated = _previousUserId != null;
    _previousUserId = currentUserId;

    if (wasAuthenticated && currentUserId == null) {
      return const NotificationState(
        items: <AppNotification>[],
        unreadCount: 0,
      );
    }

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

/// Tracks notification identities across the active user session and emits a
/// monotonic [ringSequence] only when genuinely new unread notifications arrive
/// after the initial baseline load.
class NotificationBellTriggerState {
  const NotificationBellTriggerState({
    this.ringSequence = 0,
    this.consumedSequence = 0,
    this.lastRingAt,
    this.hasBaseline = false,
  });

  final int ringSequence;
  final int consumedSequence;
  final DateTime? lastRingAt;
  final bool hasBaseline;

  bool get hasPendingRing => ringSequence > consumedSequence;

  NotificationBellTriggerState copyWith({
    int? ringSequence,
    int? consumedSequence,
    DateTime? lastRingAt,
    bool? hasBaseline,
  }) {
    return NotificationBellTriggerState(
      ringSequence: ringSequence ?? this.ringSequence,
      consumedSequence: consumedSequence ?? this.consumedSequence,
      lastRingAt: lastRingAt ?? this.lastRingAt,
      hasBaseline: hasBaseline ?? this.hasBaseline,
    );
  }
}

class NotificationBellTriggerController
    extends Notifier<NotificationBellTriggerState> {
  static const Duration ringCooldown = Duration(milliseconds: 1200);

  final Set<int> _knownNotificationIds = <int>{};
  final Set<String> _knownRealtimeKeys = <String>{};
  bool _hasBaseline = false;

  DateTime Function() get _clock => ref.read(notificationBellClockProvider);

  @override
  NotificationBellTriggerState build() {
    ref.watch(authenticatedUserIdProvider);
    _knownNotificationIds.clear();
    _knownRealtimeKeys.clear();
    _hasBaseline = false;

    final currentSnapshot = ref.read(notificationControllerProvider).value;
    if (currentSnapshot != null && !currentSnapshot.isListUnavailable) {
      for (final item in currentSnapshot.items) {
        _knownNotificationIds.add(item.id);
      }
      _hasBaseline = true;
    }

    ref.listen<AsyncValue<NotificationState>>(
      notificationControllerProvider,
      _handleNotificationSnapshot,
    );

    return NotificationBellTriggerState(hasBaseline: _hasBaseline);
  }

  void _handleNotificationSnapshot(
    AsyncValue<NotificationState>? previous,
    AsyncValue<NotificationState> next,
  ) {
    final snapshot = next.value;
    if (snapshot == null) return;

    // If the list endpoint failed, we cannot establish or diff notification IDs
    // from this snapshot alone.
    if (snapshot.isListUnavailable) return;

    if (!_hasBaseline) {
      for (final item in snapshot.items) {
        _knownNotificationIds.add(item.id);
      }
      _hasBaseline = true;
      state = state.copyWith(hasBaseline: true);
      return;
    }

    var foundNewUnread = false;
    for (final item in snapshot.items) {
      final isNew = _knownNotificationIds.add(item.id);
      if (isNew && !item.isRead) {
        foundNewUnread = true;
      }
    }

    if (foundNewUnread) {
      _emitRingWithCooldown();
    }
  }

  /// Triggered when a foreground SignalR / FCM push event arrives.
  void onRealtimeNotification(PushNotificationPayload payload) {
    final rawId = payload.notificationId?.trim();
    if (rawId != null && rawId.isNotEmpty) {
      final parsedId = int.tryParse(rawId);
      if (parsedId != null && parsedId > 0) {
        final isNew = _knownNotificationIds.add(parsedId);
        if (!isNew) return;
        _hasBaseline = true;
        state = state.copyWith(hasBaseline: true);
        _emitRingWithCooldown();
        return;
      }
      final isNewKey = _knownRealtimeKeys.add(rawId);
      if (!isNewKey) return;
      _hasBaseline = true;
      state = state.copyWith(hasBaseline: true);
      _emitRingWithCooldown();
      return;
    }

    // Ignore empty sync signals (e.g. SignalR reconnect with empty title/body).
    if (payload.title.trim().isEmpty && payload.body.trim().isEmpty) {
      return;
    }

    _emitRingWithCooldown();
  }

  void consumeRing(int sequence) {
    if (sequence <= state.consumedSequence) return;
    final clamped = sequence > state.ringSequence
        ? state.ringSequence
        : sequence;
    state = state.copyWith(consumedSequence: clamped);
  }

  void resetSession() {
    _knownNotificationIds.clear();
    _knownRealtimeKeys.clear();
    _hasBaseline = false;
    state = const NotificationBellTriggerState();
  }

  void _emitRingWithCooldown() {
    final now = _clock();
    final last = state.lastRingAt;
    if (last != null && now.difference(last) < ringCooldown) {
      return;
    }
    state = state.copyWith(
      ringSequence: state.ringSequence + 1,
      lastRingAt: now,
    );
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
