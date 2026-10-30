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

  @override
  Future<void> acceptMeeting(int bookingId) async {
    await _apiClient.post<Object?>(MentorApiPaths.acceptMeeting(bookingId));
  }

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(DateTime weekStart) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.weeklyScheduleUrl(weekStart),
    );
    return readMentorResultList(response.data)
        .map(WeeklyAvailabilityDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }

  @override
  Future<bool> saveWeeklySchedule({
    required DateTime weekStart,
    required List<WeeklyPeriodItem> periods,
  }) async {
    final weekStartStr =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final payload = {
      'weekStart': weekStartStr,
      'periods': periods
          .map((p) => {
                'date': p.formattedDate,
                'period': p.period,
              })
          .toList(growable: false),
    };
    final response = await _apiClient.put<Object?>(
      MentorApiPaths.weeklySchedule,
      data: payload,
    );
    if (response.data is Map<Object?, Object?>) {
      final map = response.data as Map<Object?, Object?>;
      return map['isSuccess'] == true;
    }
    return true;
  }
}
