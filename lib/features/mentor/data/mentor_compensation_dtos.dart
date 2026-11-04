import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';

const List<String> _earningStatuses = <String>[
  'Eligible',
  'HeldDisputed',
  'LockedInPayroll',
  'Paid',
];

const List<String> _payrollStatuses = <String>[
  'Draft',
  'Review',
  'Approved',
  'Paid',
  'Closed',
];

const List<String> _bankStatuses = <String>[
  'PendingVerification',
  'Verified',
  'Rejected',
  'Superseded',
];

const List<String> _payoutMethods = <String>[
  'ManualBankTransfer',
  'PayOsPayout',
];

const List<String> _payoutStatuses = <String>[
  'PendingExecution',
  'Processing',
  'UnknownPendingReconciliation',
  'OnHoldMissingEvidence',
  'Paid',
  'FailedRetryable',
  'Cancelled',
];

const List<String> _attemptStatuses = <String>[
  'Initiated',
  'Processing',
  'UnknownPendingReconciliation',
  'OnHoldMissingEvidence',
  'Succeeded',
  'Failed',
];

String _enumString(Object? raw, List<String> values, String fallback) {
  if (raw is int && raw >= 0 && raw < values.length) {
    return values[raw];
  }
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) return fallback;
  final asInt = int.tryParse(text);
  if (asInt != null && asInt >= 0 && asInt < values.length) {
    return values[asInt];
  }
  return text;
}

