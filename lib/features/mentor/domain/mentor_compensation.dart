import 'package:flutter/foundation.dart';

const List<String> supportedConsultationJlptLevels = <String>[
  'N5',
  'N4',
  'N3',
  'N2',
];

String normalizeConsultationJlptLevel(String? raw) {
  return (raw ?? '').trim().toUpperCase();
}

bool isSupportedConsultationJlptLevel(String? raw) {
  final normalized = normalizeConsultationJlptLevel(raw);
  return supportedConsultationJlptLevels.contains(normalized);
}

String? validateBookingJlptEligibility({
  required String? selectedJlptLevel,
  required List<String> mentorQualifiedLevels,
  required int availableTicketsForLevel,
  required bool requireTicketNow,
}) {
  final normalized = normalizeConsultationJlptLevel(selectedJlptLevel);
  if (!isSupportedConsultationJlptLevel(normalized)) {
    return 'Hệ thống tư vấn 1-1 chỉ hỗ trợ trình độ JLPT N5, N4, N3 và N2 (không hỗ trợ N1).';
  }
  if (mentorQualifiedLevels.isNotEmpty &&
      !mentorQualifiedLevels
          .map(normalizeConsultationJlptLevel)
          .contains(normalized)) {
    return 'Cố vấn chưa được cấp quyền hướng dẫn trình độ JLPT $normalized.';
  }
  if (requireTicketNow && availableTicketsForLevel <= 0) {
    return 'Bạn chưa có vé tư vấn khả dụng cho trình độ JLPT $normalized. Vui lòng mua gói cùng trình độ.';
  }
  return null;
}

@immutable
class MentorHourlyRateItem {
  const MentorHourlyRateItem({
    required this.id,
    required this.mentorUserId,
    required this.hourlyRateVnd,
    required this.currency,
    required this.effectiveFromUtc,
    required this.isActive,
    this.effectiveToUtc,
    this.reason,
  });

  final int id;
  final int mentorUserId;
  final double hourlyRateVnd;
  final String currency;
  final DateTime effectiveFromUtc;
  final DateTime? effectiveToUtc;
  final bool isActive;
  final String? reason;
}

@immutable
class MentorTeachingQualificationItem {
  const MentorTeachingQualificationItem({
    required this.id,
    required this.mentorUserId,
    required this.jlptLevel,
    required this.isActive,
    this.approvedAtUtc,
    this.revokedAtUtc,
    this.notes,
  });

  final int id;
  final int mentorUserId;
  final String jlptLevel;
  final bool isActive;
  final DateTime? approvedAtUtc;
  final DateTime? revokedAtUtc;
  final String? notes;
}

@immutable
class MentorEarningEntryItem {
  const MentorEarningEntryItem({
    required this.id,
    required this.mentorUserId,
    required this.mentorBookingId,
    required this.jlptLevel,
    required this.frozenHourlyRateVnd,
    required this.frozenLevelCoefficient,
    required this.scheduledMinutes,
    required this.approvedEligibleMinutes,
    required this.scheduledAmountVnd,
    required this.eligibleAmountVnd,
    required this.currency,
    required this.status,
    required this.earnedAtUtc,
    this.mentorPayrollLineId,
  });

  final int id;
  final int mentorUserId;
  final int mentorBookingId;
  final String jlptLevel;
  final int frozenHourlyRateVnd;
  final double frozenLevelCoefficient;
  final int scheduledMinutes;
  final int approvedEligibleMinutes;
  final int scheduledAmountVnd;
  final int eligibleAmountVnd;
  final String currency;
  final String status;
  final int? mentorPayrollLineId;
  final DateTime earnedAtUtc;

  double get approvedEligibleHours => approvedEligibleMinutes / 60.0;
}

@immutable
class MentorPayrollLineItem {
  const MentorPayrollLineItem({
    required this.id,
    required this.mentorBookingId,
    required this.jlptLevel,
    required this.frozenHourlyRateVnd,
    required this.frozenLevelCoefficient,
    required this.approvedEligibleMinutes,
    required this.lineAmountVnd,
  });

  final int id;
  final int mentorBookingId;
  final String jlptLevel;
  final int frozenHourlyRateVnd;
  final double frozenLevelCoefficient;
  final int approvedEligibleMinutes;
  final int lineAmountVnd;
}

@immutable
class MentorPayrollAdjustmentItem {
  const MentorPayrollAdjustmentItem({
    required this.id,
    required this.amountVnd,
    required this.reason,
    this.relatedMentorBookingId,
  });

