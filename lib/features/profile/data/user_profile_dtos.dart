class UserProfileDto {
  const UserProfileDto({
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
    this.learningMode = 'STANDARD',
    this.assessedJlptLevelId,
    this.assessedJlptLevelName,
    this.placementDecision = 'NOT_TAKEN',
    required this.dailyStudyMinutes,
    this.targetExamDate,
    this.learningGoalVersion = 0,
    this.certifiedJlptLevelId,
    this.certifiedJlptLevelName,
    required this.emailNotificationsEnabled,
    required this.systemNotificationsEnabled,
  });

  factory UserProfileDto.fromEnvelope(Object? body) {
    final envelope = _stringKeyedMap(body);
    if (envelope['isSuccess'] != true) {
      throw const FormatException('Expected a successful API envelope.');
    }
    return UserProfileDto.fromJson(_stringKeyedMap(envelope['result']));
  }

  factory UserProfileDto.fromJson(Map<String, Object?> json) {
    return UserProfileDto(
      userId: _requiredInt(json, 'userId'),
      email: _requiredString(json, 'email'),
      firstName: _requiredString(json, 'firstName'),
      lastName: _requiredString(json, 'lastName'),
      avatarUrl: _optionalString(json, 'avatarUrl'),
      role: _requiredString(json, 'role'),
      isEmailVerified: _requiredBool(json, 'isEmailVerified'),
      targetJlptLevelId: _optionalInt(json, 'targetJlptLevelId'),
      targetJlptLevelName: _optionalString(json, 'targetJlptLevelName'),
      startingJlptLevelId: _optionalInt(json, 'startingJlptLevelId'),
      startingJlptLevelName: _optionalString(json, 'startingJlptLevelName'),
      currentStudyLevelId: _optionalInt(json, 'currentStudyLevelId'),
      currentStudyLevelName: _optionalString(json, 'currentStudyLevelName'),
      learningMode: _optionalString(json, 'learningMode') ?? 'STANDARD',
      assessedJlptLevelId: _optionalInt(json, 'assessedJlptLevelId'),
      assessedJlptLevelName: _optionalString(json, 'assessedJlptLevelName'),
      placementDecision:
          _optionalString(json, 'placementDecision') ?? 'NOT_TAKEN',
      dailyStudyMinutes: _requiredInt(json, 'dailyStudyMinutes'),
      targetExamDate: _optionalDateTime(json, 'targetExamDate'),
      learningGoalVersion: _optionalInt(json, 'learningGoalVersion') ?? 0,
      certifiedJlptLevelId: _optionalInt(json, 'certifiedJlptLevelId'),
      certifiedJlptLevelName: _optionalString(json, 'certifiedJlptLevelName'),
      emailNotificationsEnabled: _requiredBool(
        json,
        'emailNotificationsEnabled',
      ),
      systemNotificationsEnabled: _requiredBool(
        json,
        'systemNotificationsEnabled',
      ),
    );
  }

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
  final String learningMode;
  final int? assessedJlptLevelId;
  final String? assessedJlptLevelName;
  final String placementDecision;
  final int dailyStudyMinutes;
  final DateTime? targetExamDate;
  final int learningGoalVersion;
  final int? certifiedJlptLevelId;
  final String? certifiedJlptLevelName;
  final bool emailNotificationsEnabled;
  final bool systemNotificationsEnabled;
}

class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    required this.firstName,
    required this.lastName,
  });

  final String firstName;
  final String lastName;

  Map<String, Object?> toJson() => <String, Object?>{
    'firstName': firstName,
    'lastName': lastName,
  };
}

class SetJlptGoalRequestDto {
  const SetJlptGoalRequestDto({
    required this.targetJlptLevelId,
    required this.dailyStudyMinutes,
    this.targetExamDate,
    this.clearTargetExamDate = false,
  });

  final int targetJlptLevelId;
  final int dailyStudyMinutes;
  final DateTime? targetExamDate;
  final bool clearTargetExamDate;

  Map<String, Object?> toJson() => <String, Object?>{
    'targetJlptLevelId': targetJlptLevelId,
    'dailyStudyMinutes': dailyStudyMinutes,
    if (targetExamDate != null) 'targetExamDate': _dateOnlyIso(targetExamDate!),
    if (clearTargetExamDate) 'clearTargetExamDate': true,
  };
}

class SetLearningGoalRequestDto {
  const SetLearningGoalRequestDto({
    required this.currentStudyLevelId,
    required this.targetJlptLevelId,
    required this.dailyStudyMinutes,
    required this.targetExamDate,
    required this.certifiedJlptLevelId,
    required this.expectedVersion,
  });

  final int currentStudyLevelId;
  final int targetJlptLevelId;
  final int dailyStudyMinutes;
  final DateTime? targetExamDate;
  final int? certifiedJlptLevelId;
  final int expectedVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'currentStudyLevelId': currentStudyLevelId,
    'targetJlptLevelId': targetJlptLevelId,
    'dailyStudyMinutes': dailyStudyMinutes,
    'targetExamDate': targetExamDate == null ? null : _dateOnlyIso(targetExamDate!),
    'hasJlptCertificate': certifiedJlptLevelId != null,
    'certifiedJlptLevelId': certifiedJlptLevelId,
    'expectedVersion': expectedVersion,
  };
}

class UpdateNotificationSettingsRequestDto {
  const UpdateNotificationSettingsRequestDto({
    required this.emailNotificationsEnabled,
    required this.systemNotificationsEnabled,
  });

  final bool emailNotificationsEnabled;
  final bool systemNotificationsEnabled;

  Map<String, Object?> toJson() => <String, Object?>{
    'emailNotificationsEnabled': emailNotificationsEnabled,
    'systemNotificationsEnabled': systemNotificationsEnabled,
  };
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Expected JSON object keys to be strings.');
    }
    result[entry.key! as String] = entry.value;
  }
  return result;
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected a nullable string field named $field.');
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('Expected an integer field named $field.');
}

int? _optionalInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('Expected a nullable integer field named $field.');
}

bool _requiredBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw FormatException('Expected a boolean field named $field.');
}

DateTime? _optionalDateTime(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) {
    final datePart = RegExp(r'^\d{4}-\d{2}-\d{2}').stringMatch(value);
    if (datePart != null && DateTime.tryParse(value) != null) {
      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(5, 7));
      final day = int.parse(datePart.substring(8, 10));
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    }
  }
  throw FormatException('Expected a nullable ISO-8601 field named $field.');
}

String _dateOnlyIso(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-${day}T00:00:00';
}
