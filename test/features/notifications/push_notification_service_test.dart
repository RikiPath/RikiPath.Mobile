import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notifications/application/push_notification_service.dart';
import 'package:rikipath_mobile/features/notifications/data/notification_api_paths.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';

class _FakePushApiClient extends ApiClient {
  _FakePushApiClient() : super(Dio(), const ApiErrorMapper());

  final List<Map<String, dynamic>> postCalls = [];

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    postCalls.add({'path': path, 'data': data});
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'result': 'ok'} as T,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SignalR notification maps server ID and Mentor decision', () {
    final payload = PushNotificationService.payloadFromSignalR([
      {
        'id': 42,
        'title': 'Hồ sơ đã được duyệt',
        'message': 'Bạn có thể xem hồ sơ của mình.',
        'type': 'MentorVerificationResult',
        'linkUrl': '/mentor/profile',
      },
    ]);
    expect(payload?.notificationId, '42');
    expect(payload?.type, 'MentorVerificationResult');
    expect(payload?.linkUrl, '/mentor/profile');
    expect(PushNotificationService.payloadFromSignalR([{'id': 'bad'}]), isNull);
  });

  group('PushNotificationService Device Token Lifecycle', () {
    test(
      'getDeviceIdentifier generates and persists unique device id',
      () async {
        final fakeApi = _FakePushApiClient();
        final prefs = await SharedPreferences.getInstance();
        final service = PushNotificationService(
          apiClient: fakeApi,
          preferences: prefs,
        );

        final id1 = await service.getDeviceIdentifier();
        expect(id1, isNotEmpty);
        expect(id1.startsWith('dev-'), isTrue);

        // Second call returns cached / persisted ID
        final id2 = await service.getDeviceIdentifier();
        expect(id2, equals(id1));
        expect(prefs.getString('rikipath_push_device_id'), equals(id1));
      },
    );

    test('registerDeviceToken sends correct payload to Backend', () async {
      final fakeApi = _FakePushApiClient();
      final prefs = await SharedPreferences.getInstance();
      final service = PushNotificationService(
        apiClient: fakeApi,
        preferences: prefs,
      );

      final success = await service.registerDeviceToken(
        fcmToken: 'fcm-test-token-123',
        platform: 'Android',
      );

      expect(success, isTrue);
      expect(service.isRegistered, isTrue);
      expect(service.currentToken, equals('fcm-test-token-123'));

      expect(fakeApi.postCalls, hasLength(1));
      final call = fakeApi.postCalls.first;
      expect(call['path'], equals(NotificationApiPaths.registerDeviceToken));
      final data = call['data'] as Map<String, dynamic>;
      expect(data['fcmToken'], equals('fcm-test-token-123'));
      expect(data['platform'], equals('Android'));
      expect(data['deviceIdentifier'], isNotEmpty);
    });

    test('registerDeviceToken with empty token fails safely', () async {
      final fakeApi = _FakePushApiClient();
      final service = PushNotificationService(apiClient: fakeApi);

      final success = await service.registerDeviceToken(fcmToken: '   ');
      expect(success, isFalse);
      expect(service.isRegistered, isFalse);
      expect(fakeApi.postCalls, isEmpty);
    });

    test('unregisterDeviceToken notifies backend and resets state', () async {
      final fakeApi = _FakePushApiClient();
      final service = PushNotificationService(apiClient: fakeApi);

      await service.registerDeviceToken(fcmToken: 'token-active');
      expect(service.isRegistered, isTrue);

      final unregistered = await service.unregisterDeviceToken();
      expect(unregistered, isTrue);
      expect(service.isRegistered, isFalse);
      expect(service.currentToken, isNull);

      final unregisterCall = fakeApi.postCalls.last;
      expect(
        unregisterCall['path'],
        equals(NotificationApiPaths.unregisterDeviceToken),
      );
      final data = unregisterCall['data'] as Map<String, dynamic>;
      expect(data['fcmToken'], equals('token-active'));
      expect(data['deviceIdentifier'], isNotEmpty);
    });
  });

  group('Foreground Deduplication (SignalR + FCM)', () {
    test('checkAndMarkDuplicate correctly identifies duplicate notification IDs', () {
      final service = PushNotificationService(apiClient: _FakePushApiClient());

      // First time notification #100 arrives (e.g. via SignalR)
      final firstCheck = service.checkAndMarkDuplicate('100');
      expect(firstCheck, isFalse); // Not duplicate

      // Second time notification #100 arrives (e.g. via FCM push shortly after)
      final secondCheck = service.checkAndMarkDuplicate('100');
      expect(
        secondCheck,
        isTrue,
      ); // IS duplicate -> must not increment or display twice!

      // Different notification ID arrives
      final otherCheck = service.checkAndMarkDuplicate('101');
      expect(otherCheck, isFalse); // Not duplicate
    });

    test('empty or null notification ID is never treated as duplicate', () {
      final service = PushNotificationService(apiClient: _FakePushApiClient());
      expect(service.checkAndMarkDuplicate(null), isFalse);
      expect(service.checkAndMarkDuplicate(''), isFalse);
      expect(service.checkAndMarkDuplicate('   '), isFalse);
    });
  });

  group('Deep Link Resolution', () {
    final service = PushNotificationService(apiClient: _FakePushApiClient());

    test(
      'resolves booking_detail screen to learnerMentorBookingDetail route',
      () {
        final payload = PushNotificationPayload.fromMap({
          'notification': {
            'title': 'Booking Confirmed',
            'body': 'Session scheduled',
          },
          'data': {
            'screen': 'booking_detail',
            'bookingId': '45',
            'notificationId': '900',
          },
        });

        final route = service.resolveDeepLink(payload);
        expect(route, equals(AppRoutes.learnerMentorBookingDetail(45)));
      },
    );

    test('resolves meeting_room screen to mentorMeetingDetail route', () {
      final payload = PushNotificationPayload.fromMap({
        'notification': {'title': 'Meeting Ready', 'body': 'Join room now'},
        'data': {
          'screen': 'meeting_room',
          'meetingId': '12',
          'notificationId': '901',
        },
      });

      final route = service.resolveDeepLink(payload);
      expect(route, equals(AppRoutes.mentorMeetingDetail(12)));
    });

    test('resolves direct linkUrl when screen is not specified', () {
      final payload = PushNotificationPayload.fromMap({
        'notification': {'title': 'New Update', 'body': 'Check your schedule'},
        'data': {'linkUrl': '/mentor/availability', 'notificationId': '902'},
      });

      final route = service.resolveDeepLink(payload);
      expect(route, equals('/mentor/availability'));
    });

    test(
      'mentor verification result opens own profile and ignores untrusted link',
      () {
        final payload = PushNotificationPayload.fromMap({
          'data': {
            'type': 'MentorVerificationResult',
            'linkUrl': '/admin/mentor-verifications?mentorId=7',
          },
        });
        expect(service.resolveDeepLink(payload), AppRoutes.mentorProfile);
      },
    );

    test('rejects arbitrary notification route', () {
      final payload = PushNotificationPayload.fromMap({
        'data': {'linkUrl': '/admin/mentors'},
      });
      expect(service.resolveDeepLink(payload), AppRoutes.notifications);
    });

    test(
      'falls back to notifications inbox when no specific deep link target',
      () {
        final payload = PushNotificationPayload.fromMap({
          'notification': {'title': 'General', 'body': 'Welcome'},
          'data': {},
        });

        final route = service.resolveDeepLink(payload);
        expect(route, equals(AppRoutes.notifications));
      },
    );

    test(
      'background message handler entry-point executes without throwing',
      () async {
        await expectLater(
          firebaseMessagingBackgroundHandler(
            const RemoteMessage(
              notification: RemoteNotification(
                title: 'Bg Title',
                body: 'Bg Body',
              ),
              data: {'bookingId': '10', 'screen': 'booking_detail'},
            ),
          ),
          completes,
        );
      },
    );

    test('PushNotificationPayload.fromRemoteMessage parses correctly', () {
      const message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Remote Title',
          body: 'Remote Body',
        ),
        data: {
          'notificationId': '888',
          'screen': 'booking_detail',
          'bookingId': '77',
        },
      );

      final payload = PushNotificationPayload.fromRemoteMessage(message);
      expect(payload.title, equals('Remote Title'));
      expect(payload.body, equals('Remote Body'));
      expect(payload.notificationId, equals('888'));
      expect(payload.screen, equals('booking_detail'));
      expect(payload.bookingId, equals('77'));

      final deepLink = service.resolveDeepLink(payload);
      expect(deepLink, equals(AppRoutes.learnerMentorBookingDetail(77)));
    });

    test('initializeFirebaseMessaging completes gracefully when Firebase unconfigured', () async {
      final unconfiguredService = PushNotificationService(
        apiClient: _FakePushApiClient(),
      );

      expect(unconfiguredService.isFirebaseAvailable, isFalse);
      await expectLater(
        unconfiguredService.initializeFirebaseMessaging(),
        completes,
      );
      unconfiguredService.dispose();
    });
  });
}