int _intVal(Object? raw, [int fallback = 0]) {
  if (raw is int) return raw;
  if (raw is num && raw.isFinite) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

double _doubleVal(Object? raw, [double fallback = 0]) {
  if (raw is num && raw.isFinite) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

DateTime _dateVal(Object? raw) {
  if (raw is String) {
    return DateTime.tryParse(raw)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

DateTime? _optDateVal(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim())?.toUtc();
  }
  return null;
}

Map<String, Object?> _asMap(Object? item) {
  if (item is Map) {
    return item.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, Object?>{};
}

List<Map<String, Object?>> _asMapList(Object? raw) {
  if (raw is List) {
    return raw.map(_asMap).toList(growable: false);
  }
  return const <Map<String, Object?>>[];
}

MentorHourlyRateItem parseMentorHourlyRate(Map<String, Object?> json) {
  return MentorHourlyRateItem(
    id: _intVal(json['id']),
    mentorUserId: _intVal(json['mentorUserId']),
    hourlyRateVnd: _doubleVal(json['hourlyRateVnd']),
    currency: (json['currency']?.toString().trim().isNotEmpty ?? false)
        ? json['currency']!.toString().trim()
        : 'VND',
    effectiveFromUtc: _dateVal(json['effectiveFromUtc']),
    effectiveToUtc: _optDateVal(json['effectiveToUtc']),
    isActive: json['isActive'] == true,
    reason: json['reason']?.toString(),
  );
}

MentorTeachingQualificationItem parseMentorQualification(
  Map<String, Object?> json,
) {
  return MentorTeachingQualificationItem(
    id: _intVal(json['id']),
    mentorUserId: _intVal(json['mentorUserId']),
    jlptLevel: normalizeConsultationJlptLevel(json['jlptLevel']?.toString()),
    isActive: json['isActive'] == true,
    approvedAtUtc: _optDateVal(json['approvedAtUtc']),
    revokedAtUtc: _optDateVal(json['revokedAtUtc']),
    notes: json['notes']?.toString(),
  );
}

MentorEarningEntryItem parseMentorEarningEntry(Map<String, Object?> json) {
  return MentorEarningEntryItem(
    id: _intVal(json['id']),
    mentorUserId: _intVal(json['mentorUserId']),
    mentorBookingId: _intVal(json['mentorBookingId']),
    jlptLevel: normalizeConsultationJlptLevel(json['jlptLevel']?.toString()),
    frozenHourlyRateVnd: _intVal(json['frozenHourlyRateVnd']),
    frozenLevelCoefficient: _doubleVal(json['frozenLevelCoefficient'], 1.0),
    scheduledMinutes: _intVal(json['scheduledMinutes'], 90),
    approvedEligibleMinutes: _intVal(json['approvedEligibleMinutes']),
    scheduledAmountVnd: _intVal(json['scheduledAmountVnd']),
    eligibleAmountVnd: _intVal(json['eligibleAmountVnd']),
    currency: json['currency']?.toString() ?? 'VND',
    status: _enumString(json['status'], _earningStatuses, 'Eligible'),
    mentorPayrollLineId: json['mentorPayrollLineId'] == null
        ? null
        : _intVal(json['mentorPayrollLineId']),
    earnedAtUtc: _dateVal(json['earnedAtUtc']),
  );
}

MentorPayrollLineItem parseMentorPayrollLine(Map<String, Object?> json) {
  return MentorPayrollLineItem(
    id: _intVal(json['id']),
    mentorBookingId: _intVal(json['mentorBookingId']),
    jlptLevel: normalizeConsultationJlptLevel(json['jlptLevel']?.toString()),
    frozenHourlyRateVnd: _intVal(json['frozenHourlyRateVnd']),
    frozenLevelCoefficient: _doubleVal(json['frozenLevelCoefficient'], 1.0),
    approvedEligibleMinutes: _intVal(json['approvedEligibleMinutes']),
    lineAmountVnd: _intVal(json['lineAmountVnd']),
  );
}

MentorPayrollAdjustmentItem parseMentorPayrollAdjustment(
  Map<String, Object?> json,
) {
  return MentorPayrollAdjustmentItem(
    id: _intVal(json['id']),
    amountVnd: _intVal(json['amountVnd']),
    reason: json['reason']?.toString() ?? '',
    relatedMentorBookingId: json['relatedMentorBookingId'] == null
        ? null
        : _intVal(json['relatedMentorBookingId']),
  );
}

MentorPayrollPeriodItem parseMentorPayrollPeriod(Map<String, Object?> json) {
  return MentorPayrollPeriodItem(
    id: _intVal(json['id']),
    mentorUserId: _intVal(json['mentorUserId']),
    periodYear: _intVal(json['periodYear']),
    periodMonth: _intVal(json['periodMonth']),
    status: _enumString(json['status'], _payrollStatuses, 'Draft'),
    totalEarningsAmountVnd: _intVal(json['totalEarningsAmountVnd']),
    totalAdjustmentsAmountVnd: _intVal(json['totalAdjustmentsAmountVnd']),
    grossPayableAmountVnd: _intVal(json['grossPayableAmountVnd']),
    currency: json['currency']?.toString() ?? 'VND',
    approvedAtUtc: _optDateVal(json['approvedAtUtc']),
    payoutObligationId: json['payoutObligationId'] == null
        ? null
        : _intVal(json['payoutObligationId']),
    lines: _asMapList(
      json['lines'],
    ).map(parseMentorPayrollLine).toList(growable: false),
    adjustments: _asMapList(
      json['adjustments'],
    ).map(parseMentorPayrollAdjustment).toList(growable: false),
  );
}

MentorBankAccountItem parseMentorBankAccount(Map<String, Object?> json) {
  return MentorBankAccountItem(
    id: _intVal(json['id']),
    mentorUserId: _intVal(json['mentorUserId']),
    bankBin: json['bankBin']?.toString() ?? '',
    bankShortName: json['bankShortName']?.toString() ?? '',
    maskedAccountNumber: json['maskedAccountNumber']?.toString() ?? '',
    accountHolderName: json['accountHolderName']?.toString() ?? '',
    verificationStatus: _enumString(
      json['verificationStatus'],
      _bankStatuses,
      'PendingVerification',
    ),
    accountVersion: _intVal(json['accountVersion'], 1),
    isCurrent: json['isCurrent'] == true,
    verifiedAtUtc: _optDateVal(json['verifiedAtUtc']),
    notes: json['notes']?.toString(),
  );
}

MentorPayoutAttemptItem parseMentorPayoutAttempt(Map<String, Object?> json) {
  return MentorPayoutAttemptItem(
    id: _intVal(json['id']),
    attemptNumber: _intVal(json['attemptNumber'], 1),
    executionMethod: _enumString(
      json['executionMethod'],
      _payoutMethods,
      'ManualBankTransfer',
    ),
    status: _enumString(json['status'], _attemptStatuses, 'Initiated'),
    amountVnd: _intVal(json['amountVnd']),
    initiatedAtUtc: _dateVal(json['initiatedAtUtc']),
    transferReference: json['transferReference']?.toString(),
    providerPayoutId: json['providerPayoutId']?.toString(),
    completedAtUtc: _optDateVal(json['completedAtUtc']),
  );
}

MentorPayoutObligationItem parseMentorPayoutObligation(
  Map<String, Object?> json,
) {
  return MentorPayoutObligationItem(
    id: _intVal(json['id']),
    mentorPayrollPeriodId: _intVal(json['mentorPayrollPeriodId']),
    mentorUserId: _intVal(json['mentorUserId']),
    selectedExecutionMethod: json['selectedExecutionMethod'] == null
        ? null
        : _enumString(
            json['selectedExecutionMethod'],
            _payoutMethods,
            'ManualBankTransfer',
          ),
    status: _enumString(json['status'], _payoutStatuses, 'PendingExecution'),
    payableAmountVnd: _intVal(json['payableAmountVnd']),
    paidAmountVnd: _intVal(json['paidAmountVnd']),
    currency: json['currency']?.toString() ?? 'VND',
    recipientBankShortNameSnapshot:
        json['recipientBankShortNameSnapshot']?.toString() ?? '',
    recipientMaskedAccountSnapshot:
        json['recipientMaskedAccountSnapshot']?.toString() ?? '',
    recipientAccountHolderSnapshot:
        json['recipientAccountHolderSnapshot']?.toString() ?? '',
    paidAtUtc: _optDateVal(json['paidAtUtc']),
    failureReason: json['failureReason']?.toString(),
    attempts: _asMapList(
      json['attempts'],
    ).map(parseMentorPayoutAttempt).toList(growable: false),
  );
}

MentorCompensationOverview parseMentorCompensationOverview(
  Map<String, Object?> json,
) {
  final currentRateJson = json['currentHourlyRate'];
  final currentBankJson = json['currentBankAccount'];
  return MentorCompensationOverview(
    mentorUserId: _intVal(json['mentorUserId']),
    currentHourlyRate: currentRateJson is Map
        ? parseMentorHourlyRate(_asMap(currentRateJson))
        : null,
    activeQualifications: _asMapList(json['activeQualifications'])
        .map(parseMentorQualification)
        .where((q) => isSupportedConsultationJlptLevel(q.jlptLevel))
        .toList(growable: false),
    currentBankAccount: currentBankJson is Map
        ? parseMentorBankAccount(_asMap(currentBankJson))
        : null,
    totalEligibleUnassignedVnd: _intVal(json['totalEligibleUnassignedVnd']),
    totalLockedInPayrollVnd: _intVal(json['totalLockedInPayrollVnd']),
    totalPaidVnd: _intVal(json['totalPaidVnd']),
    recentEarnings: _asMapList(
      json['recentEarnings'],
    ).map(parseMentorEarningEntry).toList(growable: false),
    recentPayrolls: _asMapList(
      json['recentPayrolls'],
    ).map(parseMentorPayrollPeriod).toList(growable: false),
    recentPayouts: _asMapList(
      json['recentPayouts'],
    ).map(parseMentorPayoutObligation).toList(growable: false),
  );
}
