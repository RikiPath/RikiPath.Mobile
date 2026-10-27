import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/profile/data/api_user_profile_repository.dart';
import 'package:rikipath_mobile/features/profile/data/profile_avatar_picker.dart';
import 'package:rikipath_mobile/features/profile/data/user_profile_api_paths.dart';
import 'package:rikipath_mobile/features/profile/data/user_profile_dtos.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile DTOs', () {
    test('maps every source-backed response field', () {
      final dto = UserProfileDto.fromEnvelope(_profileEnvelope());

      expect(dto.userId, 42);
      expect(dto.email, 'learner@example.com');
      expect(dto.firstName, 'Minh Anh');
      expect(dto.lastName, 'Nguyễn');
      expect(dto.avatarUrl, 'https://cdn.example.test/avatar.webp');
      expect(dto.role, 'Learner');
      expect(dto.isEmailVerified, isTrue);
      expect(dto.targetJlptLevelId, 73);
      expect(dto.targetJlptLevelName, 'N3');
      expect(dto.dailyStudyMinutes, 30);
      expect(dto.targetExamDate, DateTime(2030, 12, 1));
      expect(dto.emailNotificationsEnabled, isTrue);
      expect(dto.systemNotificationsEnabled, isFalse);
    });

    test('preserves optional null profile fields', () {
      final dto = UserProfileDto.fromEnvelope(
        _profileEnvelope(avatarUrl: null, targetId: null, targetName: null),
      );

      expect(dto.avatarUrl, isNull);
      expect(dto.targetJlptLevelId, isNull);
      expect(dto.targetJlptLevelName, isNull);
    });

    test('rejects fractional integer fields instead of truncating them', () {
      final body = _profileEnvelope();
      final result = body['result']! as Map<String, Object?>;
      result['dailyStudyMinutes'] = 30.5;

      expect(() => UserProfileDto.fromEnvelope(body), throwsFormatException);
    });
  });

  group('API UserProfile repository', () {
    test('GET profile uses the exact authenticated me route', () async {
      final client = _RecordingApiClient();
      final repository = ApiUserProfileRepository(client);

      final profile = await repository.loadProfile();

      expect(client.calls, <String>['GET ${UserProfileApiPaths.me}']);
      expect(profile.fullName, 'Minh Anh Nguyễn');
      expect(profile.supportedJlptLevel?.label, 'N3');
    });

    test(
      'PUT profile sends only exact firstName and lastName fields',
      () async {
        final client = _RecordingApiClient();
        final repository = ApiUserProfileRepository(client);

        await repository.updateProfile(firstName: 'Aiko', lastName: 'Tanaka');

        expect(client.calls, <String>['PUT ${UserProfileApiPaths.me}']);
        expect(client.lastData, <String, Object?>{
          'firstName': 'Aiko',
          'lastName': 'Tanaka',
        });
      },
    );

    test(
      'avatar uses exact path, multipart key, file name, and type',
      () async {
        final client = _RecordingApiClient();
        final repository = ApiUserProfileRepository(client);

        await repository.uploadAvatar(
          ProfileAvatarUpload(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'avatar.webp',
            contentType: 'image/webp',
          ),
        );

        expect(client.calls, <String>['POST ${UserProfileApiPaths.avatar}']);
        final formData = client.lastData! as FormData;
        expect(formData.files, hasLength(1));
        expect(formData.files.single.key, 'avatarFile');
        expect(formData.files.single.value.filename, 'avatar.webp');
        expect(
          formData.files.single.value.contentType.toString(),
          'image/webp',
        );
      },
    );

    test(
      'JLPT goal uses supplied backend ID without fabricating a mapping',
      () async {
        final client = _RecordingApiClient();
        final repository = ApiUserProfileRepository(client);

        await repository.setJlptGoal(
          targetJlptLevelId: 73,
          dailyStudyMinutes: 45,
        );

        expect(client.calls, <String>['POST ${UserProfileApiPaths.jlptGoal}']);
        expect(client.lastData, <String, Object?>{
          'targetJlptLevelId': 73,
          'dailyStudyMinutes': 45,
        });
      },
    );

    test('study-level switch sends confirmed current-level request', () async {
      final client = _RecordingApiClient();
      final repository = ApiUserProfileRepository(client);

      await repository.switchStudyLevel(currentStudyLevelId: 101);

      expect(client.calls, <String>['PUT ${UserProfileApiPaths.studyLevel}']);
      expect(client.lastData, <String, Object?>{
        'currentStudyLevelId': 101,
        'confirmed': true,
      });
    });

    test('JLPT goal sends the existing target exam date field', () async {
      final client = _RecordingApiClient();
      final repository = ApiUserProfileRepository(client);

      await repository.setJlptGoalWithExamDate(
        targetJlptLevelId: 73,
        dailyStudyMinutes: 45,
        targetExamDate: DateTime(2030, 12, 1),
      );

      expect(client.lastData, <String, Object?>{
        'targetJlptLevelId': 73,
        'dailyStudyMinutes': 45,
        'targetExamDate': '2030-12-01T00:00:00',
      });
    });

    test('notification update uses only the two supported booleans', () async {
      final client = _RecordingApiClient();
      final repository = ApiUserProfileRepository(client);

      await repository.updateNotificationSettings(
        emailNotificationsEnabled: false,
        systemNotificationsEnabled: true,
      );

      expect(client.calls, <String>[
        'PUT ${UserProfileApiPaths.notificationSettings}',
      ]);
      expect(client.lastData, <String, Object?>{
        'emailNotificationsEnabled': false,
        'systemNotificationsEnabled': true,
      });
    });

    test(
      'malformed success response becomes a controlled UnknownError',
      () async {
        final client = _RecordingApiClient(
          response: const <String, Object?>{
            'statusCode': 200,
            'isSuccess': true,
            'result': <String, Object?>{'userId': 42},
          },
        );
        final repository = ApiUserProfileRepository(client);

        await expectLater(
          repository.loadProfile(),
          throwsA(isA<UnknownError>()),
        );
      },
    );
  });

  group('avatar contract validation', () {
    test('accepts only a backend-supported image type', () {
      final upload = profileAvatarUploadFromBytes(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: 'avatar.jpeg',
      );

      expect(upload.contentType, 'image/jpeg');
    });

    test('rejects an unsupported image type before upload', () {
      expect(
        () => profileAvatarUploadFromBytes(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'avatar.gif',
          reportedContentType: 'image/gif',
        ),
        throwsA(isA<UnsupportedAvatarTypeException>()),
      );
    });

    test('rejects an avatar larger than the source-backed 5MB limit', () {
      expect(
        () => profileAvatarUploadFromBytes(
          bytes: Uint8List(maxProfileAvatarBytes + 1),
          fileName: 'avatar.png',
          reportedContentType: 'image/png',
        ),
        throwsA(isA<AvatarTooLargeException>()),
      );
    });
  });
}

Map<String, Object?> _profileEnvelope({
  String? avatarUrl = 'https://cdn.example.test/avatar.webp',
  int? targetId = 73,
  String? targetName = 'N3',
}) {
  return <String, Object?>{
    'statusCode': 200,
    'isSuccess': true,
    'result': <String, Object?>{
      'userId': 42,
      'email': 'learner@example.com',
      'firstName': 'Minh Anh',
      'lastName': 'Nguyễn',
      'avatarUrl': avatarUrl,
      'role': 'Learner',
      'isEmailVerified': true,
      'targetJlptLevelId': targetId,
      'targetJlptLevelName': targetName,
      'dailyStudyMinutes': 30,
      'targetExamDate': '2030-12-01T00:00:00',
      'emailNotificationsEnabled': true,
      'systemNotificationsEnabled': false,
    },
  };
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({Map<String, Object?>? response})
    : response = response ?? _profileEnvelope(),
      super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> response;
  final List<String> calls = <String>[];
  Object? lastData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add('GET $path');
    return _response<T>(path);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add('POST $path');
    lastData = data;
    return _response<T>(path);
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add('PUT $path');
    lastData = data;
    return _response<T>(path);
  }

  Response<T> _response<T>(String path) {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: response as T,
    );
  }
}
