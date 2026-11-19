import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_schedule_v3_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_schedule_v3.dart';

/// Repository for Policy v3 recurring schedule rules + preview/publish,
/// plus direct availability cancellation and weekly slot change requests.
abstract interface class MentorScheduleV3Repository {
  Future<MentorScheduleV3> loadSchedule();

  Future<MentorScheduleV3> updateSchedule(UpdateMentorScheduleV3Request request);

  Future<MentorSlotPreviewResult> previewSlots({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<MentorPublishSlotsResult> publishSlots({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> deleteAvailability(int availabilityId);

  Future<void> requestCancelAvailabilities(List<int> ids, {String? reason});

  Future<void> requestSlotChange(int slotId, String reason);

  Future<MentorTeachingConflictReport> previewTeachingConflicts({
    required List<({DateTime startUtc, DateTime endUtc})> intervals,
    int? excludeCohortId,
  });
}

class ApiMentorScheduleV3Repository implements MentorScheduleV3Repository {
  const ApiMentorScheduleV3Repository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MentorScheduleV3> loadSchedule() async {
    final response = await _apiClient.get<Object?>(MentorApiPaths.scheduleV3);
    return MentorScheduleV3Dto.fromJson(readMentorEnvelopeObject(response.data));
  }

  @override
  Future<MentorScheduleV3> updateSchedule(
    UpdateMentorScheduleV3Request request,
  ) async {
    final response = await _apiClient.put<Object?>(
      MentorApiPaths.scheduleV3,
      data: MentorScheduleV3Dto.updateToJson(request),
    );
    return MentorScheduleV3Dto.fromJson(readMentorEnvelopeObject(response.data));
  }

  @override
  Future<MentorSlotPreviewResult> previewSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.scheduleV3PreviewSlots,
      data: {
        'startDate': formatDateOnly(startDate),
        'endDate': formatDateOnly(endDate),
      },
    );
    return MentorScheduleV3Dto.previewFromJson(
      readMentorEnvelopeObject(response.data),
    );
  }

  @override
  Future<MentorPublishSlotsResult> publishSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.scheduleV3PublishSlots,
      data: {
        'startDate': formatDateOnly(startDate),
        'endDate': formatDateOnly(endDate),
      },
    );
    return MentorScheduleV3Dto.publishFromJson(
      readMentorEnvelopeObject(response.data),
    );
  }

  @override
  Future<void> deleteAvailability(int availabilityId) async {
    await _apiClient.delete<Object?>(
      MentorApiPaths.deleteAvailability(availabilityId),
    );
  }

  @override
  Future<void> requestCancelAvailabilities(
    List<int> ids, {
    String? reason,
  }) async {
    await _apiClient.post<Object?>(
      MentorApiPaths.requestCancelAvailability,
      data: {
        'ids': ids,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  @override
  Future<void> requestSlotChange(int slotId, String reason) async {
    await _apiClient.post<Object?>(
      MentorApiPaths.requestSlotChange(slotId),
      data: {'reason': reason.trim()},
    );
  }

  @override
  Future<MentorTeachingConflictReport> previewTeachingConflicts({
    required List<({DateTime startUtc, DateTime endUtc})> intervals,
    int? excludeCohortId,
  }) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.scheduleV3ConflictPreview,
      data: {
        'intervals': [
          for (final i in intervals)
            {
              'startUtc': i.startUtc.toUtc().toIso8601String(),
              'endUtc': i.endUtc.toUtc().toIso8601String(),
            },
        ],
        'excludeCohortId': ?excludeCohortId,
      },
    );
    return MentorScheduleV3Dto.conflictReportFromJson(
      readMentorEnvelopeObject(response.data),
    );
  }
}