  final int id;
  final int amountVnd;
  final String reason;
  final int? relatedMentorBookingId;
}

@immutable
class MentorPayrollPeriodItem {
  const MentorPayrollPeriodItem({
    required this.id,
    required this.mentorUserId,
    required this.periodYear,
    required this.periodMonth,
    required this.status,
    required this.totalEarningsAmountVnd,
    required this.totalAdjustmentsAmountVnd,
    required this.grossPayableAmountVnd,
    required this.currency,
    this.approvedAtUtc,
    this.payoutObligationId,
    this.lines = const [],
    this.adjustments = const [],
  });

  final int id;
  final int mentorUserId;
  final int periodYear;
  final int periodMonth;
  final String status;
  final int totalEarningsAmountVnd;
  final int totalAdjustmentsAmountVnd;
  final int grossPayableAmountVnd;
  final String currency;
  final DateTime? approvedAtUtc;
  final int? payoutObligationId;
  final List<MentorPayrollLineItem> lines;
  final List<MentorPayrollAdjustmentItem> adjustments;
}

@immutable
class MentorBankAccountItem {
  const MentorBankAccountItem({
    required this.id,
    required this.mentorUserId,
    required this.bankBin,
    required this.bankShortName,
    required this.maskedAccountNumber,
    required this.accountHolderName,
    required this.verificationStatus,
    required this.accountVersion,
    required this.isCurrent,
    this.verifiedAtUtc,
    this.notes,
  });

  final int id;
  final int mentorUserId;
  final String bankBin;
  final String bankShortName;
  final String maskedAccountNumber;
  final String accountHolderName;
  final String verificationStatus;
  final int accountVersion;
  final bool isCurrent;
  final DateTime? verifiedAtUtc;
  final String? notes;

  bool get isVerified => verificationStatus == 'Verified';
}

@immutable
class MentorPayoutAttemptItem {
  const MentorPayoutAttemptItem({
    required this.id,
    required this.attemptNumber,
    required this.executionMethod,
    required this.status,
    required this.amountVnd,
    required this.initiatedAtUtc,
    this.transferReference,
    this.providerPayoutId,
    this.completedAtUtc,
  });

  final int id;
  final int attemptNumber;
  final String executionMethod;
  final String status;
  final int amountVnd;
  final DateTime initiatedAtUtc;
  final String? transferReference;
  final String? providerPayoutId;
  final DateTime? completedAtUtc;
}

@immutable
class MentorPayoutObligationItem {
  const MentorPayoutObligationItem({
    required this.id,
    required this.mentorPayrollPeriodId,
    required this.mentorUserId,
    required this.status,
    required this.payableAmountVnd,
    required this.paidAmountVnd,
    required this.currency,
    required this.recipientBankShortNameSnapshot,
    required this.recipientMaskedAccountSnapshot,
    required this.recipientAccountHolderSnapshot,
    this.selectedExecutionMethod,
    this.paidAtUtc,
    this.failureReason,
    this.attempts = const [],
  });

  final int id;
  final int mentorPayrollPeriodId;
  final int mentorUserId;
  final String? selectedExecutionMethod;
  final String status;
  final int payableAmountVnd;
  final int paidAmountVnd;
  final String currency;
  final String recipientBankShortNameSnapshot;
  final String recipientMaskedAccountSnapshot;
  final String recipientAccountHolderSnapshot;
  final DateTime? paidAtUtc;
  final String? failureReason;
  final List<MentorPayoutAttemptItem> attempts;

  bool get isPaid => status == 'Paid';
}

@immutable
class MentorCompensationOverview {
  const MentorCompensationOverview({
    required this.mentorUserId,
    required this.totalEligibleUnassignedVnd,
    required this.totalLockedInPayrollVnd,
    required this.totalPaidVnd,
    this.currentHourlyRate,
    this.activeQualifications = const [],
    this.currentBankAccount,
    this.recentEarnings = const [],
    this.recentPayrolls = const [],
    this.recentPayouts = const [],
  });

  final int mentorUserId;
  final MentorHourlyRateItem? currentHourlyRate;
  final List<MentorTeachingQualificationItem> activeQualifications;
  final MentorBankAccountItem? currentBankAccount;
  final int totalEligibleUnassignedVnd;
  final int totalLockedInPayrollVnd;
  final int totalPaidVnd;
  final List<MentorEarningEntryItem> recentEarnings;
  final List<MentorPayrollPeriodItem> recentPayrolls;
  final List<MentorPayoutObligationItem> recentPayouts;
}
