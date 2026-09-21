import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.role,
    required this.isEmailVerified,
    required this.targetJlptLevelId,
    required this.targetJlptLevelName,
    required this.dailyStudyMinutes,
    required this.emailNotificationsEnabled,
    required this.systemNotificationsEnabled,
  });

  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String role;
  final bool isEmailVerified;
  final int? targetJlptLevelId;
  final String? targetJlptLevelName;
  final int dailyStudyMinutes;
  final bool emailNotificationsEnabled;
  final bool systemNotificationsEnabled;

  String get fullName => <String>[
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  JlptLevel? get supportedJlptLevel {
    return switch (targetJlptLevelName?.trim().toUpperCase()) {
      'N5' => JlptLevel.n5,
      'N4' => JlptLevel.n4,
      'N3' => JlptLevel.n3,
      _ => null,
    };
  }
}

@immutable
class ProfileAvatarUpload {
  const ProfileAvatarUpload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

class UnsupportedAvatarTypeException implements Exception {
  const UnsupportedAvatarTypeException();
}

class AvatarTooLargeException implements Exception {
  const AvatarTooLargeException();
}
