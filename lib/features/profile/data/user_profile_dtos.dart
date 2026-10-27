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
    required this.dailyStudyMinutes,
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
      dailyStudyMinutes: _requiredInt(json, 'dailyStudyMinutes'),
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
  final int dailyStudyMinutes;
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
  });

  final int targetJlptLevelId;
  final int dailyStudyMinutes;

  Map<String, Object?> toJson() => <String, Object?>{
    'targetJlptLevelId': targetJlptLevelId,
    'dailyStudyMinutes': dailyStudyMinutes,
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
