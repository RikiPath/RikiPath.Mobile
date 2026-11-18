import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';

/// Repository covering active Group Learning operational endpoints:
/// meeting room readiness/access and mentor verification certificate download.
abstract interface class MentorOperationsRepository {
  Future<MentorRoomAccessStatus> checkRoomAccess(String roomId);

  Future<MentorVerificationDocumentData> loadVerificationDocument();
}

class ApiMentorOperationsRepository implements MentorOperationsRepository {
  const ApiMentorOperationsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MentorRoomAccessStatus> checkRoomAccess(String roomId) async {
    try {
      final response = await _apiClient.get<Object?>(
        MentorApiPaths.roomAccess(roomId),
      );
      return MentorRoomAccessStatusDto.fromJson(
        readMentorEnvelopeObject(response.data),
      );
    } on ForbiddenError catch (error) {
      final trimmed = error.message.trim();
      final hasServerMessage =
          trimmed.isNotEmpty &&
          trimmed != 'You do not have permission to perform this action.';
      return MentorRoomAccessStatus(
        roomId: roomId,
        canAccess: false,
        isRoomReady: false,
        reason: hasServerMessage ? trimmed : null,
      );
    }
  }

  @override
  Future<MentorVerificationDocumentData> loadVerificationDocument() async {
    try {
      final response = await _apiClient.get<List<int>>(
        MentorApiPaths.verificationDocumentContent,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data != null && data.isNotEmpty) {
        final contentType =
            response.headers.value('content-type') ??
            'application/octet-stream';
        return MentorVerificationDocumentData(
          bytes: Uint8List.fromList(data),
          contentType: contentType,
        );
      }
    } on ApiError catch (error) {
      if (error.statusCode == 404 ||
          error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.statusCode == 422) {
        rethrow;
      }
    }

    final urlResponse = await _apiClient.get<Object?>(
      MentorApiPaths.verificationDocument,
    );
    final body = readMapOrEmpty(urlResponse.data);
    final url =
        readOptionalString(body, 'url') ??
        readOptionalString(body, 'Url');
    return MentorVerificationDocumentData(signedUrl: url);
  }
}
