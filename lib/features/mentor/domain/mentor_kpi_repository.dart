import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';

abstract interface class MentorKpiRepository {
  Future<MentorKpiSummary> loadSummary({String? fromDate, String? toDate});
}
