import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_compensation_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation_repository.dart';

class ApiMentorCompensationRepository implements MentorCompensationRepository {
  const ApiMentorCompensationRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MentorCompensationOverview> loadOverview() async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.compensationOverview,
    );
    return parseMentorCompensationOverview(
      readMentorResultObject(response.data),
    );
  }

  @override
  Future<List<MentorEarningEntryItem>> loadEarnings() async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.compensationEarnings,
    );
    return readMentorResultList(
      response.data,
    ).map(parseMentorEarningEntry).toList(growable: false);
  }

  @override
  Future<List<MentorPayrollPeriodItem>> loadPayrolls({
    int? year,
    int? month,
  }) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.compensationPayrolls,
      queryParameters: <String, Object?>{'year': ?year, 'month': ?month},
    );
    return readMentorResultList(
      response.data,
    ).map(parseMentorPayrollPeriod).toList(growable: false);
  }

  @override
  Future<List<MentorBankAccountItem>> loadBankAccounts() async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.compensationBankAccounts,
    );
    return readMentorResultList(
      response.data,
    ).map(parseMentorBankAccount).toList(growable: false);
  }

  @override
  Future<MentorBankAccountItem> upsertBankAccount({
    required String bankBin,
    required String bankShortName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final response = await _apiClient.post<Object?>(
      MentorApiPaths.compensationBankAccounts,
      data: <String, Object?>{
        'bankBin': bankBin.trim(),
        'bankShortName': bankShortName.trim(),
        'accountNumber': accountNumber.trim(),
        'accountHolderName': accountHolderName.trim().toUpperCase(),
      },
    );
    return parseMentorBankAccount(readMentorResultObject(response.data));
  }

  @override
  Future<List<MentorPayoutObligationItem>> loadPayouts() async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.compensationPayouts,
    );
    return readMentorResultList(
      response.data,
    ).map(parseMentorPayoutObligation).toList(growable: false);
  }
}
