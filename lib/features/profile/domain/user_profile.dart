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
    this.startingJlptLevelId,
    this.startingJlptLevelName,
    this.currentStudyLevelId,
    this.currentStudyLevelName,
    this.learningMode = LearningMode.standard,
    this.assessedJlptLevelId,
    this.assessedJlptLevelName,
    this.placementDecision = PlacementDecision.notTaken,
    required this.dailyStudyMinutes,
    this.targetExamDate,
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
  final int? startingJlptLevelId;
  final String? startingJlptLevelName;
  final int? currentStudyLevelId;
  final String? currentStudyLevelName;
  final LearningMode learningMode;
  final int? assessedJlptLevelId;
  final String? assessedJlptLevelName;
  final PlacementDecision placementDecision;
  final int dailyStudyMinutes;
  final DateTime? targetExamDate;
  final bool emailNotificationsEnabled;
  final bool systemNotificationsEnabled;

  String get fullName => <String>[
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  JlptLevel? get supportedJlptLevel {
    final name = targetJlptLevelName;
    return name == null ? null : JlptLevel.tryParse(name);
  }
}

enum PlacementDecision { notTaken, skipped, completed }

enum LearningMode { standard, aiPersonalized }

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
