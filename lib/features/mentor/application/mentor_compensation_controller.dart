import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_mentor_compensation_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation_repository.dart';

final mentorCompensationRepositoryProvider =
    Provider<MentorCompensationRepository>(
      (ref) => ApiMentorCompensationRepository(ref.watch(apiClientProvider)),
    );

final mentorCompensationOverviewProvider =
    FutureProvider.autoDispose<MentorCompensationOverview>(
      (ref) => ref.watch(mentorCompensationRepositoryProvider).loadOverview(),
    );

final mentorEarningsProvider =
    FutureProvider.autoDispose<List<MentorEarningEntryItem>>(
      (ref) => ref.watch(mentorCompensationRepositoryProvider).loadEarnings(),
    );

final mentorPayrollsProvider =
    FutureProvider.autoDispose<List<MentorPayrollPeriodItem>>(
      (ref) => ref.watch(mentorCompensationRepositoryProvider).loadPayrolls(),
    );

final mentorPayoutsProvider =
    FutureProvider.autoDispose<List<MentorPayoutObligationItem>>(
      (ref) => ref.watch(mentorCompensationRepositoryProvider).loadPayouts(),
    );

final mentorBankAccountsProvider =
    FutureProvider.autoDispose<List<MentorBankAccountItem>>(
      (ref) =>
          ref.watch(mentorCompensationRepositoryProvider).loadBankAccounts(),
    );

/// Kiểm tra định dạng dữ liệu tài khoản ngân hàng trước khi gửi lên Backend.
/// Trả về thông báo lỗi tiếng Việt hoặc null nếu hợp lệ.
String? validateMentorBankAccountInput({
  required String bankBin,
  required String bankShortName,
  required String accountNumber,
  required String accountHolderName,
}) {
  if (!RegExp(r'^\d{6}$').hasMatch(bankBin.trim())) {
    return 'Mã BIN ngân hàng phải gồm đúng 6 chữ số.';
  }
  if (bankShortName.trim().isEmpty) {
    return 'Vui lòng nhập tên ngân hàng.';
  }
  if (!RegExp(r'^\d{6,20}$').hasMatch(accountNumber.trim())) {
    return 'Số tài khoản chỉ gồm 6–20 chữ số.';
  }
  if (accountHolderName.trim().length < 2) {
    return 'Vui lòng nhập tên chủ tài khoản.';
  }
  return null;
}
