import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_kpi_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi_repository.dart';

class ApiMentorKpiRepository implements MentorKpiRepository {
  const ApiMentorKpiRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MentorKpiSummary> loadSummary({
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, Object?>{
      if (fromDate != null && fromDate.isNotEmpty) 'from': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'to': toDate,
    };
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.kpiSummary,
      queryParameters: query.isEmpty ? null : query,
    );
    return parseMentorKpiSummary(readMentorResultObject(response.data));
  }
}
