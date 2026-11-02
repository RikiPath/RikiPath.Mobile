import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_hub/signalr_client.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/notifications/data/notification_api_paths.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  final service = PushNotificationService(
    apiClient: apiClient,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Manages Mobile Push Notifications (FCM / APNs):
/// - Device token lifecycle (registration, token rotation, logout unregistration)
/// - Deduplication between SignalR foreground events and FCM push notifications
/// - Deep linking to Mentor Booking / Meeting Room / Notifications
/// - Safe headless / unconfigured degradation
class PushNotificationService {
  PushNotificationService({
    required this.apiClient,
    this.tokenStorage,
    this.preferences,
    this.messaging,
  });

  final ApiClient apiClient;
  final TokenStorage? tokenStorage;
  SharedPreferences? preferences;
  final FirebaseMessaging? messaging;

  String? _cachedDeviceId;
  String? _currentToken;
  bool _isRegistered = false;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  HubConnection? _notificationHub;
  Future<void>? _connectingHub;

  // Deduplication cache: notificationId -> received epoch ms
  final Map<String, int> _handledNotifications = <String, int>{};
  static const int _dedupTtlMs = 60 * 1000; // 60 seconds

  String? get currentToken => _currentToken;
  bool get isRegistered => _isRegistered;

  /// Kết nối thông báo theo JWT hiện tại; FCM vẫn xử lý khi ứng dụng ở nền.
  Future<void> connectForegroundNotifications({
    required void Function(PushNotificationPayload payload) onNotification,
  }) async {
    if (_notificationHub != null) return;
    if (_connectingHub != null) return _connectingHub;
    final storage = tokenStorage;
    if (storage == null) return;
    final token = await storage.readAccessToken();
    if (token == null || token.isEmpty) return;

    final connection = HubConnectionBuilder()
        .withUrl(
          apiClient.baseUrl.resolve('/hubs/notification').toString(),
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              final current = await storage.readAccessToken();
              if (current == null || current.isEmpty) {
                throw StateError('Authentication is required.');
              }
              return current;
            },
            requestTimeout: 10000,
          ),
        )
        .withAutomaticReconnect(
          retryDelays: const [0, 2000, 5000, 10000, 30000],
        )
        .build();
    connection.on('NotificationReceived', (arguments) {
      final payload = payloadFromSignalR(arguments);
      if (payload != null && !checkAndMarkDuplicate(payload.notificationId)) {
        onNotification(payload);
      }
    });
    connection.onreconnected(({connectionId}) {
      // REST remains authoritative for missed notifications and read state.
      onNotification(const PushNotificationPayload(title: '', body: ''));
    });
    connection.onclose(({error}) {
      if (identical(_notificationHub, connection)) {
        _notificationHub = null;
      }
    });
    _connectingHub = () async {
      try {
        await connection.start();
        _notificationHub = connection;
        await connection.invoke('RequestSync');
      } catch (_) {
        await connection.stop();
      } finally {
        _connectingHub = null;
      }
    }();
    await _connectingHub;
  }

  static PushNotificationPayload? payloadFromSignalR(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty || arguments.first is! Map) {
      return null;
    }
    final value = (arguments.first as Map).map(
      (key, item) => MapEntry(key.toString(), item),
    );
    final id = value['id'];
    if (id is! int || id <= 0 || value['title'] is! String ||
        value['message'] is! String) {
      return null;
    }
    return PushNotificationPayload.fromMap({
      'notificationId': id.toString(),
      'title': value['title'],
      'body': value['message'],
      'type': value['type'],
      'linkUrl': value['linkUrl'],
    });
  }

  Future<void> disconnectForegroundNotifications() async {
    final pending = _connectingHub;
    if (pending != null) await pending;
    final hub = _notificationHub;
    _notificationHub = null;
    if (hub != null) await hub.stop();
    _handledNotifications.clear();
  }

  bool get isFirebaseAvailable {
    if (messaging != null) return true;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseMessaging? get _resolvedMessaging {
    if (messaging != null) return messaging;
    if (isFirebaseAvailable) {
      try {
        return FirebaseMessaging.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<SharedPreferences> _getPrefs() async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences!;
  }

  /// Initializes Firebase Messaging permissions, listeners, and live token registration.
  /// Degrades gracefully if Firebase is not configured or throws.
  Future<void> initializeFirebaseMessaging({
    GoRouter? router,
    void Function(PushNotificationPayload payload)? onForegroundNotification,
  }) async {
    final msg = _resolvedMessaging;
    if (msg == null) {
      debugPrint(
        '[PushNotificationService] FirebaseMessaging not available, skipping runtime init.',
      );
      return;
    }

    try {
      final settings = await msg.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
        '[PushNotificationService] Notification permission status: ${settings.authorizationStatus}',
      );

      await msg.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Set top-level background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen to token registration & rotation
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = msg.onRegistered.listen((token) async {
        debugPrint('[PushNotificationService] FCM token registered.');
        await registerDeviceToken(fcmToken: token);
      });

      // Register / retrieve token via newest API
      try {
        await msg.register();
      } catch (e) {
        debugPrint('[PushNotificationService] Could not register FCM: $e');
      }

      // Fallback token retrieval if token wasn't emitted yet
      try {
        // ignore: deprecated_member_use
        final token = await msg.getToken();
        debugPrint('[PushNotificationService] Fallback FCM token retrieved.');
        if (token != null && token.trim().isNotEmpty && _currentToken == null) {
          await registerDeviceToken(fcmToken: token);
        }
      } catch (_) {}

      // Listen to foreground messages (deduplicated against SignalR)
      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
        final payload = PushNotificationPayload.fromRemoteMessage(message);
        final isDuplicate = checkAndMarkDuplicate(payload.notificationId);
        if (isDuplicate) {
          debugPrint(
            '[PushNotificationService] Skipping duplicate foreground message: ${payload.notificationId}',
          );
          return;
        }
        if (onForegroundNotification != null) {
          onForegroundNotification(payload);
        }
      });

      // Listen to notification clicks from background state
      _onMessageOpenedAppSub?.cancel();
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        final payload = PushNotificationPayload.fromRemoteMessage(message);
        if (router != null) {
          handleNotificationTap(router, payload);
        }
      });

      // Check if app was opened from terminated state by a notification
      final initialMessage = await msg.getInitialMessage();
      if (initialMessage != null && router != null) {
        final payload = PushNotificationPayload.fromRemoteMessage(
          initialMessage,
        );
        handleNotificationTap(router, payload);
      }
    } catch (e) {
      debugPrint(
        '[PushNotificationService] Error initializing FirebaseMessaging: $e',
      );
    }
  }

  /// Returns a persistent device UUID, creating one if not already saved.
  Future<String> getDeviceIdentifier() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await _getPrefs();
    var id = prefs.getString('rikipath_push_device_id');
    if (id == null || id.isEmpty) {
      final rand = Random.secure();
      final values = List<int>.generate(16, (_) => rand.nextInt(256));
      id =
          'dev-${values.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      await prefs.setString('rikipath_push_device_id', id);
    }
    _cachedDeviceId = id;
    return id;
  }

  /// Registers or rotates an FCM device token with the Backend.
  Future<bool> registerDeviceToken({
    required String fcmToken,
    String platform = 'Android',
  }) async {
    if (fcmToken.trim().isEmpty) return false;
    try {
      final deviceId = await getDeviceIdentifier();
      final response = await apiClient.post<Object?>(
        NotificationApiPaths.registerDeviceToken,
        data: {
          'deviceIdentifier': deviceId,
          'platform': platform,
          'fcmToken': fcmToken.trim(),
        },
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        _currentToken = fcmToken.trim();
        _isRegistered = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(
        '[PushNotificationService] Failed to register device token: $e',
      );
      return false;
    }
  }

  /// Revokes/deactivates the device token upon user logout.
  Future<bool> unregisterDeviceToken({String? fcmToken}) async {
    try {
      final msg = _resolvedMessaging;
      if (msg != null) {
        try {
          await msg.unregister();
        } catch (e) {
          try {
            // ignore: deprecated_member_use
            await msg.deleteToken();
          } catch (_) {}
        }
      }

      final deviceId = await getDeviceIdentifier();
      final tokenToUnregister = fcmToken ?? _currentToken;
      final payload = <String, dynamic>{'deviceIdentifier': deviceId};
      if (tokenToUnregister != null) {
        payload['fcmToken'] = tokenToUnregister;
      }
      final response = await apiClient.post<Object?>(
        NotificationApiPaths.unregisterDeviceToken,
        data: payload,
      );
      _currentToken = null;
      _isRegistered = false;
      return (response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300;
    } catch (e) {
      debugPrint(
        '[PushNotificationService] Failed to unregister device token: $e',
      );
      _currentToken = null;
      _isRegistered = false;
      return false;
    }
  }

  /// Checks if a notificationId was already handled within the deduplication window.
  /// If not, marks it as handled and returns false. If yes, returns true (is duplicate).
  bool checkAndMarkDuplicate(String? notificationId) {
    if (notificationId == null || notificationId.trim().isEmpty) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _cleanOldDeduplications(now);

    final key = notificationId.trim();
    if (_handledNotifications.containsKey(key)) {
      return true;
    }
    _handledNotifications[key] = now;
    return false;
  }

  void _cleanOldDeduplications(int now) {
    _handledNotifications.removeWhere((_, time) => now - time > _dedupTtlMs);
  }

  /// Resolves the in-app route destination from push notification payload data.
  String resolveDeepLink(PushNotificationPayload payload) {
    // 1. Direct screen parameter with ID
    if (payload.screen == 'booking_detail' && payload.bookingId != null) {
      final id = int.tryParse(payload.bookingId!);
      if (id != null && id > 0) {
        return AppRoutes.learnerMentorBookingDetail(id);
      }
    }

    if (payload.screen == 'meeting_room' && payload.meetingId != null) {
      final id = int.tryParse(payload.meetingId!);
      if (id != null && id > 0) {
        return AppRoutes.mentorMeetingDetail(id);
      }
    }

    // 2. Link URL parsing
    if (payload.type == 'MentorVerificationResult') {
      return AppRoutes.mentorProfile;
    }
    if (payload.linkUrl != null && payload.linkUrl!.trim().isNotEmpty) {
      final uri = payload.linkUrl!.trim();
      if (uri == AppRoutes.mentorAvailability ||
          uri == AppRoutes.mentorProfile) {
        return uri;
      }
    }

    // 3. Fallback to notification inbox
    return AppRoutes.notifications;
  }

  /// Navigates to the appropriate destination for a tapped push notification.
  void handleNotificationTap(GoRouter router, PushNotificationPayload payload) {
    final destination = resolveDeepLink(payload);
    router.go(destination);
  }

  void dispose() {
    unawaited(disconnectForegroundNotifications());
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}

/// Standalone top-level background message handler for background/terminated app states.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // In terminated / background state, Android/iOS system shows notification automatically.
  // Data payload is processed when app is launched via notification tap.
  debugPrint('[PushNotificationBackground] Received background push message.');
}
