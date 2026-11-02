import 'package:firebase_messaging/firebase_messaging.dart' show RemoteMessage;

class PushNotificationPayload {
  const PushNotificationPayload({
    this.notificationId,
    required this.title,
    required this.body,
    this.type,
    this.linkUrl,
    this.screen,
    this.bookingId,
    this.meetingId,
    this.rawData = const <String, dynamic>{},
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? const _DefaultDateTime();

  final String? notificationId;
  final String title;
  final String body;
  final String? type;
  final String? linkUrl;
  final String? screen;
  final String? bookingId;
  final String? meetingId;
  final Map<String, dynamic> rawData;
  final Object receivedAt;

  DateTime get receivedDateTime =>
      receivedAt is DateTime ? receivedAt as DateTime : DateTime.now().toUtc();

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return PushNotificationPayload.fromMap({
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
      'data': message.data,
    });
  }

  factory PushNotificationPayload.fromMap(Map<String, dynamic> map) {
    final notification = map['notification'] as Map<dynamic, dynamic>? ?? {};
    final data = map['data'] as Map<dynamic, dynamic>? ?? map;

    final title = notification['title']?.toString() ??
        data['title']?.toString() ??
        'RikiPath';
    final body = notification['body']?.toString() ??
        data['body']?.toString() ??
        '';

    final notifId = data['notificationId']?.toString() ??
        data['id']?.toString();
    final type = data['type']?.toString();
    final linkUrl = data['linkUrl']?.toString();
    final screen = data['screen']?.toString();
    final bookingId = data['bookingId']?.toString();
    final meetingId = data['meetingId']?.toString();

    final stringData = <String, dynamic>{};
    data.forEach((key, value) {
      stringData[key.toString()] = value;
    });

    return PushNotificationPayload(
      notificationId: notifId,
      title: title,
      body: body,
      type: type,
      linkUrl: linkUrl,
      screen: screen,
      bookingId: bookingId,
      meetingId: meetingId,
      rawData: stringData,
      receivedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toMap() => {
    'notificationId': notificationId,
    'title': title,
    'body': body,
    'type': type,
    'linkUrl': linkUrl,
    'screen': screen,
    'bookingId': bookingId,
    'meetingId': meetingId,
    'data': rawData,
  };
}

class _DefaultDateTime {
  const _DefaultDateTime();
}
