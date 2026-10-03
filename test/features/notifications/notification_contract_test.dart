import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/data/api_notification_repository.dart';
import 'package:rikipath_mobile/features/notifications/data/notification_api_paths.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';

void main() {
  test('uses verified in-app notification endpoints', () {
    expect(NotificationApiPaths.list, '/api/Notification');
    expect(NotificationApiPaths.unreadCount, '/api/Notification/unread-count');
    expect(NotificationApiPaths.markRead(42), '/api/Notification/42/read');
    expect(NotificationApiPaths.markAllRead, '/api/Notification/mark-all-read');
  });

  test('copyWith updates read state only', () {
    final notification = AppNotification(
      id: 7,
      title: 'RikiPath',
      message: 'Message',
      type: 'General',
      isRead: false,
      createdAt: DateTime.utc(2026),
    );

    final read = notification.copyWith(isRead: true);
    expect(read.isRead, isTrue);
    expect(read.id, 7);
    expect(read.message, 'Message');
  });

  test(
    'mark read and mark all read update unread state optimistically',
    () async {
      final repository = _NotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(notificationControllerProvider.future);

      final controller = container.read(
        notificationControllerProvider.notifier,
      );
      await controller.markRead(repository.items.first);
      var state = container.read(notificationControllerProvider).requireValue;
      expect(state.unreadCount, 1);
      expect(state.items.first.isRead, isTrue);
      expect(repository.markedIds, <int>[1]);

      await controller.markAllRead();
      state = container.read(notificationControllerProvider).requireValue;
      expect(state.unreadCount, 0);
      expect(state.items.every((item) => item.isRead), isTrue);
      expect(repository.markAllCalls, 1);
    },
  );

  test('list failure preserves a successful unread count for Home', () async {
    final repository = _NotificationRepository(listError: const NetworkError());
    final container = _container(repository);
    addTearDown(container.dispose);

    final state = await container.read(notificationControllerProvider.future);

    expect(state.isListUnavailable, isTrue);
    expect(state.items, isEmpty);
    expect(state.unreadCount, 2);
  });

  test('empty notification list remains a distinct successful state', () async {
    final repository = _NotificationRepository(items: const [], unreadCount: 0);
    final container = _container(repository);
    addTearDown(container.dispose);

    final state = await container.read(notificationControllerProvider.future);

    expect(state.items, isEmpty);
    expect(state.isListUnavailable, isFalse);
    expect(state.unreadCount, 0);
  });

  test('unread-count failure preserves the notification list', () async {
    final repository = _NotificationRepository(
      countError: const NetworkError(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final state = await container.read(notificationControllerProvider.future);

    expect(state.isUnreadCountUnavailable, isTrue);
    expect(state.items, hasLength(2));
    expect(state.unreadCount, isNull);
  });

  test('both notification reads failing produces a retryable error', () async {
    final repository = _NotificationRepository(
      listError: const NetworkError(),
      countError: const ServerError(statusCode: 500),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await expectLater(
      container.read(notificationControllerProvider.future),
      throwsA(isA<NetworkError>()),
    );
  });

  test('mark-read failure rolls back and is returned safely', () async {
    final repository = _NotificationRepository(
      markReadError: const ForbiddenError(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationControllerProvider.future);

    final success = await container
        .read(notificationControllerProvider.notifier)
        .markRead(repository.items.first);
    final state = container.read(notificationControllerProvider).requireValue;

    expect(success, isFalse);
    expect(state.items.first.isRead, isFalse);
    expect(state.unreadCount, 2);
  });

  test('mark-all failure rolls back and is returned safely', () async {
    final repository = _NotificationRepository(
      markAllError: const NetworkError(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationControllerProvider.future);

    final success = await container
        .read(notificationControllerProvider.notifier)
        .markAllRead();
    final state = container.read(notificationControllerProvider).requireValue;

    expect(success, isFalse);
    expect(state.items.every((item) => !item.isRead), isTrue);
    expect(state.unreadCount, 2);
  });

  test('duplicate mark-read tap sends only one mutation', () async {
    final gate = Completer<void>();
    final repository = _NotificationRepository(markReadGate: gate);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationControllerProvider.future);
    final controller = container.read(notificationControllerProvider.notifier);

    final first = controller.markRead(repository.items.first);
    final duplicate = await controller.markRead(repository.items.first);
    expect(duplicate, isFalse);
    expect(repository.markedIds, <int>[1]);

    gate.complete();
    expect(await first, isTrue);
  });

  test('duplicate mark-all tap sends only one mutation', () async {
    final gate = Completer<void>();
    final repository = _NotificationRepository(markAllGate: gate);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationControllerProvider.future);
    final controller = container.read(notificationControllerProvider.notifier);

    final first = controller.markAllRead();
    final duplicate = await controller.markAllRead();
    expect(duplicate, isFalse);
    expect(repository.markAllCalls, 1);

    gate.complete();
    expect(await first, isTrue);
  });

  test('malformed notification identity is rejected before mutation', () async {
    final repository = ApiNotificationRepository(
      _NotificationApiClient(<String, Object?>{
        NotificationApiPaths.list: <String, Object?>{
          'result': <String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'id': 0,
                'title': 'Unsafe',
                'message': 'Unsafe identity',
                'type': 'General',
                'isRead': false,
                'createdAt': '2026-10-03T00:00:00Z',
              },
            ],
          },
        },
      }),
    );

    await expectLater(
      repository.loadNotifications(),
      throwsA(isA<UnknownError>()),
    );
  });

  test('verified notification response fields are parsed exactly', () async {
    final repository = ApiNotificationRepository(
      _NotificationApiClient(<String, Object?>{
        NotificationApiPaths.list: <String, Object?>{
          'result': <String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'id': 9,
                'title': 'Nhắc ôn tập',
                'message': 'Bạn có thẻ cần ôn.',
                'type': 'srs_reminder',
                'isRead': false,
                'createdAt': '2026-10-03T00:00:00Z',
              },
            ],
          },
        },
      }),
    );

    final notifications = await repository.loadNotifications();

    expect(notifications.single.id, 9);
    expect(notifications.single.type, 'srs_reminder');
    expect(notifications.single.createdAt, DateTime.utc(2026, 10, 3));
  });

  test('one malformed notification does not erase a valid sibling', () async {
    final repository = ApiNotificationRepository(
      _NotificationApiClient(<String, Object?>{
        NotificationApiPaths.list: <String, Object?>{
          'result': <String, Object?>{
            'items': <Object?>[
              <String, Object?>{'id': 0},
              <String, Object?>{
                'id': 10,
                'title': 'Kết quả mới',
                'message': 'Kết quả chấm điểm đã sẵn sàng.',
                'type': 'grading_result',
                'isRead': false,
                'createdAt': '2026-10-03T00:00:00Z',
              },
            ],
          },
        },
      }),
    );

    final notifications = await repository.loadNotifications();

    expect(notifications.single.id, 10);
  });

  test('malformed unread count is not converted to zero', () async {
    final repository = ApiNotificationRepository(
      _NotificationApiClient(<String, Object?>{
        NotificationApiPaths.unreadCount: <String, Object?>{'result': 'many'},
      }),
    );

    await expectLater(
      repository.loadUnreadCount(),
      throwsA(isA<UnknownError>()),
    );
  });
}

