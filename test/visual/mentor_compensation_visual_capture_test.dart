import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_compensation_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_compensation_screen.dart';

void main() {
  final outputDir = Directory(
    Platform.environment['RIKI_CAPTURE_DIR'] ??
        r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce',
  );

  final sampleHourlyRate = MentorHourlyRateItem(
    id: 1,
    mentorUserId: 900002,
    hourlyRateVnd: 250000.0,
    currency: 'VND',
    effectiveFromUtc: DateTime.utc(2026, 1, 1),
    isActive: true,
    reason: 'Đơn giá chuẩn cố vấn JLPT',
  );

  const sampleQualifications = [
    MentorTeachingQualificationItem(
      id: 1,
      mentorUserId: 900002,
      jlptLevel: 'N3',
      isActive: true,
      notes: 'Đã xác minh chứng chỉ JLPT N3',
    ),
    MentorTeachingQualificationItem(
      id: 2,
      mentorUserId: 900002,
      jlptLevel: 'N2',
      isActive: true,
      notes: 'Đã phỏng vấn sư phạm JLPT N2',
    ),
  ];

  const sampleBank = MentorBankAccountItem(
    id: 1,
    mentorUserId: 900002,
    bankBin: '970436',
    bankShortName: 'Vietcombank',
    maskedAccountNumber: '****5678',
    accountHolderName: 'NGUYEN VAN SENSEI',
    verificationStatus: 'Verified',
    accountVersion: 1,
    isCurrent: true,
  );

  final sampleOverview = MentorCompensationOverview(
    mentorUserId: 900002,
    currentHourlyRate: sampleHourlyRate,
    activeQualifications: sampleQualifications,
    currentBankAccount: sampleBank,
    totalEligibleUnassignedVnd: 750000,
    totalLockedInPayrollVnd: 525000,
    totalPaidVnd: 3500000,
  );

  final sampleEarnings = <MentorEarningEntryItem>[
    MentorEarningEntryItem(
      id: 101,
      mentorUserId: 900002,
      mentorBookingId: 105,
      jlptLevel: 'N3',
      frozenHourlyRateVnd: 250000,
      frozenLevelCoefficient: 1.2,
      scheduledMinutes: 90,
      approvedEligibleMinutes: 90,
      scheduledAmountVnd: 450000,
      eligibleAmountVnd: 450000,
      currency: 'VND',
      status: 'Eligible',
      earnedAtUtc: DateTime.utc(2026, 11, 2, 14, 0),
    ),
    MentorEarningEntryItem(
      id: 102,
      mentorUserId: 900002,
      mentorBookingId: 106,
      jlptLevel: 'N2',
      frozenHourlyRateVnd: 250000,
      frozenLevelCoefficient: 1.4,
      scheduledMinutes: 90,
      approvedEligibleMinutes: 90,
      scheduledAmountVnd: 525000,
      eligibleAmountVnd: 525000,
      currency: 'VND',
      status: 'LockedInPayroll',
      earnedAtUtc: DateTime.utc(2026, 11, 3, 9, 30),
    ),
    MentorEarningEntryItem(
      id: 103,
      mentorUserId: 900002,
      mentorBookingId: 107,
      jlptLevel: 'N3',
      frozenHourlyRateVnd: 250000,
      frozenLevelCoefficient: 1.2,
      scheduledMinutes: 90,
      approvedEligibleMinutes: 0,
      scheduledAmountVnd: 450000,
      eligibleAmountVnd: 0,
      currency: 'VND',
      status: 'HeldDisputed',
      earnedAtUtc: DateTime.utc(2026, 11, 4, 11, 0),
    ),
  ];

  final samplePayrolls = <MentorPayrollPeriodItem>[
    MentorPayrollPeriodItem(
      id: 1,
      mentorUserId: 900002,
      periodYear: 2026,
      periodMonth: 11,
      status: 'Approved',
      totalEarningsAmountVnd: 975000,
      totalAdjustmentsAmountVnd: 0,
      grossPayableAmountVnd: 975000,
      currency: 'VND',
      approvedAtUtc: DateTime.utc(2026, 11, 4, 15, 0),
    ),
  ];

  final samplePayouts = <MentorPayoutObligationItem>[
    MentorPayoutObligationItem(
      id: 1,
      mentorPayrollPeriodId: 1,
      mentorUserId: 900002,
      selectedExecutionMethod: 'PayOsPayout',
      status: 'Processing',
      payableAmountVnd: 975000,
      paidAmountVnd: 0,
      currency: 'VND',
      recipientBankShortNameSnapshot: 'Vietcombank',
      recipientMaskedAccountSnapshot: '****5678',
      recipientAccountHolderSnapshot: 'NGUYEN VAN SENSEI',
      attempts: [
        MentorPayoutAttemptItem(
          id: 1,
          attemptNumber: 1,
          executionMethod: 'PayOsPayout',
          status: 'Processing',
          amountVnd: 975000,
          providerPayoutId: 'POS-SIM-900002-1',
          initiatedAtUtc: DateTime.utc(2026, 11, 4, 15, 35),
        ),
      ],
    ),
  ];

  Future<void> captureTab(WidgetTester tester, int tabIndex, String fileName) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          overrides: [
            mentorCompensationOverviewProvider.overrideWith((ref) => sampleOverview),
            mentorEarningsProvider.overrideWith((ref) => sampleEarnings),
            mentorPayrollsProvider.overrideWith((ref) => samplePayrolls),
            mentorPayoutsProvider.overrideWith((ref) => samplePayouts),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MentorCompensationScreen(initialTabIndex: tabIndex),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    outputDir.createSync(recursive: true);
    final file = File('${outputDir.path}${Platform.pathSeparator}\$fileName.png');
    file.writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Captured: \${file.path} (\${bytes.length} bytes)');
  }

  testWidgets('Capture Tab 3 Payrolls', (tester) async {
    await captureTab(tester, 2, 'e2e_mobile_mentor_compensation_tab3_payrolls');
  });

  testWidgets('Capture Tab 4 Payouts', (tester) async {
    await captureTab(tester, 3, 'e2e_mobile_mentor_compensation_tab4_payouts');
  });
}
