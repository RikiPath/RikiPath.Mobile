class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.linkUrl,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? linkUrl;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      linkUrl: linkUrl,
    );
  }
}
