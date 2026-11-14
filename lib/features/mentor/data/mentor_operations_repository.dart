import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';

/// Repository covering Mentor operational Backend APIs beyond the core v1 interface:
/// booking detail, attendance telemetry, cancellation eligibility, room access,
/// verification certificate download, reviews/summary, and disputes detail/list.
abstract interface class MentorOperationsRepository {
  Future<MentorBookingDetail> loadBookingDetail(int bookingId);

  Future<MentorCancellationEligibility> checkCancellationEligibility(
    int bookingId,
  );

  Future<List<MentorAttendanceRecord>> loadBookingAttendance(int bookingId);

  Future<MentorRoomAccessStatus> checkRoomAccess(String roomId);

  Future<MentorVerificationDocumentData> loadVerificationDocument();

  Future<MentorRatingSummary> loadRatingSummary(int mentorId);

  Future<List<MentorReviewItem>> loadReviews(
    int mentorId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<List<MentorDisputeItem>> loadDisputes({
    int page = 1,
    int pageSize = 20,
  });

  Future<MentorDisputeDetail> loadDisputeDetail(int disputeId);
}

class ApiMentorOperationsRepository implements MentorOperationsRepository {
  const ApiMentorOperationsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MentorBookingDetail> loadBookingDetail(int bookingId) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.bookingDetail(bookingId),
    );
    return MentorBookingDetailDto.fromJson(
      readMentorEnvelopeObject(response.data),
    );
  }

  @override
  Future<MentorCancellationEligibility> checkCancellationEligibility(
    int bookingId,
  ) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.cancellationEligibility(bookingId),
    );
    return MentorCancellationEligibilityDto.fromJson(
      readMentorEnvelopeObject(response.data),
    );
  }

  @override
  Future<List<MentorAttendanceRecord>> loadBookingAttendance(
    int bookingId,
  ) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.bookingAttendance(bookingId),
    );
    return readMentorEnvelopeList(response.data)
        .map(MentorAttendanceRecordDto.fromJson)
        .toList(growable: false);
  }

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
      // Backend returns HTTP 403 when the room is outside its active join window
      // or restricted; surface the server reason immediately without erroring.
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
      // Fallback to signed URL endpoint if content streaming returns 5xx/unsupported.
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

  @override
  Future<MentorRatingSummary> loadRatingSummary(int mentorId) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.mentorRatingSummary(mentorId),
    );
    return MentorRatingSummaryDto.fromJson(
      readMentorEnvelopeObject(response.data),
    );
  }

  @override
  Future<List<MentorReviewItem>> loadReviews(
    int mentorId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.mentorReviews(mentorId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return readMentorEnvelopeList(response.data)
        .map(MentorReviewDto.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<MentorDisputeItem>> loadDisputes({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.mentorDisputes,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return readMentorEnvelopeList(response.data)
        .map(MentorDisputeDto.fromJson)
        .toList(growable: false);
  }

  @override
  Future<MentorDisputeDetail> loadDisputeDetail(int disputeId) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.disputeDetail(disputeId),
    );
    return MentorDisputeDetailDto.fromJson(
      readMentorEnvelopeObject(response.data),
    );
  }
}
