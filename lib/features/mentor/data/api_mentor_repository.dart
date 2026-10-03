import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';

class ApiMentorRepository implements MentorRepository {
  const ApiMentorRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async {
    final response = await _apiClient.get<Object?>(MentorApiPaths.availability);
    return readMentorResultList(response.data)
        .map(MentorAvailabilityDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() async {
    final response = await _apiClient.get<Object?>(MentorApiPaths.meetings);
    return readMentorResultList(response.data)
        .map(MentorMeetingDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }
}