ProviderContainer _container(NotificationRepository repository) {
  return ProviderContainer(
    overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
  );
}

class _NotificationRepository implements NotificationRepository {
  _NotificationRepository({
    List<AppNotification>? items,
    this.unreadCount = 2,
    this.listError,
    this.countError,
    this.markReadError,
    this.markAllError,
    this.markReadGate,
    this.markAllGate,
  }) : items =
           items ??
           <AppNotification>[
             AppNotification(
               id: 1,
               title: 'One',
               message: 'First',
               type: 'General',
               isRead: false,
               createdAt: DateTime.utc(2026),
             ),
             AppNotification(
               id: 2,
               title: 'Two',
               message: 'Second',
               type: 'General',
               isRead: false,
               createdAt: DateTime.utc(2026),
             ),
           ];

  final Object? listError;
  final int unreadCount;
  final Object? countError;
  final Object? markReadError;
  final Object? markAllError;
  final Completer<void>? markReadGate;
  final Completer<void>? markAllGate;
  final List<AppNotification> items;
  final List<int> markedIds = <int>[];
  int markAllCalls = 0;

  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async {
    if (listError != null) throw listError!;
    return items;
  }

  @override
  Future<int> loadUnreadCount() async {
    if (countError != null) throw countError!;
    return unreadCount;
  }

  @override
  Future<void> markAllRead() async {
    markAllCalls++;
    if (markAllError != null) throw markAllError!;
    await markAllGate?.future;
  }

  @override
  Future<void> markRead(int notificationId) async {
    markedIds.add(notificationId);
    if (markReadError != null) throw markReadError!;
    await markReadGate?.future;
  }
}

class _NotificationApiClient extends ApiClient {
  _NotificationApiClient(this.responses) : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responses[path] as T,
    );
  }
}
