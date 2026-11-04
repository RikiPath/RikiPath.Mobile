import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';

abstract interface class MentorCompensationRepository {
  Future<MentorCompensationOverview> loadOverview();

  Future<List<MentorEarningEntryItem>> loadEarnings();

  Future<List<MentorPayrollPeriodItem>> loadPayrolls({int? year, int? month});

  Future<List<MentorBankAccountItem>> loadBankAccounts();

  Future<MentorBankAccountItem> upsertBankAccount({
    required String bankBin,
    required String bankShortName,
    required String accountNumber,
    required String accountHolderName,
  });

  Future<List<MentorPayoutObligationItem>> loadPayouts();
}
